# -*- perl -*-
#
#  Net::Server::PSGI - Extensible Perl HTTP PSGI base server
#
#  $Id$
#
#  Copyright (C) 2011-2012
#
#    Paul Seamons
#    paul@seamons.com
#    http://seamons.com/
#
#  This package may be distributed under the terms of either the
#  GNU General Public License
#    or the
#  Perl Artistic License
#
################################################################

package Net::Server::PSGI;

use strict;
use base qw(Net::Server::HTTP);

sub net_server_type { __PACKAGE__ }

sub options {
    my $self = shift;
    my $ref  = $self->SUPER::options(@_);
    my $prop = $self->{'server'};
    $ref->{$_} = \$prop->{$_} for qw(app);
    return $ref;
}

sub post_configure {
    my $self = shift;
    my $prop = $self->{'server'};

    $prop->{'log_handle'} = IO::Handle->new;
    $prop->{'log_handle'}->fdopen(fileno(STDERR), "w");
    $prop->{'no_client_stdout'} = 1;

    $self->SUPER::post_configure(@_);
}

sub _tie_client_stdout {} # the client should not print directly

sub process_request {
    my $self = shift;

    local $SIG{'ALRM'} = sub { die "Server Timeout\n" };
    my $ok = eval {
        alarm($self->timeout_header);
        $self->process_headers;

        alarm($self->timeout_idle);
        my $env = \%ENV;
        $env->{'psgi.version'}      = [1, 0];
        $env->{'psgi.url_scheme'}   = ($ENV{'HTTPS'} && $ENV{'HTTPS'} eq 'on') ? 'https' : 'http';
        $env->{'psgi.input'}        = $self->{'server'}->{'client'};
        $env->{'psgi.errors'}       = $self->{'server'}->{'log_handle'};
        $env->{'psgi.multithread'}  = 1;
        $env->{'psgi.multiprocess'} = 1;
        $env->{'psgi.nonblocking'}  = 1; # need to make this false if we aren't of a forking type server
        $env->{'psgi.streaming'}    = 1;
        local %ENV;
        $self->process_psgi_request($env);
        alarm(0);
        1;
    };
    alarm(0);

    if (! $ok) {
        my $err = "$@" || "Something happened";
        $self->send_500($err);
        die $err;
    }
}

sub process_psgi_request {
    my ($self, $env) = @_;
    my $app = $self->find_psgi_handler($env);
    my $resp = $app->($env);
    return $resp->(sub {
        my $resp = shift;
        $self->print_psgi_headers($resp->[0], $resp->[1]);
        return $self->{'server'}->{'client'} if @$resp == 2;
        return $self->print_psgi_body($resp->[2]);
    }) if ref($resp) eq 'CODE';
    $self->print_psgi_headers($resp->[0], $resp->[1]);
    $self->print_psgi_body($resp->[2]);
}

sub find_psgi_handler { shift->app || \&psgi_echo_handler }

sub app {
    my $self = shift;
    $self->{'server'}->{'app'} = shift if @_;
    my $app = $self->{'server'}->{'app'};
    if (!ref($app) && $app) {
        $app = $self->{'server'}->{'app'} = eval { require CGI::Compile; CGI::Compile->compile($app) }
            || die "Failed to compile app with CGI::Compile";
    }
    return $app;
}

sub print_psgi_headers {
    my ($self, $status, $headers) = @_;
    $self->send_status($status);
    my $request_info = $self->{'request_info'};
    my $out = '';
    for my $i (0 .. @{ $headers || [] } / 2 - 1) {
        my $key = "\u\L$headers->[$i*2]";
        my $val = $headers->[$i*2 + 1];
        $key =~ y/_/-/;
        $out .= "$key: $val\015\012";
        push @{ $request_info->{'response_headers'} }, [$key, $val];
    }
    $out .= "\015\012";
    $request_info->{'response_header_size'} += length $out;
    $self->{'server'}->{'client'}->print($out);
    $request_info->{'headers_sent'} = 1;
}

sub print_psgi_body {
    my ($self, $body) = @_;
    my $client = $self->{'server'}->{'client'};
    my $request_info = $self->{'request_info'};
    if (ref $body eq 'ARRAY') {
        for my $chunk (@$body) {
            $client->print($chunk);
            $request_info->{'response_size'} += length $chunk;
        }
    } elsif (blessed($body) && $body->can('getline')) {
        while (defined(my $chunk = $body->getline)) {
            $client->print($chunk);
            $request_info->{'response_size'} += length $chunk;
        }
    } else {
        while (defined(my $chunk = <$body>)) {
            $client->print($chunk);
            $request_info->{'response_size'} += length $chunk;
        }
    }
}

sub psgi_echo_handler {
    my $env = shift;
    my $txt = qq{<form method="post" action="/bam"><input type="text" name="foo"><input type="submit"></form>\n};
    if (eval { require Data::Dumper }) {
        local $Data::Dumper::Sortkeys = 1;
        my $form = {};
        if (eval { require CGI::PSGI }) {  my $q = CGI::PSGI->new($env); $form->{$_} = $q->param($_) for $q->param;  }
        $txt .= "<pre>".Data::Dumper->Dump([$env, $form], ['env', 'form'])."</pre>";
    }
    return [200, ['Content-type', 'text/html'], [$txt]];
}

