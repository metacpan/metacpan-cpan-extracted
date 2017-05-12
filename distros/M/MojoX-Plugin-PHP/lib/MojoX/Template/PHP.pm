package MojoX::Template::PHP;
use 5.010;
use Mojo::Base -base;
use Carp 'croak';
use PHP 0.15;
use Mojo::ByteStream;
use Mojo::Exception;
use Mojo::Util qw(decode encode monkey_patch slurp url_unescape);
use File::Temp;
use constant DEBUG =>   # not used ...
    $ENV{MOJO_TEMPLATE_DEBUG} || $ENV{MOJOX_TEMPLATE_PHP_DEBUG} || 0;

use Data::Dumper;
$Data::Dumper::Indent = $Data::Dumper::Sortkeys = 1;

our $VERSION = '0.05';

#has [qw(auto_escape)];
has [qw(code include_file)] => '';
has encoding => 'UTF-8'; # documented, not used
has name => 'template.php';
has template => "";

sub interpret {
    no strict 'refs';  # let callbacks be fully qualified subroutine names

    my $self = shift;
    my $c = shift // {};
    my $log = $c->app->log;
    local $SIG{__DIE__} = sub {
	CORE::die($_[0]) if ref $_[0];
	Mojo::Exception->throw( shift, 
		[ $self->template, $self->include_file, $self->code ] );
    };

    PHP::__reset;

    if (DEBUG) {
	$log->debug(" Request: ", Dumper($c->req) );
    }

    my $callbacks = $c && $c->app->config->{'MojoX::Template::PHP'};
    $callbacks ||= {};

    # prepare global variables for the PHP interpreter
    my $variables_order = PHP::eval_return( "ini_get('variables_order')" );
    my $cookie_params = { };
    my $params = $c ? { %{$c->{stash}}, c => $c } : { };

    if ($variables_order =~ /S/) {
	$params->{_SERVER} = $self->_server_params($c);
	$params->{_ENV} = \%ENV;
    } elsif ($variables_order =~ /E/) {
	$params->{_ENV} = \%ENV;
    }
    if ($variables_order =~ /C/) {
	$cookie_params = $self->_cookie_params($c);
	$params->{_COOKIE} = $cookie_params;
    }

    $params->{_FILES} = $self->_files_params($c);

    $self->_set_get_post_request_params( $c, $params, $variables_order );

    if (length($c->req->body)) {
	$params->{HTTP_RAW_POST_DATA} = $c->req->body;
    }

    # hook to make adjustments to  %$params
    if ($callbacks && $callbacks->{php_var_preprocessor}) {
	$callbacks->{php_var_preprocessor}->($params);
    }

    if (DEBUG) {
	$log->debug("Super globals for request " . $self->include_file . ":"
		    . Data::Dumper::Dumper({_GET => $params->{_GET},
					    _POST => $params->{_POST},
					    _REQUEST => $params->{_REQUEST},
					    _FILES => $params->{_FILES},
					    _SERVER => $params->{_SERVER} }));
    }

    while (my ($param_name, $param_value) = each %$params) {
	next if 'CODE' eq ref $param_value;
	PHP::assign_global($param_name, $param_value);
    }
    $c && $c->stash( 'php_params', $params );

    _set_php_input($c, $params);

    my $OUTPUT;
    my $ERROR = "";
    PHP::options( 
	stdout => sub {
	    $OUTPUT .= $_[0];
	} );
    PHP::options(
	stderr => sub {
	    $ERROR .= $_[0];
	    if ($callbacks && $callbacks->{php_stderr_processor}) {
		$callbacks->{php_stderr_processor}->($_[0]);
	    }
	} );
    PHP::options(
	header => sub {
	    my ($keyval, $replace) = @_;
	    my ($key,$val) = split /: /, $keyval, 2;
	    my $keep = 1;
	    if ($callbacks && $callbacks->{php_header_processor}) {
		$keep &&= $callbacks->{php_header_processor}
				    ->($key, $val, $replace);
	    }
	    return if !$keep;

	    if ($replace) {
		$c->res->headers->header($key,$val);
	    } else {
		$c->res->headers->add($key,$val);
	    }
	    if ($key =~ /^[Ss]tatus$/) {
		my ($code) = $val =~ /^\s*(\d+)/;
		if ($code) {
		    $c->res->code($code);
		} else {
		    $log->error("Unrecognized Status header: '"
					. $keyval . "' from PHP");
		}
	    }
	} );

    if (my $ipath = $c->stash("__php_include_path")) {
	PHP::set_include_path( $ipath );
	$log->info("include path: $ipath") if DEBUG;
    }

    if ($self->include_file) {
	if (DEBUG) {
	    $log->info("executing " . $self->include_file . " in PHP engine");
	}
	eval { PHP::include( $self->include_file ) };
    } else {
	my $len = length($self->code);
	if (DEBUG) {
	    if ($len < 1000) {
		$log->info("executing code:\n\n" . $self->code
			   . "\nin PHP engine");
	    } else {
		$log->info("executing $len bytes of code in PHP engine");
	    }
	}
	eval { PHP::eval( "?>" . $self->code ); };
    }

    if ($@) {
	if (length($OUTPUT || "") < 1000 || DEBUG) {
	    $log->error("Output from PHP engine: (" . $self->name . 
			"):\n\n" . ($OUTPUT // "<no output>") . "\n");
	} else {
	    $log->error("Output from PHP engine (" . $self->name . "): "
			. length($OUTPUT) . " bytes");
	}
	$log->error("PHP error from template " . $self->name . ": $@");

	# when does $@ indicate a serious (server) error,
	# and when can it be ignored? The value of $@ is often
        # something like "PHP error: PHP::eval failed at 
	# .../i686-linux/PHP.pm line 25.", which sometimes just
	# means that WordPress called exit()

	if (!$OUTPUT  && $@ !~ /PHP::eval failed at /) {
	    # maybe we are changing the response code to 500 too much
	    $log->info( "changing response code from "
				. ($c->res->code || "") . " to 500" );
	    $OUTPUT = $@;
	    $c->res->code(500);
	}

	undef $@;
    }
    if ($ERROR) {
	$log->warn("Error from PHP: $ERROR");
    }

    my $output = $OUTPUT;

    if ($callbacks && $callbacks->{php_output_postprocessor}) {
	$callbacks->{php_output_postprocessor}->(
	    \$output, $c && $c->res->headers, $c);
    }
    if ($c->res->headers->header('Location')) {

	# this is disappointing. if the $output string is empty,
	# Mojo will automatically sets a 404 status code?
	if ("" eq ($output // "")) {
	    $output = chr(0);
	}
	if (!$c->res->code) {
	    $c->res->code(302);
	} elsif (500 == $c->res->code) {
	    $log->info("changing response code from 500 to 302 "
		       . "because there's a location header");
	    $c->res->code(302);
	    $log->info("output is\n\n" . $output);
	    $log->info("active exception msg is: " . ($@ || ""));
	    undef $@;
	}
    }

    return $output unless $@;
    return Mojo::Exception->new( $@, [$self->template, $self->code] );
}

sub _set_php_input {
    my ($c, $params) = @_;
    my $input = $c->req->body;
    if (length($input)) {
	PHP::set_php_input( "$input" );
	$params->{HTTP_RAW_POST_DATA} = $input;
    }
    return;
}

sub _get_upload_metadata {
    my ($self, $upload) = @_;

    my ($temp_fh, $tempname) = File::Temp::tempfile( UNLINK => 1 );
    print $temp_fh $upload->slurp;
    close $temp_fh;
    PHP::_spoof_rfc1867( $tempname || "" );

    return {
	name => $upload->name,
	type => $upload->headers->content_type,
	size => $upload->size,
	filename => $upload->filename,
	tmp_name => $tempname,
	error => 0
    };
}

sub _files_params {
    my ($self, $c) = @_;
    my $_files = {};
    my $uploads = $c->req->uploads;

    if ($uploads) {

	foreach my $upload (@$uploads) {

	    DEBUG && $c->app->log->debug("\n--------\nUPLOAD:\n---------\n"
			    . Data::Dumper::Dumper($upload)
			    . "\n-------------------\n");

	    my $metadata = $self->_get_upload_metadata($upload);
	    if ($metadata->{name} =~ s/\[\]//) {
		my $name = $metadata->{name};
		$metadata->{name} = $metadata->{filename};
		if ($_files->{$name} && !ref $_files->{$name}) {
		    # upload of foo[] overwrites upload of foo
		    delete $_files->{$name};
		}
		for my $attrib (qw(name size type tmp_name error)) {
		    push @{$_files->{$name}{$attrib}},
			    $metadata->{$attrib};
		}
	    } elsif ($metadata->{name} =~ s/\[(.*?)\]//) {
		# XXX -- need test in t/20-uploads.t for this branch
		my $index = $1;
		my $name = $metadata->{name};
		$metadata->{name} = delete $metadata->{filename};
		$_files->{$name}{$index} = $metadata;
	    } else {
		my $name = $metadata->{name};
		$metadata->{name} = delete $metadata->{filename};
		$_files->{$name} = $metadata;
	    }
	}
#	$_files = _files_params_000($self, $c);
    }
    if (DEBUG && keys %$_files) {
	$c->app->log->debug("\$_FILES => " . Data::Dumper::Dumper($_files));
    }
    return $_files;
}

sub _cookie_params {
    my ($self, $c) = @_;

    # Mojo: $c->req->cookies is [], in Catalyst it is {}
    my $p = { 
	map {;
	     $_->name => url_unescape $_->value
	} @{$c->req->cookies} };
    return $p;
}

sub _server_params {
    use Socket;
    use Sys::Hostname;
    my ($self, $c) = @_;

    my $tx = $c->tx;
    my $req = $c->req;
    my $headers = $req->headers;

    # see  Mojolicious::Plugin::CGI
    return {
	CONTENT_LENGTH => $headers->content_length || 0,
	CONTENT_TYPE => $headers->content_type || 0,
	GATEWAY_INTERFACE => 'PHP/5.x',
	HTTP_COOKIE => $headers->cookie || '',
	HTTP_HOST => $headers->host || '',
	HTTP_REFERER => $headers->referrer || '',
	HTTP_USER_AGENT => $headers->user_agent || '',
	HTTPS => $req->is_secure ? 'YES' : 'NO',
	PATH_INFO => $req->{__old_path} || $req->url->path->to_string,
	QUERY_STRING => $req->url->query->to_string,
	REMOTE_ADDR => $tx->remote_address,
	REMOTE_HOST => gethostbyaddr( inet_aton( $tx->remote_address ),
				      AF_INET ) || '',
	REMOTE_PORT => $tx->remote_port,
	REQUEST_METHOD => $req->method,
	REQUEST_URI => $req->url->to_string,
	SERVER_NAME => hostname,
	SERVER_PORT => $tx->local_port,
	SERVER_PROTOCOL => $req->is_secure ? 'HTTPS' : 'HTTP',
	SERVER_SOFTWARE => __PACKAGE__
    };
}

sub _mojoparams_to_phpparams {
    my ($query, @order) = @_;
    my $existing_params = {};

    # .. was using Mojo::Parameters::param here, which stopped working
    # with Mojolicious 6.00 (and possibly earliers), but
    # Mojo::Parameters::to_hash also works, even for older Mojoliciouses
    my $p = $query->to_hash;
    while (my ($k,$v) = each %$p) {
	$existing_params->{$k} = $v;
    }


    # XXX - what if parameter value is a Mojo::Upload ? Do we still
    #       save it in the $_GET/$_POST array?





    # The conventional ways to parse input parameters with Perl (CGI/Catalyst)
    # are different from the way that PHP parses the input, and we may need
    # to translate the Perl-style parameters to PHP-style. Some examples:
    #
    # 1. foo=first&foo=second&foo=last
    #
    #    In Perl, value for the parameter 'foo' is an array ref with 3 values
    #    In PHP, value for param 'foo' is 'last', whatever the last value was
    #    See also example #5
    #
    # 2. foo[bar]=value1&foo[baz]=value2
    #
    #    In Perl, this creates scalar parameters 'foo[bar]' and 'foo[baz]'
    #    In PHP, this creates the parameter 'foo' with an associative array
    #            value ('bar'=>'value1', 'baz'=>'value2')
    #
    # 3. foo[bar]=value1&foo=value2&foo[baz]=value3
    #
    #    In Perl, this creates parameters 'foo[bar]', 'foo', and 'foo[baz]'
    #    In PHP, this create the parameter 'foo' with an associative array
    #            with value ('baz'=>'value3'). The values associated with
    #            'foo[bar]' and 'foo' are lost.
    #
    # 4. foo[2][bar]=value1&foo[2][baz]=value2
    #
    #    In Perl, this creates parameters 'foo[2][bar]' and 'foo[2][baz]'
    #    In PHP, this creates a 2-level hash 'foo'
    #
    # 5. foo[]=123&foo[]=234&foo[]=345
    #    In Perl, parameter 'foo[]' assigned to array ref [123,234,345]
    #    In PHP, parameter 'foo' is an array with elem (123,234,345)
    #
    # For a given set of Perl-parsed parameter input, this function returns
    # a hashref that resembles what the same parameters would look like
    # to PHP.

    my $new_params = {};
    foreach my $pp (@order) {
	my $p = $pp;
	if ($p =~ s/\[(.+)\]$//) {
	    my $key = $1;
	    s/%(..)/chr hex $1/ge for $p, $pp, $key;

	    if ($key ne '' && $new_params->{$p}
		    && ref($new_params->{$p} ne 'HASH')) {
		$new_params->{$p} = {};
	    }

	    # XXX - how to generalize this from 2 to n level deep hash?
	    if ($key =~ /\]\[/) {
		my ($key1, $key2) = split /\]\[/, $key;
		$new_params->{$p}{$key1}{$key2} = $existing_params->{$pp};
	    } else {
		$new_params->{$p}{$key} = $existing_params->{$pp};
	    }
	} elsif ($p =~ s/\[\]$//) {
	    # expect $existing_params->{$pp} to already be an array ref
	    $p =~ s/%(..)/chr hex $1/ge;
	    $new_params->{$p} = $existing_params->{$pp};
	} else {
	    $p =~ s/%(..)/chr hex $1/ge;
	    $new_params->{$p} = $existing_params->{$p};
	    if ('ARRAY' eq ref $new_params->{$p}) {
		$new_params->{$p} = $new_params->{$p}[-1];
	    }
	}
    }
    return $new_params;
}

sub _set_get_post_request_params {
    my ($self, $c, $params, $var_order) = @_;
    my $order = PHP::eval_return( 'ini_get("request_order")' ) || $var_order;
    $params->{$_} = {} for qw(_GET _POST _REQUEST);
    if ($var_order =~ /G/) {
	my $query = $c->req->url && $c->req->url->query;
	if ($query) {
	    $query =~ s/%(5[BD])/chr hex $1/ge;
	    my @order = map { s/=.*//; $_ } split /&/, $query;
	    $params->{_GET} = _mojoparams_to_phpparams(
		 $c->req->url->query, @order );
	}
    }
    if ($var_order =~ /P/ && $c->req->method eq 'POST') {
	my $order = $Mojolicious::VERSION >= 6.00 
		      ? $c->req->body_params->names
		      : [ $c->req->body_params->param ];
	$params->{_POST} = _mojoparams_to_phpparams(
	    $c->req->body_params, @$order );
    }

    $params->{_REQUEST} = {};
    foreach my $reqvar (split //, uc $order) {
	if ($reqvar eq 'C') {
	    $params->{_REQUEST} = { %{$params->{_REQUEST}}, 
				    %{$params->{_COOKIE}} };
	} elsif ($reqvar eq 'G') {
	    $params->{_REQUEST} = { %{$params->{_REQUEST}}, 
				    %{$params->{_GET}} };
	} elsif ($reqvar eq 'P') {
	    $params->{_REQUEST} = { %{$params->{_REQUEST}}, 
				    %{$params->{_POST}} };
	}
    }
    return;
}

sub render {
    my $self = shift;
    my $c = pop if @_ && ref $_[-1];
    $self->code( join '', @_ );
    $self->include_file('');
    return $self->interpret($c);
}

sub render_file {
    my ($self, $path) = (shift, shift);
    $self->name($path) unless defined $self->{name};
    $self->include_file($path);
    return $self->interpret(@_);
}

unless (caller) {
    my $mt = MojoX::Template::PHP->new;
    my $output = $mt->render(<<'EOF');
<html>
    <head><title>Simple</title><head>
    <body>
        Time: <?php echo "figuring out the time in PHP is too hard!"; ?>
    </body>
</html>
EOF
    say $output;

    open my $fh, '>/tmp/test.php' or die;
    print $fh <<'EOF';
<?php echo "hello world\n"; ?>
HeLlO WoRlD!
<?php echo "HELLO WORLD\n"; ?>
EOF
    close $fh;
    $output = $mt->render_file( '/tmp/test.php' );
    say $output;
    unlink '/tmp/test.php';
}

1;

=encoding utf8

=head1 NAME

MojoX::Template::PHP - PHP processing engine for MojoX::Plugin::PHP

=head1 VERSION

0.05

=head1 SYNOPSIS

    use MojoX::Template::PHP;
    my $mt = MojoX::Template::PHP->new;
    my $output = $mt->render(<<'EOF');
    <html>
        <head><title>Simple</title><head>
        <body>Time: 
            <?php echo time(); ?>
        </body>
    </html>
    EOF
    say $output;

    my $output = $mt->render_file( '/path/to/some/template.php' );
    say $output;

=head1 DESCRIPTION

L<MojoX::Template::PHP> is a way to use PHP as a templating
system for your Mojolicious application. 

=over 4

=item 1. You can put a Mojolicious wrapper around some decent
PHP application (say, WordPress)

=item 2. You are on a development project with Perl and PHP
programmers, and you want to use Mojolicious as a backend
without scaring the PHP developers.

=back

=head1 ATTRIBUTES

L<MojoX::Template::PHP> implements the following attributes:

=head2 code

    my $code = $mt->code;
    $mt = $mt->code($code);

Inline PHP code for template. The L<"interpret"> method
will check the L<"include_file"> attribute first, and then
this attribute to decide what to pass to the PHP interpreter.

=head2 encoding

    my $encoding = $mt->encoding;
    $mt = $mt->encoding( $charset );

Encoding used for template files.

=head2 include_file

    my $file = $mt->include_file;
    $mt = $mt->include_file( $path );

PHP template file to be interpreted. The L<"interpret"> method
will check this attribute, and then the L<"code"> attribute
to decide what to pass to the PHP interpreter.

=head2 name

    my $name = $mt->name;
    $mt = $mt->name('foo.php');

Name of the template currently being processed. Defaults to
C<template.php>. This value should not contain quotes or
newline characters, or error messages might end up being wrong.

=head2 template

    my $template = $mt->template;
    $mt = $mt->template( $template_name );

Should contain the name of the template currently being processed,
but I don't think it is ever set to anything now. This value will
appear in exception messages.

=head1 METHODS

L<MojoX::Template::PHP> inherits all methods from
L<Mojo::Base>, and the following new ones:

=head2 interpret

    my $output = $mt->interpret($c)

Interpret template code. Starts the PHP engine and evaluates the
template code with it. See L<"CONFIG"/MojoX::Plugin::PHP> for
information about various callbacks that can be used to change
and extend the behavior of the PHP templating engine.

=head2 render

    my $output = $mt->render($template);

Render a PHP template.

=head2 render_file

    my $output = $mt->render_file( $php_file_path );

Render template file.

=cut

#=head1 DEBUGGING
#
#You can set either the C<MOJO_TEMPLATE_DEBUG> or
#C<MOJOX_TEMPLATE_PHP_DEBUG> environment variable to enable
#some diagnostics information printed to C<STDERR>.

=head1 SEE ALSO

L<MojoX::Plugin::PHP>, L<Mojo::Template>, L<PHP>,
L<Catalyst::View::Template::PHP>

=head1 AUTHOR

Marty O'Brien E<lt>mob@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2013-2015, Marty O'Brien. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Sortware Foundation; or the Artistic License.

See http://dev.perl.org/licenses for more information.

=cut
