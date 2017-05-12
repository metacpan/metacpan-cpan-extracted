package Test::Apache::RewriteRules;
use 5.008001;
use strict;
use warnings;
use Carp qw(croak);

use JSON::XS qw(decode_json);
use Path::Class qw(dir file);
use File::Temp qw(tempfile);

use LWP::UserAgent;
use HTTP::Request;

use Test::Differences;
use Test::Httpd::Apache2;
use Test::TCP qw(empty_port);

our $VERSION = '1.0.1';

sub new {
    my ($class, %args) = @_;
    bless { backends => [], %args }, $class;
}

sub available {
    my ($class, %apache_options) = @_;
    my $apache = Test::Httpd::Apache2->new(
        %apache_options,
        auto_start => 0,
    );
    eval { $apache->start };
    my $is_available = !$@;
    eval { undef $apache  };
    $is_available;
}

sub add_backend {
    my ($self, %backend) = @_;
    $backend{port}   ||= empty_port();
    $backend{apache} ||= $self->create_backend_apache(%backend);
    push @{$self->{backends}}, \%backend;
}

sub proxy_port {
    my $self = shift;
    $self->{proxy_port} ||= empty_port();
}

sub proxy_host {
    my $self = shift;
    sprintf q<localhost:%s>, $self->proxy_port;
}

