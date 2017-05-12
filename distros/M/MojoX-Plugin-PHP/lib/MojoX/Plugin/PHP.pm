package MojoX::Plugin::PHP;
use Mojo::Base 'Mojolicious::Plugin';

use MojoX::Template::PHP;
use Mojo::Util qw(encode md5_sum);

use Data::Dumper;
$Data::Dumper::Indent = 1;
$Data::Dumper::Sortkeys = 1;

our $VERSION = '0.05';
my $php_req_handler_path = sprintf "/php-handler-%07x", 0x10000000 * rand();

sub register {
    my ($self, $app, $config) = @_;
    $app->config( 'MojoX::Template::PHP' => $config,
		  'MojoX::Plugin::PHP'   => $config );
    $app->types->type( php => "application/x-php" );
    $app->renderer->add_handler( php => \&_php );
    $app->routes->any( $php_req_handler_path, \&_php_controller );
    $app->hook( before_dispatch => \&_before_dispatch_hook );
}

sub _rewrite_req_for_php_handler {
    my ($c, $path_to_restore, $path_to_request) = @_;
    $c->req->{__old_path} = $path_to_restore;
    $c->req->{__php_restore} = { path => $path_to_restore,
				 template => $path_to_request };
    $c->req->url->path( $php_req_handler_path );
}

sub _path_contains_index_php {
    my ($path, $c) = @_;
    my $app = $c->app;
    foreach my $dir (@{$app->renderer->paths}, @{$app->static->paths}) {
	my $file = catfile( split('/', $dir), split('/',$path), 'index.php' );
	if (-r $file) {
	    return $file;
	}
    }
    return;
}

sub _before_dispatch_hook {
    my $c = shift;
    my $old_path = $c->req->url->path->to_string;
    if ($old_path =~ /\.php$/) {
	_rewrite_req_for_php_handler( $c, $old_path, substr($old_path,1) );
    } else {
	my $use_index_php =
	    $c->app->config->{'MojoX::Plugin::PHP'}{use_index_php};
	if ($old_path =~ m{/$}) {
	    if (defined $use_index_php && 
		    _path_contains_index_php($old_path,$c)) {
		_rewrite_req_for_php_handler($c, $old_path, 
					     substr($old_path,1).'index.php');
	    }
	} elsif ($use_index_php && _path_contains_index_php($old_path,$c)) {
	    _rewrite_req_for_php_handler($c,$old_path,
					 substr($old_path,1).'/index.php');
	}
    }
}

sub _php_controller {
    my $self = shift;
    $self->req->url->path( $self->req->{__php_restore}{path} );
    my $template = $self->req->{__php_restore}{template};
    $self->render( template => $template, handler => 'php' );
}

sub _template_path {
    use File::Spec::Functions 'catfile';
    my ($renderer, $c, $options) = @_;
    my $name = $options->{template};

    foreach my $path (@{$renderer->paths}, @{$c->app->static->paths}) {
	my $file = catfile($path, split '/', $name);
	if (-r $file) {
	    my @d = split '/', $file;
	    pop @d;
	    $c->stash( '__template_dir', join("/", @d) );
	    return $file;
	}
    }
    my @d = split '/', $renderer->paths->[0];
    pop @d;
    $c->stash( '__template_dir', join("/", @d) );
    return catfile( $renderer->paths->[0], split '/', $name );
}

sub _template_name {
    my ($renderer, $c, $options) = @_;
    my $name = $options->{template};
    return $name;
}

sub _php {
    my ($renderer, $c, $output, $options) = @_;

    # the PHP script should declare its own encoding in a Content-type header
    delete $options->{encoding};
    my $inline = $options->{inline};
    my $path = _template_path($renderer, $c, $options);

    $path = md5_sum encode('UTF-8', $inline) if defined $inline;
    return undef unless defined $path;

    my $mt = MojoX::Template::PHP->new;
    my $log = $c->app->log;
    if (defined $inline) {
	$log->debug('Rendering inline template.');
	$$output = $mt->name('inline template')->render($inline, $c);
    } else {
	$mt->encoding( $renderer->encoding ) if $renderer->encoding;
	return undef unless my $t = _template_name($renderer, $c, $options);
	$mt->template($t);

	if (-r $path) {
	    use File::Tools qw(pushd popd);
	    my $php_dir = $c->stash('__template_dir') || ".";

	    # XXX - need more consistent way of setting the include path
	    $c->stash("__php_include_path",
		      ".:/usr/local/lib/php:$php_dir");

	    pushd($php_dir);
	    $log->debug("chdir to: $php_dir");
	    $log->debug( "Rendering template '$t'." );
	    $$output = $mt->name("template '$t'")->render_file($path,$c);
	    popd();
	    $c->stash("__template_dir", undef);
	} elsif (my $d = $renderer->get_data_template($options)) {
	    $log->debug( "Rendering template '$t' from DATA section" );
	    $$output = $mt->name("template '$t' from DATA section")
				->render($d,$c);
	} else {
	    $log->debug("template '$t' not found.");
	    return undef;
	}
    }
    return ref $$output ? die $$output : 1;
}

