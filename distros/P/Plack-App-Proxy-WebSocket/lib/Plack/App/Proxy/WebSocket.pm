package Plack::App::Proxy::WebSocket;
{
  $Plack::App::Proxy::WebSocket::VERSION = '0.03';
}
# ABSTRACT: proxy HTTP and WebSocket connections

use warnings FATAL => 'all';
use strict;

use AnyEvent::Handle;
use AnyEvent::Socket;
use HTTP::Headers;
use HTTP::Request;
use HTTP::Parser::XS qw/parse_http_response HEADERS_AS_HASHREF/;
use Plack::Request;
use URI;

use parent 'Plack::App::Proxy';


sub call {
    my ($self, $env) = @_;
    my $req = Plack::Request->new($env);

    # detect a protocol upgrade handshake or just proxy as usual
    my $upgrade = $req->header('Upgrade') or return $self->SUPER::call($env);

    $env->{'psgi.streaming'} or die "Plack server support for psgi.streaming is required";
    my $client_fh = $env->{'psgix.io'} or die "Plack server support for the psgix.io extension is required";

    my $url = $self->build_url_from_env($env) or return [502, [], ["Bad Gateway"]];
    my $uri = URI->new($url);

    sub {
        my $res = shift;

        # set up an event loop if the server is blocking
        my $cv;
        unless ($env->{'psgi.nonblocking'}) {
            $env->{'psgi.errors'}->print("Plack server support for psgi.nonblocking is highly recommended.\n");
            $cv = AE::cv;
        }

        tcp_connect $uri->host, $uri->port, sub {
            my $server_fh = shift;

            # return 502 if connection to server fails
            unless ($server_fh) {
                $res->([502, [], ["Bad Gateway"]]);
                $cv->send if $cv;
                return;
            }

            my $client = AnyEvent::Handle->new(fh => $client_fh);
            my $server = AnyEvent::Handle->new(fh => $server_fh);

            # forward request from the client
            my $headers = $self->build_headers_from_env($env, $req, $uri);
            $headers->{Upgrade} = $upgrade;
            $headers->{Connection} = 'Upgrade';
            my $hs = HTTP::Request->new('GET', $uri->path, HTTP::Headers->new(%$headers));
            $hs->protocol($req->protocol);
            $server->push_write($hs->as_string);

            my $buffer = "";
            my $writer;

            # buffer the exchange between the client and server
            $client->on_read(sub {
                my $hdl = shift;
                my $buf = delete $hdl->{rbuf};
                $server->push_write($buf);
            });
            $server->on_read(sub {
                my $hdl = shift;
                my $buf = delete $hdl->{rbuf};

                return $writer->write($buf) if $writer;
                $buffer .= $buf;

                my ($ret, $http_version, $status, $message, $headers) =
                    parse_http_response($buffer, HEADERS_AS_HASHREF);
                $server->push_shutdown if $ret == -2;
                return if $ret < 0;

                $headers = [$self->response_headers(HTTP::Headers->new(%$headers))] unless $status == 101;
                $writer = $res->([$status, $headers]);
                $writer->write(substr($buffer, $ret));
                $buffer = undef;
            });

            # shut down the sockets and exit the loop if an error occurs
            $client->on_error(sub {
                $client->destroy;
                $server->push_shutdown;
                $cv->send if $cv;
                $writer->close if $writer;
            });
            $server->on_error(sub {
                $server->destroy;
                # get the client handle's attention
                $client->push_shutdown;
            });
        };

        $cv->recv if $cv;
    };
}


sub build_headers_from_env {
    my ($self, $env, $req, $uri) = @_;

    my $headers = $self->SUPER::build_headers_from_env($env, $req);

    # if x-forwarded-for already existed, append the remote address; the super
    # method fails to maintain a list of mutiple proxies
    if (my $forwarded_for = $env->{HTTP_X_FORWARDED_FOR}) {
        $headers->{'X-Forwarded-For'} = "$forwarded_for, $env->{REMOTE_ADDR}";
    }

    # the super method depends on the user agent to add the host header if it
    # is missing, so set the host if it needs to be set
    if ($uri && !$headers->{'Host'}) {
        $headers->{'Host'} = $uri->host_port;
    }

    $headers->{'X-Forwarded-Proto'} ||= $env->{'psgi.url_scheme'};
    $headers->{'X-Real-IP'} ||= $env->{REMOTE_ADDR};

    $headers;
}

1;

__END__

=pod

=head1 NAME

Plack::App::Proxy::WebSocket - proxy HTTP and WebSocket connections

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    use Plack::App::Proxy::WebSocket;
    use Plack::Builder;

    builder {
        mount "/socket.io" => Plack::App::Proxy::WebSocket->new(
            remote               => "http://localhost:9000/socket.io",
            preserve_host_header => 1,
        )->to_app;
    };

=head1 DESCRIPTION

This is a subclass of L<Plack::App::Proxy> that adds support for transparent
(i.e. reverse) proxying WebSocket connections.  If your proxy is a forward
proxy that is to be explicitly configured in the system or browser, you may be
able to use L<Plack::Middleware::Proxy::Connect> instead.

This module works by looking for the C<Upgrade: WebSocket> header, completing
the handshake with the remote, and then buffering full-duplex between the
client and the remote.  Regular requests are handled by L<Plack::App::Proxy>
as usual, though there are a few differences related to the generation of
headers for the back-end request; see L</build_headers_from_env> for details.

This module has no configuration options beyond what L<Plack::App::Proxy>
requires or provides, so it may be an easy drop-in replacement.  Read the
documentation of that module for advanced usage not covered here.  Also, you
must use a L<PSGI> server that supports C<psgi.streaming> and C<psgix.io>.
For performance reasons, you should also use a C<psgi.nonblocking> server
(like L<Twiggy>) and the L<Plack::App::Proxy::Backend::AnyEvent::HTTP> user
agent back-end (which is the default, so no extra configuration is needed).

This module is B<EXPERIMENTAL>.  I use it in development and it works
swimmingly for me, but it is completely untested in production scenarios.

=head1 METHODS

=head2 build_headers_from_env

Supplement the headers-building logic from L<Plack::App::Proxy> to maintain
the complete list of proxies in C<X-Forwarded-For> and to set the following
headers if they are not already set: C<X-Forwarded-Proto> to the value of
C<psgi.url_scheme>, C<X-Real-IP> to the value of C<REMOTE_ADDR>, and C<Host>
to the host and port number of a URI (if given).

This is called internally.

=head1 CAVEATS

L<Starman> ignores the C<Connection> HTTP response header from applications
and chooses its own value (C<Close> or C<Keep-Alive>), but WebSocket clients
expect the value of that header to be C<Upgrade>.  Therefore, WebSocket
proxying does not work on L<Starman>.  Your best bet is to use a server that
doesn't mess with the C<Connection> header, like L<Twiggy>.

=head1 AUTHOR

Charles McGarvey <ccm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
