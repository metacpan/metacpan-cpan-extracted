package Tailscale::HttpServer;
use strict;
use warnings;

use HTTP::Request;
use HTTP::Response;
use HTTP::Status qw(:constants);
use Carp qw(croak);

sub new {
    my ($class, %args) = @_;
    my $ts   = $args{tailscale} // croak "tailscale is required";
    my $port = $args{port}      // 80;

    return bless {
        _ts   => $ts,
        _port => $port,
    }, $class;
}

# Run the server with a handler callback.
# The callback receives an HTTP::Request and returns an HTTP::Response.
sub run {
    my ($self, $handler) = @_;
    croak "handler callback is required" unless ref $handler eq 'CODE';

    my $listener = $self->{_ts}->tcp_listen($self->{_port});
    my $ip = $self->{_ts}->ipv4_addr();
    print "Tailscale HTTP server listening on $ip:$self->{_port}\n";

    while (1) {
        my $stream = eval { $listener->accept() };
        unless ($stream) {
            warn "accept failed: $@\n";
            next;
        }

        eval { $self->_handle_connection($stream, $handler) };
        warn "connection error: $@\n" if $@;
        $stream->close();
    }
}

# Accept a single connection and handle it. Useful for testing.
sub accept_once {
    my ($self, $listener, $handler) = @_;
    my $stream = $listener->accept();
    eval { $self->_handle_connection($stream, $handler) };
    warn "connection error: $@\n" if $@;
    $stream->close();
}

sub _handle_connection {
    my ($self, $stream, $handler) = @_;

    # Read request data until we see end of headers.
    my $raw = "";
    while (1) {
        my $chunk = $stream->recv(4096);
        last unless defined $chunk;
        $raw .= $chunk;
        last if $raw =~ /\r\n\r\n/;
    }
    return unless length $raw;

    # Split headers from body.
    my ($header_part, $body) = split /\r\n\r\n/, $raw, 2;
    $body //= "";

    # Parse the request line and headers.
    my @lines = split /\r\n/, $header_part;
    my $request_line = shift @lines;
    my ($method, $uri, $proto) = split /\s+/, $request_line, 3;
    $proto //= "HTTP/1.0";

    # Build HTTP::Request.
    my $req = HTTP::Request->new($method, $uri);
    $req->protocol($proto);
    for my $line (@lines) {
        if ($line =~ /^([^:]+):\s*(.*)$/) {
            $req->header($1 => $2);
        }
    }

    # If there's a Content-Length, read the remaining body.
    my $content_length = $req->header('Content-Length');
    if ($content_length && length($body) < $content_length) {
        my $remaining = $content_length - length($body);
        while ($remaining > 0) {
            my $chunk = $stream->recv($remaining);
            last unless defined $chunk;
            $body .= $chunk;
            $remaining -= length($chunk);
        }
    }
    $req->content($body) if length $body;

    # Call handler.
    my $res = $handler->($req);
    unless (ref $res && $res->isa('HTTP::Response')) {
        $res = HTTP::Response->new(HTTP_INTERNAL_SERVER_ERROR);
        $res->content("Internal Server Error\n");
    }

    # Ensure Content-Length is set.
    my $content = $res->content // "";
    $res->header('Content-Length' => length($content));
    $res->header('Connection' => 'close');
    $res->protocol('HTTP/1.0');

    # Format and send the response.
    my $status_line = sprintf "HTTP/1.0 %d %s\r\n",
        $res->code, HTTP::Status::status_message($res->code);
    my $headers = "";
    $res->headers->scan(sub { $headers .= "$_[0]: $_[1]\r\n" });
    my $response_str = $status_line . $headers . "\r\n" . $content;
    $stream->send_all($response_str);
}

1;

__END__

=head1 NAME

Tailscale::HttpServer - minimal HTTP server on a Tailscale network

=head1 SYNOPSIS

    use Tailscale;
    use Tailscale::HttpServer;
    use HTTP::Response;

    my $ts = Tailscale->new(
        config_path => "state.json",
        auth_key    => "tskey-auth-...",
    );

    my $httpd = Tailscale::HttpServer->new(
        tailscale => $ts,
        port      => 8080,
    );

    $httpd->run(sub {
        my ($req) = @_;    # HTTP::Request

        my $res = HTTP::Response->new(200);
        $res->header('Content-Type' => 'text/plain');
        $res->content("Hello from Perl!\n");
        return $res;
    });

=head1 DESCRIPTION

A simple, single-threaded HTTP/1.0 server that runs on a Tailscale
network.  It uses L<HTTP::Request> for parsing incoming requests and
L<HTTP::Response> for formatting outgoing responses.  The actual
network transport is provided by the L<Tailscale> TCP primitives.

This is intentionally minimal.  For production use you would likely
want to build a PSGI/Plack adapter on top of the L<Tailscale> TCP API
instead.

=head1 CONSTRUCTOR

=head2 new

    my $httpd = Tailscale::HttpServer->new(%args);

Arguments:

=over 4

=item tailscale (required)

A L<Tailscale> object representing the node to serve on.

=item port

The TCP port to listen on.  Defaults to 80.

=back

=head1 METHODS

=head2 run

    $httpd->run(\&handler);

Listens on the configured port and enters an accept loop.  For each
incoming connection the request is parsed into an L<HTTP::Request> and
passed to C<\&handler>, which must return an L<HTTP::Response>.  The
response is sent back to the client and the connection is closed.

This method does not return.

=head2 accept_once

    $httpd->accept_once($listener, \&handler);

Accepts a single connection on the given L<Tailscale::TcpListener>,
handles it with C<\&handler>, and returns.  Useful for testing.

=head1 SEE ALSO

L<Tailscale>, L<Tailscale::TcpStream>, L<HTTP::Request>,
L<HTTP::Response>

=head1 AUTHOR

Brad Fitzpatrick <brad@danga.com>

=head1 LICENSE

BSD-3-Clause

=cut