1;

=encoding UTF8

=head1 NAME

MojoX::Plugin::PHP - use PHP as a templating system in Mojolicious

=head1 VERSION

0.05

=head1 WTF

Keep reading.

=head1 SYNOPSIS

    # MyApp.pl, using Mojolicious
    app->plugin('MojoX::Plugin::PHP');
    app->plugin('MojoX::Plugin::PHP', {
        php_var_preprocessor => sub { my $params = shift; ... },
        php_stderr_preprocessor => sub { my $msg = shift; ... },
        php_header_processor => sub { my ($field,$value,$repl) = @_; ... },
        php_output_processor => sub { my ($outref, $headers, $c) = @_; ... }
    } );

    # using Mojolicious::Lite
    plugin 'MojoX::Plugin::PHP';
    plugin 'MojoX::Plugin::PHP', {
        php_var_preprocessor => sub { my $params = shift; ... },
        php_stderr_preprocessor => sub { my $msg = shift; ... },
        php_header_processor => sub { my ($field,$value,$repl) = @_; ... },
        php_output_processor => sub { my ($outref, $headers, $c) = @_; ... }
    };



=head1 DESCRIPTION

L<MojoX::Plugin::PHP> establishes a PHP engine as the default
handler for C<php> files and templates in a Mojolicious application.
This allows you to put
a PHP template (say, called C<foo/bar.php> under your Mojolicious
application's C</templates> or C</public> directory, make a
request to

    /foo/bar.php

and have a PHP interpreter process your file, and Mojolicious
return a response as if it the request were processed in
Apache with mod_php.

Why would anyone want to do this? Here are a couple of reasons I
can think of:

=over 4

=item * to put a Mojolicious wrapper around some decent PHP
application (WordPress?). Then you could use Perl and any
other state of your Mojolicious application to post process
output and response headers.

=item * allow PHP developers on your project to keep 
prototyping in PHP, postponing the religious war about
which appserver your project should use

=back

=head1 CONFIG

=over 4

=item use_index_php

    use_index_php => boolean | undef

Describes how the before_dispatch hook should handle requests
for a path that contains a file called C<index.php>. 

If C<use_index_php> is set to a defined value, then a request like
C</foo/> (with a trailing slash) will be routed to
C</foo/index.php> if C</foo/index.php> would resolve to a valid
PHP template.

If C<use_index_php> is set to a true value, then a request like
C</foo> (with or without a trailing slash) will be routed to
C</foo/index.php> if C</foo/index.php> would resolve to a valid
PHP template.

If C<use_index_php> is not defined or set to C<undef>, then
this module will not look for an C<index.php> file related
to any request.

=back

=head2 Callbacks during PHP processing

There are four hooks in the PHP template processing engine
(L<MojoX::Template::PHP>) where you can customize or extend 
the behavior of the PHP engine. In the plugin configuration,
you can specify the code that should be run off each of these
hooks. All of these configuration are optional.

=over 4

=item php_var_preprocessor 

    php_var_preprocessor => sub { my $params = shift; ... }

L<MojoX::Template::PHP> gathers several variables from Perl
and sets them as global variables in the PHP environment. These
include the standard C<$_GET>, C<$_POST>, C<$_REQUEST>,
C<$_SERVER>, C<$_ENV>, C<$_COOKIE>, and C<$_FILES> variables,
but also includes most of the stash variables. All of these
variable values are gathered into a single hash reference.
Right before all of the variables are assigned in PHP, the
PHP engine will look for a C<php_var_preprocessor> setting,
and will invoke its code, passing that hash reference as an
argument. In this callback, you can add, remove, or edit
the set of variables that will be initialized in PHP.

=item php_stderr_processor

    php_stderr_processor => sub { my $msg = shift; ... }

When the PHP interpreter writes a message to its standard error
stream, a callback specified by the C<php_stderr_processor>
config setting can be called with the text that PHP was trying
to write to that stream. You can use this callback to log
warnings and errors from PHP.

=item php_header_processor

    php_header_processor => sub { 
        my ($field,$value,$replace) = @_; 
        ... 
        return $keep_header;
    }

When the PHP C<header()> function is invoked in the PHP interpreter,
a callback specified by the C<php_header_processor> config setting
can be called with the name and value of the header. If this callback
returns a true value (or if there is no callback), the header from
PHP will be included in the Mojolicious response headers.
If this callback returns a false value, the header will not be 
returned with the Mojolicious response.

One powerful use of the header callback is as a communication
channel between PHP and Perl. For example, the header processor
can look for a specific header field. When it sees this header,
the value can be a JSON-encoded payload which can be processed
in Perl. Perl can return the results of the processing through
a global PHP variable (again, possibly JSON encoded). The
C<t/10-headers.t> test case in this distribution has a
proof-of-concept of this kind of use of the header callback.

=item php_output_postprocessor

    php_output_postprocessor => sub {
        my ($output_ref, $headers, $c) = @_;
        ...
    }

When the PHP engine has finished processing a PHP template, and
a callback has been specified with the C<php_output_postprocessor>
config setting, then that callback will be invoked with a
I<reference> to the PHP output, the set of headers returned
by PHP (probably in a L<Mojo::Headers> object), and the current
controller/context object. You can use this
callback for postprocessing the output or the set of headers
that will be included in the Mojolicious response.

One thing that you might want to do in the output post-processing
is to look for a C<Location: ...> header, and determine if you
want the application to follow it.

=back

=head1 METHODS

=head2 register

    $plugin->register(Mojolicious->new);

Register the php renderer in L<Mojolicious> application.

=head1 COMMUNICATION BETWEEN PERL AND PHP

As mentioned in the L<"php_header_processor" documentation in the 
CONFIG section above|"php_header_processor">,
it is possible to use the header callback mechanism to execute
arbitrary Perl code from PHP and to establish a communication channel
between your PHP scripts and your Mojolicious application.

Let's demonstrate with a simple example:

The Collatz conjecture states that the following algorithm:

    Take any natural number  n . If  n  is even, divide it by 2.
    If  n  is odd, multiply it by 3 and add 1 so the result is  3n + 1 .
    Repeat the process until you reach the number 1.

will always terminate in a finite number of steps.

Suppose we are interested in finding out, for a given numner I<n>,
how many steps of this algorithm are required to reach the number 1.
We'll make a request to a path like:

C<collatz.php?n=>I<n>

and return the number of steps in the response. Our C<collatz.php>
template looks like:

    <?php
      $nsteps = 0;
      $n = $_GET['n'];
      while ($n > 1) {
        if ($n % 2 == 0) {
          $n = divide_by_two($n);
        } else {
          $n = triple_plus_one($n);
        }
        $nsteps++;
      }

      function divide_by_two($x) {
        return $x / 2;
      }

      function triple_plus_one($x) {
        ...
      }
    ?>
    number of Collatz steps is <?php echo $nsteps; ?>

and we will implement the C<triple_plus_one> function in Perl.

=head2 Components of the communication channel

The configuration for C<MojoX::Plugin::PHP> can specify a callback
function that will be invoked when PHP sends a response header.
To use this channel to perform work in PHP, we need

=over 4

=item 1. a C<MojoX::Plugin::PHP> header callback function that
listens for a specific header

=item 2. PHP code to produce that header

=item 3. an agreed upon global PHP variable, that Perl code
can set (with L<< the C<PHP::assign_global> function|"assign_global"/PHP >>)
with the result of its operation, and that PHP can read

=back

=head2 Perl code

In the Mojolicious application, we intercept a header of the form
C<< X-collatz: >>I<payload>  where I<payload> is the JSON-encoding
of a hash that defines C<n>, the number to operate on, and
C<result>, the name of the PHP variable to publish the results to.

JSON-encoding the header value is a convenient way to pass
complicated, arbitrary data from PHP to Perl, including binary
data or strings with newlines. For complex results, it is also
convenient to assign a JSON-encoded value to a single PHP global
variable.

    ...
    use Mojo::JSON;
    ...
    app->plugin('MojoX::Plugin::PHP',
        { php_header_processor => \&my_header_processor };

    sub my_header_processor {
        my ($field,$value,$replace) = @_;
        if ($field eq 'X-collatz') {
            my $payload = Mojo::JSON::decode_json($value);
            my $n = $payload->{n};
	    my $result_var = $payload->{result};
            $n = 3 * $n + 1;
	    PHP::assign_global( $result_var, $n );
            return 0;   # don't include this header in response
        }
        return 1;       # do include this header in response
    }
    ...

=head2 PHP code

The PHP code merely has to set a response header that looks like
C<< X-collatz: >>I<payload>  where I<payload> is a JSON-encoded
associative array with the number to operate on the variable to
receive the results in. Then it must read the result out of that
variable.

    ...
    function triple_plus_one($x) {
        global $collatz_result;
        $payload = encode_json(   // requires php >=v5.2.0
            array( "n" => $x, "result" => "collatz_result")
        );
        header("X-collatz: $payload");
        return $collatz_result;
    }

Now we can not only run PHP scripts in Mojolicious, our PHP
templates can execute code in Perl. 

    $ perl our_app.pl get /collatz.php?n=5
    number of Collatz steps is 5
    $ perl our_app.pl get /collatz.php?n=42
    number of Collatz steps is 8

=head2 Other possible uses

Other ways you might use this feature include:

=over 4

=item * have PHP execute functions or use modules that are hard to
implement in Perl or only available in Perl

=item * have PHP manipulate data in your app's Perl model

=item * perform authentication or other function in PHP that changes
the state on the Perl side of your application

=back

=head1 SEE ALSO

L<MojoX::Template::PHP>, L<Mojolicious::Plugin::EPRenderer>,
L<Mojolicious::Plugin::EPLRenderer>,
L<Catalyst::View::Template::PHP>, L<PHP>, L<PHP::Interpreter>.

=head1 AUTHOR

Marty O'Brien E<lt>mob@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2013-2015, Marty O'Brien. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Sortware Foundation; or the Artistic License.

See http://dev.perl.org/licenses for more information.

=cut