sub proxy_http_url {
    my $self = shift;
    my $path = shift || q</>;
       $path =~ s[^//[^/]*/][/];

    sprintf q<http://%s%s>, $self->proxy_host, $path;
}

sub backend_port {
    my ($self, $backend_name) = @_;

    for my $backend (@{$self->{backends}}) {
        return $backend->{port}
            if $backend->{name} eq $backend_name;
    }

    croak qq<Can't find backend by name: $backend_name>;
}

sub backend_host {
    my ($self, $backend_name) = @_;
    sprintf q<localhost:%s>, $self->backend_port($backend_name);
}

sub get_backend_name_by_port {
    my ($self, $port) = @_;

    for my $backend (@{$self->{backends}}) {
        return $backend->{name}
            if ($backend->{port} || 0) == $port
    }
}

sub rewrite_conf {
    my ($self, $rewrite_conf) = @_;
    $self->{rewrite_conf} ||= $rewrite_conf && file($rewrite_conf);
}

*rewrite_conf_f = \&rewrite_conf;

sub copy_config {
    my ($self, $original_conf, $patterns) = @_;
    $patterns ||= [];
    $original_conf = file($original_conf);
    my $config     = eval { $original_conf->slurp };

    croak $@ if $@;

    while (@$patterns) {
        my $pattern = shift @$patterns;
           $pattern = ref $pattern eq 'Regexp' ? $pattern : qr/\Q$pattern\E/;
        my $replace = shift @$patterns;
        my $code    = ref $replace eq 'CODE' ? $replace : sub { $replace };

        $config =~ s/$pattern/$code->()/ge;
    }

    my $copied_conf = $original_conf->basename;
       $copied_conf =~ s/\.[^.]*//g;
       $copied_conf .= 'XXXXX';

    (undef, $copied_conf) = tempfile(
        $copied_conf,
        DIR => $self->server_root,
    );
    $copied_conf = file($copied_conf);

    my $fh = $copied_conf->openw;
    print $fh $config;
    close $fh;

    $copied_conf;
}

*copy_conf_as_f = \&copy_config;

sub server_root {
    my $self = shift;
    dir($self->apache->server_root);
}

*server_root_d = \&server_root;

sub proxy_document_root_d {
    my $self = shift;
    $self->server_root->absolute->cleanup;
}

sub receiver {
    my $self   = shift;
    return $self->{receiver} if $self->{receiver};

    my $receiver_path_name = 'url.cgi';
    my $receiver = <<"EOS";
#!/usr/bin/env perl
use strict;
use warnings;
use JSON::XS;

print "Content-Type: application/json;\\n\\n";
print encode_json({
    host            => \$ENV{HTTP_HOST},
    path            => \$ENV{REQUEST_URI},
    path_translated => \$ENV{PATH_TRANSLATED} . (\$ENV{REQUEST_URI} =~ /\\?/ ? "?\$ENV{QUERY_STRING}" : '')
});
EOS

    my $receiver_file = sprintf '%s/%s', $self->server_root, $receiver_path_name;
    open my $fh, "> $receiver_file" or die $!;
    print $fh $receiver;
    close $fh;
    chmod 0755, $receiver_file
        or die "Couldn't chmod receiver file: $receiver_file";

    $self->{receiver} = file($receiver_file);
}

sub custom_conf {
    my $self = shift;

    croak "rewrite conf is required"
        if !$self->rewrite_conf;

    my $custom_conf  = '';
    for my $backend (@{$self->{backends}}) {
        $custom_conf .= sprintf "SetEnvIf Request_URI .* %s=localhost:%s\n",
            $backend->{name}, $backend->{port};
    }

    $custom_conf .= <<"EOS";
ServerName   proxy.test:@{[$self->proxy_port]}
DocumentRoot @{[$self->server_root]}

RewriteRule ^/url\\.cgi/ - [L]

Include "@{[$self->rewrite_conf]}"

Action default-proxy-handler /@{[$self->receiver->basename]} virtual
SetHandler default-proxy-handler

<Location /@{[$self->receiver->basename]}>
  SetHandler cgi-script
</Location>
EOS
}

my @required_modules = qw(
    log_config
    setenvif
    alias
    rewrite
    authn_file
    authz_host
    auth_basic
    mime
    proxy
    proxy_http
    cgi
    actions
);

sub apache {
    my $self = shift;
    return $self->{apache} if $self->{apache};

    my $apache_options = $self->{apache_options} || {};
    $self->{apache} = Test::Httpd::Apache2->new(
        auto_start       => 0,
        listen           => $self->proxy_port,
        required_modules => \@required_modules,
        %$apache_options,
    );
    $self->{apache}->server_root($self->{apache}->tmpdir);
    $self->{apache}
}

sub start_apache {
    my $self = shift;
       $self->apache->custom_conf($self->custom_conf);
       $self->apache->start;

    for my $backend (@{$self->{backends}}) {
        $backend->{apache}->start;
    }
}

sub stop_apache {
    my $self = shift;
       $self->apache->stop if $self->apache->pid;

    for my $backend (@{$self->{backends}}) {
        $backend->{apache}->stop if $backend->{apache}->pid;
    }
}

sub create_backend_apache {
    my ($self, %backend) = @_;
    my $apache_options = $self->{apache_options} || {};
    my $proxy_apache   = $self->apache;
    my $backend_apache = Test::Httpd::Apache2->new(
        auto_start       => 0,
        listen           => $backend{port},
        required_modules => \@required_modules,
        %$apache_options,
    );
    $backend_apache->server_root($proxy_apache->server_root);
    $backend_apache->custom_conf(<<"EOS");
ServerName   @{[$backend{name}]}.test:@{[$backend{port}]}
DocumentRoot @{[$backend_apache->server_root]}

AddHandler cgi-script .cgi
<Location @{[$backend_apache->server_root]}>
  Options +ExecCGI
</Location>

RewriteEngine on
RewriteRule /(.*) /@{[$self->receiver->basename]}/\$1 [L]
EOS
    $backend_apache;
}

sub get_rewrite_result {
    my ($self, %args) = @_;

    my $url    = $self->proxy_http_url($args{orig_path});
    my $method = $Test::Apache::RewriteRules::ClientEnvs::RequestMethod || 'GET';

    my $req = HTTP::Request->new($method => $url);
    my $ua  = LWP::UserAgent->new(max_redirect => 0, agent => '');

    my $UA = $Test::Apache::RewriteRules::ClientEnvs::UserAgent;
    if (defined $UA) {
        $UA =~ s/%%SBSerialNumber%%//g;
        $req->header('User-Agent' => $UA);
    }

    if ($args{orig_path} =~ m[^//([^/]*)/]) {
        $req->header(Host => $1);
    }

    my $cookies = $Test::Apache::RewriteRules::ClientEnvs::Cookies || [];
    if (@$cookies) {
        $cookies = [@$cookies];
        my @c;
        while (@$cookies) {
            my $n = shift @$cookies;
            my $v = shift @$cookies;
            push @c, $n . '=' . $v;
        }
        $req->header(Cookie => join '; ', @c);
    }

    my $header = $Test::Apache::RewriteRules::ClientEnvs::HttpHeader || [];
    if (@$header) {
        $header = [@$header];
        my @c;
        while (@$header) {
            my $n = shift @$header;
            my $v = shift @$header;
            $req->header($n => $v);
        }
    }

    my $res = $ua->request($req);
    die $res->status_line if $res->is_error;

    my $code = $res->code;
    my $result;

    if ($code >= 300) {
        $result = {
            code => $code,
        };
        $result->{location} = $res->header('Location') if $res->header('Location');
    }
    else {
        $result = eval { decode_json($res->content) };
        die $@ if $@;
        $result->{code} = $code;
        $result->{host} =~ s!
            ^(localhost:(\d+))!
            qq[$1 (@{[($self->get_backend_name_by_port($2) || '')]})]
        !xe;

        my $path_translated = delete $result->{path_translated};
        if ($args{use_path_translated}) {
            $result->{path} = $path_translated;
        }
    }

    $result;
}

sub is_host_path {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($self, $orig_path, $backend_name, $path, $name) = @_;
    $backend_name = defined $backend_name ? $backend_name : '';

    my $use_path_translated = !$backend_name;
    my $result = $self->get_rewrite_result(
        orig_path           => $orig_path,
        use_path_translated => $use_path_translated,
    );

    my $host = $backend_name
        ? $self->backend_host($backend_name)
        : $self->proxy_host;
    $host .= " ($backend_name)";

    my $expected = {
        code => 200,
        host => $host,
        path => $path,
    };

    eq_or_diff $result, $expected, $name;
}

sub is_redirect {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my ($self, $orig_path, $redirect_url, $name, %args) = @_;
    my $result = $self->get_rewrite_result(orig_path => $orig_path);
    my $code = $args{code} || 302;

    my $expected = {
        code => $code,
    };
    $expected->{location} = $redirect_url if $redirect_url;

    eq_or_diff $result, $expected, $name;
}

sub DESTROY {
    my $self = shift;
       $self->stop_apache;
}

1;

__END__

=head1 NAME

Test::Apache::RewriteRules - Testing Apache's Rewrite Rules

=head1 SYNOPSIS

  use Test::Apache::RewriteRules;

  my $apache = Test::Apache::RewriteRules->new;
     $apache->add_backend(name => 'ReverseProxyedHost1');
     $apache->add_backend(name => 'ReverseProxyedHost2');
     $apache->rewrite_conf('apache.rewrite.conf');
     $apache->start_apache;

  # testing rewritten result
  $apache->is_host_path('/foo/aaa', 'ReverseProxyedHost1', '/aaa',
                        'Handled by reverse-proxyed host 1');
  $apache->is_host_path('/bar/bbb', 'ReverseProxyedHost2', '/bbb',
                        'Handled by reverse-proxyed host 2');
  $apache->is_host_path('/baz', '', '/baz',
                        'Handled by the proxy itself');

  # testing redirection
  $apache->is_redirect('/quux/xxx', 'http://external.test/xxx');

  # rewrite rules in `apache.rewrite.conf' passed in above
  RewriteEngine on
  RewriteRule /foo/(.*)  http://%{ENV:ReverseProxyedHost1}/$1 [P,L]
  RewriteRule /bar/(.*)  http://%{ENV:ReverseProxyedHost2}/$1 [P,L]
  RewriteRule /quux/(.*) http://external.test/$1 [R,L]

=head1 DESCRIPTION

The C<Test::Apache::RewriteRules> module sets up Apache HTTPD server
for the purpose of testing of a set of C<RewriteRule>s in
C<apache.conf> Apache configuration.

=head1 METHODS

=head2 available

=over 4

  $is_available = Test::Apache::RewriteRules->available;

Returns whether the features provided by this module is available or
not. At the time of writing, it returns false is no Apache binary is
found.

=back

=head2 new (I<[%args]>)

=over 4

  $apache = Test::Apache::RewriteRules->new;

Returns a new instance of the class.

If a ref to hash as a value of C<%args> keyed as 'apache_options'
passed in, it's passed straight into C<Test::Httpd::Apache2->new()>.

=back

=head2 add_backend (I<%backend>)

=over 4

  $apache->add_backend(name => HOST_NAME);

Registers a backend (i.e. a host that handles HTTP requests). An
environment variable whose name is C<HOST_NAME> will be defined in the
automatically-generated Apache configuration file such that it can be
used in rewrite rules.

=back

=head2 copy_config (I<config_file>, \@patterns)

=over 4

  $apache->copy_config(
      $config_file, [
          PATTERN1 => REPLACE1,
          PATTERN2 => REPLACE2,
          ...
      ]
  )

Copies the file represented by C<$config_file> into the temporary
directory and optionally replaces its content by applying patterns.

Patterns, if specified, must be an array reference containing string
or regular expression followed by string or code reference. If the
replaced string is specified as a code reference, its return value is
used for the replacement. If the pattern is specified as a regular
expression and the replaced string is specified as a code reference,
the code reference can use C<$1>, C<$2>, ... to access to captured
substrings.

=back

=head2 rewrite_conf (I<$rewrite_conf>)

=over 4

  $apache->rewrite_conf($rewrite_conf)

Sets C<$rewrite_conf> file that represents the path to the
C<RewriteRule>s' part of the Apache configuration to test.

=back

=head2 start_apache

=over 4

  $apache->start_apache

Boots the Apache process. It should be invoked before any
C<is_host_path> call.

=back

=head2 is_host_path (I<$request_path>, I<$expected_host_name>, I<$expected_path>, [I<$name>])

=over 4

  $apache->is_host_path($request_path, $expected_host_name, $expected_path, $name);

Checks whether the request for C<$request_path> is handled by host
C<$expected_host_name> with path C<$expected_path>. The host name
should be specified by the name registered using C<add_backend>
method, or the empty string if the request would be handled by the
reverse proxy (i.e. the rewriting host) itself.

This method acts as a test function of L<Test::Builder> or
L<Test::More>. The argument C<$name>, if specified, represents the
name of the test.

=back

=head2 is_redirect (I<$request_path>, I<$expected_redirect_url>, [I<$name>, %args])

=over 4

  $apache->is_redirect($request_path, $expected_redirect_url, $name, code => 301);

Checks whether the request for C<$request_path> is HTTP-redirected to
the C<$expected_redirect_url>.

This method acts as a test function of L<Test::Builder> or
L<Test::More>. The argument C<$name>, if specified, represents the
name of the test.

Optionally, you can specify the expected HTTP status code. The default
status code is C<302> (Found).

=back

=head2 stop_apache

=over 4

  $apache->stop_apache

Shuts down the Apache process.

=back

=head1 DETAILS

You can set the expected client environment used to evaluate
C<is_host_path> and C<is_redirect> by using
L<Test::Apache::RewriteRules::ClientEnvs> module.

Where C<$request_path> is expected, the host of the request (used in
the C<Host:> request header field) can be specified by prepending
C<//> followed by host (hostname possibly followed by C<:> and port
number) before the real path.

=head1 EXAMPLES

See C<t/*.t> and C<t/conf/*.conf>.

=head1 SEE ALSO

=over 4

=item * mod_rewrite <http://httpd.apache.org/docs/2.2/mod/mod_rewrite.html>.

=item * L<Test::More>.

=item * L<Test::Apache::RewriteRules::ClientEnvs>.

=back

=head1 AUTHOR

=over 4

=item * Wakaba (id:wakabatan) <wakabatan@hatena.ne.jp>.

=item * Kentaro Kuribayashi (id:antipop) <antipop@hatena.ne.jp>

=back

=head1 LICENSE

Copyright 2010 Hatena <http://www.hatena.ne.jp/>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
