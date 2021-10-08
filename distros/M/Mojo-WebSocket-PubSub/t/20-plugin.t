package Skel;

use Mojo::Base 'Mojolicious';

sub startup {
    my $s = shift;
    $s->plugin(
        Config => {
            default => {
                secrets => ['I love Mojolicious'],
                plugins =>
                  [ { 'Mojolicious::Plugin::PubSub::WebSocket' => {} }, ]
            }
        }
    );
}

package main;
use Test::More;
use Mojo::Base -strict;
use Test::Mojo;
use Mojo::WebSocket::PubSub::Syntax;

my $t   = Test::Mojo->new('Skel');
my $syn = new Mojo::WebSocket::PubSub::Syntax;

my $app = $t->app;
my $r   = $app->routes;

sub j {
    return { json => shift };
}


subtest 'keepalive' => sub {
    $t->websocket_ok('/psws')->send_ok( j $syn->keepalive )
      ->finish_ok->finished_ok(1005);
};

subtest 'ping' => sub {
    my $ping = $syn->ping;
    my $cts  = $ping->{cts};
    $t->websocket_ok('/psws')->send_ok( j $ping)->message_ok('got reply')
      ->json_message_is( '/t'   => 'o',  'Correct reply type' )
      ->json_message_is( '/cts' => $cts, 'Correct time in reply' )
      ->finish_ok->finished_ok(1005);
};

subtest 'join channel' => sub {
    my $ch = 'channel1';
    $t->websocket_ok('/psws')->send_ok( j $syn->listen($ch) )
      ->message_ok('got reply')
      ->json_message_is( '/t'  => 'd', 'Correct reply type' )
      ->json_message_is( '/ch' => $ch, 'Correct channel in reply' )
      ->finish_ok->finished_ok(1005);
};

subtest 'channel com' => sub {
    my $ch   = 'channel1';
    my $smsg = j $syn->listen($ch);
    my $w1   = $t->websocket_ok('/psws')->send_ok($smsg)
      ->message_ok('First client subscribe to channel');
    my $w2 = $t->websocket_ok('/psws')->send_ok($smsg)
      ->message_ok('Second client subscribe to channel');

    my $msg = 'Hello World';
    $w1->send_ok( j $syn->notify($msg) );
    $w2->message_ok('Got channel message')
      ->json_message_is( '/msg' => $msg, 'Correct message' );

    $_->finish_ok->finished_ok(1005) foreach ( $w1, $w2 );
};

subtest 'multiple subscribers' => sub {
    my $ch   = 'channel1';
    my $smsg = j $syn->listen($ch);
    my @s;
    my $i   = 0;
    my $msg = 'Hello World';

    # create ten subscribers
    push @s, $t->websocket_ok('/psws')->send_ok($smsg)->message_ok( 'Register subscriber n. ' . $_ )
      for ( 1 .. 10 );

    # the first notify
    my $notifier = shift(@s);
    $notifier->send_ok( j $syn->notify($msg) )
      ->message_ok("Send message from notifier " );

    my @p;

    # client received notify
    Mojo::Promise->map(
        sub {
            my $client = $_;
            Mojo::IOLoop->subprocess->run_p(
                sub {
                    $client->message_ok("Subscriber recived notify")->message("rcvd");
                }
            );
        },
        @s
    )->wait;

};

done_testing();
