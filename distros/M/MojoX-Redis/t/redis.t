#!/usr/bin/env perl

# Becouse of two async applications working together this tests look ugly
# if you want to examine MojoX::Redis API take a look at t/redis_live.t

use strict;
use warnings;

use Test::More tests => 10;

use Mojo::IOLoop;
use Mojo::IOLoop::Server;

use_ok 'MojoX::Redis';

my $port = Mojo::IOLoop::Server->generate_port;


my ($sbuffer1, $sbuffer2, $sbuffer3);
my ($r, $r1, $r2, $r4);
my $redis_error;
my $curr_stream;

$r4 = 'wrong result';


my $server = Mojo::IOLoop->server(
    {port => $port},
    sub {
        my ($loop, $stream) = @_;
        $curr_stream = $stream;
        $stream->once(
            read => sub {
                my ($stream, $chunk) = @_;
                $sbuffer1 = $chunk;
                $stream->write("\$2\r\nok\r\n");
        });
    });

my $redis =
  new_ok 'MojoX::Redis' => [server => "127.0.0.1:$port", timeout => 1];
Mojo::IOLoop->timer(5 => sub { $redis->stop }); #security valve


$redis->execute(
    get => 'test',
    sub {
        my ($redis, $result) = @_;
        $r = $result;
        &test2;
    }
)->start;


is $sbuffer1, "*2\r\n\$3\r\nGET\r\n\$4\r\ntest\r\n", 'input command';
is_deeply $r, ['ok'], 'result';

is $sbuffer2,
  "*2\r\n\$3\r\nGET\r\n\$5\r\ntest1\r\n*2\r\n\$3\r\nGET\r\n\$5\r\ntest2\r\n",
  'input commands';
is_deeply $r1, ['ok1'], 'first command';
is_deeply $r2, ['ok2'], 'second command';

is $sbuffer3, "*3\r\n\$3\r\nSET\r\n\$3\r\nkey\r\n\$5\r\nvalue\r\n",
  'fast command';

is $r4,          undef,          'error result';
is $redis_error, 'disconnected', 'redis error message';

# Multiple pipelined commands
sub test2 {
    $curr_stream->once(
        read => sub {
            my ($stream, $chunk) = @_;
            $sbuffer2 .= $chunk;

            # Wait both commands to come
            if ($sbuffer2 =~ m{test2}) {
                $stream->on(read => sub { });

                # Half of first command
                $stream->write(
                    "\$3\r\nok",
                    sub {
                        Mojo::IOLoop->timer(
                            0.1 => sub {
                                my ($self) = @_;

                                # Another half with first half of second
                                $stream->write(
                                    "1\r\n\$3",
                                    sub {
                                        Mojo::IOLoop->timer(
                                            0.1 => sub {
                                                my ($self) = @_;

                                                # Done
                                                $stream->write(
                                                    "\r\nok2\r\n");
                                            }
                                        );
                                    }
                                );
                            }
                        );
                    }
                );
            }
        }
    );
    $redis->execute(
        get => 'test1',
        sub {
            my ($redis, $result) = @_;
            $r1 = $result;
        }
      )->execute(
        get => 'test2',
        sub {
            my ($redis, $result) = @_;
            $r2 = $result;
            &check3;
        }
      );
}

sub check3 {
    $curr_stream->once(
        read => sub {
            my ($stream, $chunk) = @_;
            $sbuffer3 = $chunk;

            &check4;
        }
    );

    $redis->set(key => 'value', sub { });
}

sub check4 {
    $curr_stream->once(
        read => sub {
            my ($stream, $chunk) = @_;
            Mojo::IOLoop->remove($server);
       }
    );

    $redis->execute(
        get => 'test',
        sub {
            my ($redis, $result) = @_;
            $r4          = $result;
            $redis_error = $redis->error;
            Mojo::IOLoop->stop;

        }
    );

}
