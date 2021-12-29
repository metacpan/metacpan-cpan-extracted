use strict;
use warnings;
use POE qw(Wheel::SocketFactory);
use POE::Component::IRC;
use POE::Component::Server::IRC;
use Test::More tests => 3;

my $ircd = POE::Component::Server::IRC->spawn(
    Auth         => 0,
    AntiFlood    => 0,
    plugin_debug => 1,
    config       => { sid => '9AR', },
);

my $irc = POE::Component::IRC->spawn(Flood => 1);

POE::Session->create(
    package_states => [
        (__PACKAGE__) => [qw(
            _start
            ircd_listener_add
            ircd_listener_failure
            irc_001
            irc_join
            irc_nick
            irc_disconnected
            _shutdown
        )],
    ],
);

POE::Kernel->run();

sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    $ircd->yield('register', 'all');
    $ircd->yield('add_listener');
    $kernel->delay(_shutdown => 60, 'Timed out');
}

sub ircd_listener_failure {
    my ($kernel, $op, $reason) = @_[KERNEL, ARG1, ARG3];
    $kernel->yield('_shutdown', "$op: $reason");
}

sub ircd_listener_add {
    my ($heap, $port) = @_[HEAP, ARG0];

    $irc->yield(register => 'all');
    $irc->yield(connect => {
        nick   => 'foo',
        server => '127.0.0.1',
        port   => $port,
    });
}

sub irc_001 {
    my $irc = $_[SENDER]->get_heap();
    pass('Logged in');
    $irc->yield(join => '#foobar');
}

sub irc_join {
    my $irc = $_[SENDER]->get_heap();
    pass('Joined channel');
    $irc->yield(nick => 'newnick');
    $irc->yield('quit');
}

sub irc_nick {
    is($_[HEAP]{got_nick}, undef, 'Got irc_nick only once');
    $_[HEAP]->{irc_nick}++;
}

sub irc_disconnected {
    $_[KERNEL]->yield('_shutdown');
}

sub _shutdown {
    $_[KERNEL]->alarm_remove_all();
    $ircd->yield('shutdown');
    $irc->yield('shutdown');
}
