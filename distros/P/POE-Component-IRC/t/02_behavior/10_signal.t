use strict;
use warnings FATAL => 'all';
use lib 't/inc';
use POE;
use POE::Component::IRC;
use POE::Component::Server::IRC;
use Test::More tests => 7;

my $bot = POE::Component::IRC->spawn(Flood => 1);
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
            _shutdown
            irc_registered
            irc_connected
            irc_001
            irc_error
            irc_disconnected
            irc_shutdown
        )],
    ],
);

$poe_kernel->run();

sub _start {
    my ($kernel) = $_[KERNEL];
    $ircd->yield('register', 'all');
    $ircd->yield('add_listener');
    $kernel->delay(_shutdown => 60, 'Timed out');
}

sub ircd_listener_failure {
    my ($kernel, $op, $reason) = @_[KERNEL, ARG1, ARG3];
    $kernel->yield('_shutdown', "$op: $reason");
}

sub ircd_listener_add {
    my ($kernel, $heap, $session, $port) = @_[KERNEL, HEAP, SESSION, ARG0];
    $kernel->signal($kernel, 'POCOIRC_REGISTER', $session, 'all');
    $heap->{port} = $port;
}

sub irc_registered {
    my ($heap, $irc) = @_[HEAP, ARG0];
    pass('Registered');
    isa_ok($irc, 'POE::Component::IRC');

    $irc->yield(connect => {
        nick    => 'TestBot',
        server  => '127.0.0.1',
        port    => $heap->{port},
    });
}

sub irc_connected {
    pass('Connected');
}

sub irc_001 {
    my ($kernel, $sender, $text) = @_[KERNEL, SENDER, ARG1];
    my $irc = $sender->get_heap();
    pass('Logged in');
    $irc->yield('quit');
}

sub irc_error {
    pass('irc_error');
}

sub irc_disconnected {
    pass('irc_disconnected');
    $poe_kernel->yield('_shutdown');
}

sub _shutdown {
    my ($kernel, $error) = @_[KERNEL, ARG0];
    fail($error) if defined $error;

    $kernel->alarm_remove_all();
    $ircd->yield('shutdown');
    $kernel->signal($kernel, 'POCOIRC_SHUTDOWN');
}

sub irc_shutdown {
    pass('irc_shutdown');
}
