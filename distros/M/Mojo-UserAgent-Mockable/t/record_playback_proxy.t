use 5.014;

# Test MUA::Mockable behavior with CONNECT proxies. Heavily based on 
# https://metacpan.org/source/SRI/Mojolicious-7.26/t/mojo/websocket_proxy_tls.t

use Test::Most;
use FindBin qw($Bin);
BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Mojo::IOLoop;
use Mojo::Server::Daemon;
use Mojo::UserAgent::Mockable;
use Path::Tiny;

my $daemon = get_daemon();
my $port = $daemon->ports->[0];
my $proxy = get_proxy();
my $dir = Path::Tiny->tempdir;

# User agent with valid certificates
my $ua = Mojo::UserAgent::Mockable->new(
  ioloop => Mojo::IOLoop->singleton,
  ca     => qq($Bin/certs/ca.crt),
  cert   => qq($Bin/certs/client.crt),
  key    => qq($Bin/certs/client.key),
  mode   => 'record',
  file   => qq{$dir/proxy-test.out},
);

my @transactions;
$ua->on(
    start => sub {
        my $tx = $_[1];
        $tx->once( finish => sub { push @transactions, $tx; } );
    }
);

# Non-blocking proxy request
$ua->proxy->https("http://foo:bar\@127.0.0.1:$proxy");

my $url = qq{https://127.0.0.1:$port/}; 
my $tx = $ua->get($url);
my $recorded_number = $tx->res->body;
ok $recorded_number, q{Got a number};
$ua = undef;

my $connect_seen;
for my $tx (@transactions) { 
    if (sprintf ('%s %s', $tx->req->method, $tx->req->url) eq qq{CONNECT $url}) { 
        $connect_seen = 1;
    }
}
ok $connect_seen, q{Proxy CONNECT request seen};

$ua = Mojo::UserAgent::Mockable->new(
    ca   => qq($Bin/certs/ca.crt),
    cert => qq($Bin/certs/client.crt),
    key  => qq($Bin/certs/client.key),
    mode => 'playback',
    file => qq{$dir/proxy-test.out},
);
$ua->server->app->log->level('fatal');

lives_ok { $tx = $ua->get(qq{https://127.0.0.1:$port/}) } q{GET request did not die in playback mode};
my $playback_number = $tx->res->body;
is $playback_number, $recorded_number, q{Number same as recorded};


done_testing;

sub get_daemon { 
    my $app = Mojolicious->new();
    $app->routes->get( '/' => sub { shift->render( text => 1 + int rand(1000) ) } );
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