sub exec_cgi { die "Not implemented" }
sub exec_trusted_perl { die "Not implemented" }

1;

__END__

=head1 NAME

Net::Server::PSGI - basic Net::Server based PSGI HTTP server class

=head1 TEST ONE LINER

    perl -e 'use base qw(Net::Server::PSGI); main->run(port => 8080, ipv => "*")'
    # runs a default echo server

=head1 SYNOPSIS

    use base qw(Net::Server::PSGI);
    __PACKAGE__->run(app => \&my_echo_handler); # will bind IPv4 port 80

    sub my_echo_handler {
        my $env = shift;
        my $txt = qq{<form method="post" action="/bam"><input type="text" name="foo"><input type="submit"></form>\n};

        require Data::Dumper;
        local $Data::Dumper::Sortkeys = 1;

        require CGI::PSGI;
        my $form = {};
        my $q = CGI::PSGI->new($env);
        $form->{$_} = $q->param($_) for $q->param;

        $txt .= "<pre>".Data::Dumper->Dump([$env, $form], ['env', 'form'])."</pre>";

        return [200, ['Content-type', 'text/html'], [$txt]];
    }

=head1 DESCRIPTION

If you want a more fully featured PSGI experience, it would be wise to
look at the L<Plack> and L<Starman> set of modules.  Net::Server::PSGI
is intended as an easy gateway into PSGI.  But to get the most out of
all that PSGI has to offer, you should review the L<Plack> and
L<Plack::Middleware>.  If you only need something a little more
rudimentary, then Net::Server::PSGI may be good for you.

Net::Server::PSGI takes Net::Server::HTTP one level farther.  It
begins with base type MultiType defaulting to Net::Server::Fork.  It
is easy to change it to any of the other Net::Server flavors by
passing server_type => $other_flavor in the server configurtation.
The port has also been defaulted to port 80 - but could easily be
changed to another through the server configuration.  You can also
very easily add ssl by including, proto=>"ssl" and provide a
SSL_cert_file and SSL_key_file.

For example, here is a basic server that will bind to all interfaces,
will speak both HTTP on port 8080 as well as HTTPS on 8443, and will
speak both IPv4, as well as IPv6 if it is available.

    use base qw(Net::Server::PSGI);

    __PACKAGE__->run(
        port  => [8080, "8443/ssl"],
        ipv   => '*', # IPv6 if available
        SSL_key_file  => '/my/key',
        SSL_cert_file => '/my/cert',
    );

=head1 METHODS

=over 4

=item C<process_request>

This method has been overridden in Net::Server::PSGI - you should not
use it while using Net::Server::PSGI.  This overridden method parses
the environment and sets up request alarms and handles dying failures.
It calls process_psgi_request once the request is ready and headers
have been parsed.

=item C<process_psgi_request>

Used when psgi_enabled is true.  During this method, find_psgi_handler
will be called to return the appropriate psgi response handler.  Once
finished, print_psgi_headers and print_psgi_body are used to print out
the response.  See L<PSGI>.

Typically this method should not be overridden.  Instead, an appropriate
method for finding the app should be given to find_psgi_handler or app.

=item C<find_psgi_handler>

Used to lookup the appropriate PSGI handler.  A reference to the
already parsed $env hashref is passed.  PATH_INFO will be initialized
to the full path portion of the URI.  SCRIPT_NAME will be initialized
to the empty string.  This handler should set the appropriate values
for SCRIPT_NAME and PATH_INFO depending upon the path matched.  A code
reference for the handler should be returned.  The default
find_psgi_handler will call the C<app> method.  If that fails a
reference to the psgi_echo_handler is returned as the default
application.

    sub find_psgi_handler {
        my ($self, $env) = @_;

        if ($env->{'PATH_INFO'} && $env->{'PATH_INFO'} =~ s{^ (/foo) (?= $ | /) }{}x) {
            $env->{'SCRIPT_NAME'} = $1;
            return \&foo_app;
        }

        return $self->SUPER::find_psgi_handler($env);
    }

=item C<app>

Return a reference to the application being served.  This should
be a valid PSGI application.  See L<PSGI>.  By default it will look
at the value of the C<app> configuration option.  The C<app> method
may also be used to set the C<app> configuration option.

    package MyApp;
    use base qw(Net::Server::PSGI);

    sub default_server_type { 'Prefork' }

    sub my_app {
        my $env = shift;
        return [200, ['Content-type', 'text/html'], ["Hello world"]];
    }


    MyApp->run(app => \&my_app);


    # OR
    sub app { \&my_app }
    MyApp->run;


    # OR
    my $server = MyApp->new;
    $server->app(\&my_app);
    $server->run;

=back

=head1 OPTIONS

In addition to the command line arguments of the Net::Server::HTTP
base classes you can also set the following options.

=over 4

=item app

Should return a coderef of the PSGI application.  Is returned by the
app method.

=back

=head1 AUTHOR

Paul T. Seamons paul@seamons.com

=head1 SEE ALSO

Please see also
L<Plack>,
L<Starman>,

L<Net::Server::Fork>,
L<Net::Server::INET>,
L<Net::Server::PreFork>,
L<Net::Server::PreForkSimple>,
L<Net::Server::MultiType>,
L<Net::Server::Single>
L<Net::Server::SIG>
L<Net::Server::Daemonize>
L<Net::Server::Proto>
L<Net::Server::HTTP>

=cut

