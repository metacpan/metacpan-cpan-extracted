use Mojo::Base -strict;

BEGIN { $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll' }

use Test::More;
use Mojo::UserAgent::Mockable;
use Mojo::IOLoop;
use Mojo::IOLoop::Server;
use Mojo::Server::Daemon;
use Mojo::UserAgent;
use Mojolicious::Lite;

# Silence
app->log->level('fatal');

get '/' => sub {
  my $c   = shift;
  my $rel = $c->req->url;
  my $abs = $rel->to_abs;
  $c->render(text => "Hello World! $rel $abs");
};

get '/proxy' => sub {
  my $c = shift;
  $c->render(text => $c->req->url);
};

websocket '/test' => sub {
  my $c = shift;
  $c->on(message => sub { shift->send(shift() . 'test2') });
};

# HTTP server for testing
#my $ua = Mojo::UserAgent::Mockable->new(ioloop => Mojo::IOLoop->singleton, mode => 'record', file => 'proxy-test.out');
my $ua = Mojo::UserAgent->new(ioloop => Mojo::IOLoop->singleton);
$ua->on(
    start => sub {
        my $tx = $_[1];
        $tx->once(
            finish => sub {
                my $url    = $tx->req->url;
                my $method = $tx->req->method;
                say qq{$method $url};
            }
        );
    }
);
my $daemon = Mojo::Server::Daemon->new(app => app, silent => 1);
my $listen
  = 'https://127.0.0.1'
  . '?cert=t/mojo/certs/server.crt'
  . '&key=t/mojo/certs/server.key'
  . '&ca=t/mojo/certs/ca.crt';
my $port = $daemon->listen([$listen])->start->ports->[0];

# CONNECT proxy server for testing
my (%buffer, $connected, $read, $sent);
my $nf
  = "HTTP/1.1 404 NOT FOUND\x0d\x0a"
  . "Content-Length: 0\x0d\x0a"
  . "Connection: close\x0d\x0a\x0d\x0a";
my $ok    = "HTTP/1.0 201 BAR\x0d\x0aX-Something: unimportant\x0d\x0a\x0d\x0a";
my $dummy = Mojo::IOLoop::Server->generate_port;
my $id    = Mojo::IOLoop->server(
  {address => '127.0.0.1'} => sub {
    my ($loop, $stream, $id) = @_;
    say qq{$id PROXY};

    # Connection to client
    $stream->on(
      read => sub {
        my ($stream, $chunk) = @_;

        # Write chunk from client to server
        my $server = $buffer{$id}{connection};
        say qq{<TOSERVER id="$id">$chunk</TOSERVER>};
        return Mojo::IOLoop->stream($server)->write($chunk) if $server;

        # Read connect request from client
        my $buffer = $buffer{$id}{client} .= $chunk;
        say qq{<BUFFER>$buffer</BUFFER>};
        if ($buffer =~ /\x0d?\x0a\x0d?\x0a$/) {
          $buffer{$id}{client} = '';
          if ($buffer =~ /CONNECT (\S+):(\d+)?/) {
            $connected = "$1:$2";
            my $fail = $2 == $dummy;

            # Connection to server
            $buffer{$id}{connection} = Mojo::IOLoop->client(
              {address => $1, port => $fail ? $port : $2} => sub {
                my ($loop, $err, $stream) = @_;

                # Connection to server failed
                if ($err) {
                  Mojo::IOLoop->remove($id);
                  return delete $buffer{$id};
                }

                # Start forwarding data in both directions
                Mojo::IOLoop->stream($id)->write($fail ? $nf : $ok);
                $stream->on(
                  read => sub {
                    my ($stream, $chunk) = @_;
                    $read += length $chunk;
                    $sent += length $chunk;
                    say qq{<TOCLIENT id="$id">$chunk</TOCLIENT>};
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
        Mojo::IOLoop->remove($buffer->{connection}) if $buffer->{connection};
      }
    );
  }
);
my $proxy = Mojo::IOLoop->acceptor($id)->port;

# Non-blocking proxy request
#$ua->proxy->http("http://127.0.0.1:$port");
$ua->proxy->http("http://127.0.0.1:$proxy");
my $tx = $ua->get('https://example.com/proxy');
use Data::Dumper;
print Dumper $tx;
#my $kept_alive;
#my $result = undef;
#$ua->get(
#  'http://example.com/proxy' => sub {
#    my ($ua, $tx) = @_;
#    $kept_alive = $tx->kept_alive;
#    $result     = $tx->res->body;
#    Mojo::IOLoop->stop;
#  }
#);
#Mojo::IOLoop->start;
#
## # ok !$kept_alive, 'connection was not kept alive';
## # is $result, 'http://example.com/proxy', 'right content';
## 
## Kept alive proxy WebSocket
# ($kept_alive, $result) = ();
# $ua->websocket(
#   "ws://127.0.0.1:$port/test?foo=bar" => sub {
#     my ($ua, $tx) = @_;
#     $kept_alive = $tx->kept_alive;
#     $tx->on(finish => sub { Mojo::IOLoop->stop });
#     $tx->on(message => sub { shift->finish; $result = shift });
#     $tx->send('test1');
#   }
# );
# Mojo::IOLoop->start;
# #ok $kept_alive, 'connection was kept alive';
# #is $result, 'test1test2', 'right result';
# 
# # Blocking proxy request
# my $tx = $ua->get('http://example.com/proxy2');
# #is $tx->res->code, 200, 'right status';
# #is $tx->res->body, 'http://example.com/proxy', 'right content';
# 
# # Proxy WebSocket
# $ua = Mojo::UserAgent->new;
# $ua->proxy->http("http://127.0.0.1:$proxy");
# $result = undef;
# $ua->websocket(
#   "ws://127.0.0.1:$port/test" => sub {
#     my ($ua, $tx) = @_;
#     $tx->on(finish => sub { Mojo::IOLoop->stop });
#     $tx->on(message => sub { shift->finish; $result = shift });
#     $tx->send('test1');
#   }
# );
# Mojo::IOLoop->start;
# #is $connected, "127.0.0.1:$port", 'connected';
# #is $result,    'test1test2',      'right result';
# #ok $read > 25, 'read enough';
# #ok $sent > 25, 'sent enough';
# 
# # Proxy WebSocket with bad target
# $ua->proxy->http("http://127.0.0.1:$proxy");
# my ($success, $leak, $err);
# $ua->websocket(
#   "ws://127.0.0.1:$dummy/test" => sub {
#     my ($ua, $tx) = @_;
#     $success = $tx->success;
#     $leak    = !!Mojo::IOLoop->stream($tx->previous->connection);
#     $err     = $tx->error;
#     Mojo::IOLoop->stop;
#   }
# );
# Mojo::IOLoop->start;
# #ok !$success, 'no success';
# #ok !$leak,    'connection has been removed';
# #is $err->{message}, 'Proxy connection failed', 'right message';

done_testing();
