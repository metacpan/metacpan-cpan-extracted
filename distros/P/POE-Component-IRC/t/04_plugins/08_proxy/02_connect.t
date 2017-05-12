use strict;
use warnings FATAL => 'all';
use lib 't/inc';
use POE;
use POE::Component::IRC::State;
use POE::Component::IRC::Plugin::Proxy;
use POE::Component::Server::IRC;
use Socket qw(unpack_sockaddr_in);
use Test::More tests => 8;

my $bot1 = POE::Component::IRC::State->spawn(
    Flood        => 1,
    plugin_debug => 1,
);
my $bot2 = POE::Component::IRC::State->spawn(
    Flood        => 1,
    plugin_debug => 1,
);
my $ircd = POE::Component::Server::IRC->spawn(
    Auth      => 0,
    AntiFlood => 0,
);

POE::Session->create(
    package_states => [
        main => [qw(
            _start
            ircd_listener_add
            ircd_listener_failure
            irc_proxy_up
            _shutdown
            irc_001
            irc_332
            irc_topic
            irc_join
            irc_disconnected
        )],
    ],
);

$poe_kernel->run();

sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];

    $bot1->plugin_add(Proxy => POE::Component::IRC::Plugin::Proxy->new(
        password => 'proxy_pass',
    ));

    $ircd->yield('register', 'all');
    $ircd->yield('add_listener');
    $kernel->delay(_shutdown => 60, 'Timed out');
}

sub irc_proxy_up {
    my ($heap, $port) = @_[HEAP, ARG0];
    $heap->{proxy_port} = (unpack_sockaddr_in($port))[0];
}

sub ircd_listener_failure {
    my ($kernel, $op, $reason) = @_[KERNEL, ARG1, ARG3];
    $kernel->yield('_shutdown', "$op: $reason");
}

sub ircd_listener_add {
    my ($kernel, $port) = @_[KERNEL, ARG0];

    $bot1->yield(register => 'all');
    $bot1->yield(connect => {
        nick    => 'TestBot1',
        server  => '127.0.0.1',
        port    => $port,
    });
}

sub irc_001 {
    my $irc = $_[SENDER]->get_heap();

    if ($irc == $bot1) {
        pass($irc->nick_name() . ' logged in');
        $irc->yield(join => '#testchannel');
    }
    else {
        pass($irc->nick_name() . ' logged in (via proxy)');
    }
}

sub irc_join {
    my ($sender, $heap, $who, $where) = @_[SENDER, HEAP, ARG0, ARG1];
    my $nick = ( split /!/, $who )[0];
    my $irc = $sender->get_heap();

    if ($irc == $bot1) {
        like($where, qr/#testchannel/, "$nick joined $where");
        $irc->yield(topic => $where, 'Some topic');
    }
    else {
        like($where, qr/#testchannel/, "$nick joined $where (via proxy)");
    }
}

sub irc_topic {
    my ($heap, $sender, $topic) = @_[HEAP, SENDER, ARG2];
    my $irc = $sender->get_heap();

    is($topic, 'Some topic', $irc->nick_name() . ' changed topic');

    $bot2->yield(register => 'all');
    $bot2->yield(connect => {
        nick     => 'TestBot1',
        server   => '127.0.0.1',
        port     => $heap->{proxy_port},
        password => 'proxy_pass',
    });
}

sub irc_332 {
    my ($heap, $sender, $reply) = @_[HEAP, SENDER, ARG2];
    my $topic = $reply->[1];
    my $irc = $sender->get_heap();

    return if $irc != $bot2;
    is($topic, 'Some topic', $irc->nick_name() . ' got topic (via proxy)');
    $bot2->yield('quit');
    $bot1->yield('quit');
}

sub irc_disconnected {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    pass('irc_disconnected');
    $heap->{count}++;
    $kernel->yield('_shutdown') if $heap->{count} == 2;
}

sub _shutdown {
    my ($kernel, $error) = @_[KERNEL, ARG0];
    fail($error) if defined $error;

    $kernel->alarm_remove_all();
    $ircd->yield('shutdown');
    $bot1->yield('shutdown');
    $bot2->yield('shutdown');
}

