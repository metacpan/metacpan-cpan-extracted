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
use Mojo::WebSocket::PubSub;

use Test::Mojo;

my $t = Test::Mojo->new('Skel');
my $url = $t->ua->server->url->to_string;

subtest 'subscriber survives for more than timeout period' => sub {
    my $ps = new Mojo::WebSocket::PubSub(url => "${url}psws");
    my $timeout = 2;
    Mojo::IOLoop->stream($ps->tx->connection)->timeout($timeout);
    # reset keepalive timer
    $ps->_send_keepalive;
    Mojo::IOLoop->timer(($timeout*2) => sub {Mojo::IOLoop->stop;});
    Mojo::IOLoop->start;
    is($ps->tx->is_finished, '', "Survivor")
};


subtest 'subscribers on different channel' => sub {
    my $ps_s = new Mojo::WebSocket::PubSub(url => "${url}psws");
    my $ps_r = new Mojo::WebSocket::PubSub(url => "${url}psws");
    my $ps_o = new Mojo::WebSocket::PubSub(url => "${url}psws");

    my $ch1 = "foo";
    my $ch2 = "bar";

    my $rc_r = 0;
    my $rc_o = 0;

    $ps_r->listen($ch1);
    $ps_r->on(notify => sub {$rc_r = 1});

    $ps_o->listen($ch2);
    $ps_o->on(notify => sub {$rc_o = 1});

    $ps_s->listen($ch1);
    $ps_s->publish("newrec");

    is($rc_r,1, "Subscriber on same channel received message");
    is($rc_o,0, "Subscriber on different channel didn't receive message");
};

done_testing();

1;
