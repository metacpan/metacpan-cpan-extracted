use 5.016;
use Mojo::Base -strict;
use FindBin qw($Bin);
BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Mojo::IOLoop::TLS;
use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use Mojo::UserAgent::Mockable;
use Mojolicious::Lite;
use MIME::Base64;

#my $daemon = get_daemon($app);
my $daemon = get_daemon();
my $port = $daemon->ports->[0];
my $proxy = get_proxy();

# User agent with valid certificates
my $ua = Mojo::UserAgent::Mockable->new(
  ioloop => Mojo::IOLoop->singleton,
  ca     => qq($Bin/certs/ca.crt),
  cert   => qq($Bin/certs/client.crt),
  key    => qq($Bin/certs/client.key),
  mode   => 'record',
  file   => 'proxy-test.out',
);
$ua->on(
    start => sub {
        my $tx = $_[1];
        $tx->once( finish => sub { say $tx->req->method, ' ', $tx->req->url } );
    }
);
# # Normal non-blocking request
my $result;

# Non-blocking proxy request
$ua->proxy->https("http://sri:secr3t\@127.0.0.1:$proxy");

my $tx = $ua->get(qq{https://127.0.0.1:$port/});
say $tx->res->body;


sub get_daemon { 
    my $app = Mojolicious->new();
    $app->routes->get( '/' => sub { shift->render( text => 'bar baz bak' ) } );
    $app->log->level('fatal');
    # Web server with valid certificates
    my $daemon = Mojo::Server::Daemon->new( app => $app, silent => 1 );
    my $listen =
          'https://127.0.0.1'
        . qq{?cert=$Bin/certs/server.crt}
        . qq{&key=$Bin/certs/server.key}
        . qq{&ca=$Bin/certs/ca.crt};
    $daemon->listen( [$listen])->start;
    return $daemon;
}

sub get_proxy {

    # Connect proxy server for testing
    my ( %buffer, $connected, $read, $sent );
    my $nf    = "HTTP/1.1 501 FOO\x0d\x0a" . "Content-Length: 0\x0d\x0a" . "Connection: close\x0d\x0a\x0d\x0a";
    my $ok    = "HTTP/1.1 200 OK\x0d\x0aConnection: keep-alive\x0d\x0a\x0d\x0a";
    my $dummy = Mojo::IOLoop::Server->generate_port;
    my $id    = Mojo::IOLoop->server(
        { address => '127.0.0.1' } => sub {
            my ( $loop, $stream, $id ) = @_;

            # Connection to client
            $stream->on(
                read => sub {
                    my ( $stream, $chunk ) = @_;

                    # Write chunk from client to server
                    my $server = $buffer{$id}{connection};

                    # say qq{<TOSERVER id="$id">}, encode_base64($chunk), q{</TOSERVER>} if $server;
                    return Mojo::IOLoop->stream($server)->write($chunk) if $server;

                    # Read connect request from client
                    my $buffer = $buffer{$id}{client} .= $chunk;
                    if ( $buffer =~ /\x0d?\x0a\x0d?\x0a$/ ) {
                        $buffer{$id}{client} = '';
                        if ( $buffer =~ /CONNECT (\S+):(\d+)?/ ) {
                            $connected = "$1:$2";
                            my $fail = $2 == $dummy;

                            # Connection to server
                            $buffer{$id}{connection} = Mojo::IOLoop->client(
                                { address => $1, port => $fail ? $port : $2 } => sub {
                                    my ( $loop, $err, $stream ) = @_;

                                    # Connection to server failed
                                    if ($err) {
                                        Mojo::IOLoop->remove($id);
                                        return delete $buffer{$id};
                                    }

                                    # Start forwarding data in both directions
                                    Mojo::IOLoop->stream($id)->write( $fail ? $nf : $ok );
                                    $stream->on(
                                        read => sub {
                                            my ( $stream, $chunk ) = @_;
                                            $read += length $chunk;
                                            $sent += length $chunk;
                                            # say qq{<TOCLIENT id="$id">}, encode_base64($chunk), q{</TOCLIENT>};
                                            Mojo::IOLoop->stream($id)->write($chunk);
                                        }
                                    );

                                    # Server closed connection
                                    $stream->on(
                                        close => sub {
                                            Mojo::IOLoop->remove($id);
                                            delete $buffer{$id};
                                        }
                                    );
                                }
                            );
                        }

                        # Invalid request from client
                        else { Mojo::IOLoop->remove($id) }
                    }
                }
            );

            # Client closed connection
            $stream->on(
                close => sub {
                    my $buffer = delete $buffer{$id};
                    Mojo::IOLoop->remove( $buffer->{connection} ) if $buffer->{connection};
                }
            );
        }
    );
    my $proxy = Mojo::IOLoop->acceptor($id)->port;
    return $proxy;
}
