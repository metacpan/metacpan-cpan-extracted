use strict;
use warnings;
use Test::More tests => 7;
use POE;
use POE::Component::Server::IRC;

my $pocosi = POE::Component::Server::IRC->spawn(
    auth         => 0,
    antiflood    => 0,
    plugin_debug => 1,
);

POE::Session->create(
    package_states => [
        'main' => [qw(
            _start
            _shutdown
            ircd_daemon_quit
            ircd_daemon_nick
        )],
    ],
    heap => { ircd => $pocosi },
);

$poe_kernel->run();

sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    $heap->{ircd}->yield('register', 'all');
    $heap->{ircd}->yield(
        'add_spoofed_nick',
        {
            nick  => 'OperServ',
            umode => 'o',
        },
    );
    $kernel->delay('_shutdown', 20);
}

sub _shutdown {
    my $heap = $_[HEAP];
    $_[KERNEL]->delay('_shutdown');
    $heap->{ircd}->yield('shutdown');
    delete $heap->{ircd};
}

sub ircd_daemon_quit {
    pass('Deleted Spoof User');
    $poe_kernel->yield('_shutdown');
}

sub ircd_daemon_nick {
    my @args = @_[ARG0..$#_];

    is($args[0], 'OperServ', 'Spoof Test 1: Nick');
    is($args[4], 'OperServ', 'Spoof Test 1: User');
    is($args[5], 'poco.server.irc', 'Spoof Test 1: Host');
    is($args[6], 'poco.server.irc', 'Spoof Test 1: Server');
    is($args[3], '+o', 'Spoof Test 1: Umode');
    is($args[7], "* I'm too lame to read the documentation *", 'Spoof Test 1: GECOS');
    $_[SENDER]->get_heap()->yield('del_spoofed_nick', $args[0]);
}
