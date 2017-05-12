use strict;
use warnings FATAL => 'all';
use lib 't/inc';
use POE;
use POE::Component::IRC;
use POE::Component::Server::IRC;
use Test::More tests => 6;

my $ircd = POE::Component::Server::IRC->spawn(
    Auth      => 0,
    AntiFlood => 0,
);

my $bot = POE::Component::IRC->spawn(
    Flood => 1,
    Raw   => 1,
);

isa_ok($ircd, 'POE::Component::Server::IRC');
isa_ok($bot, 'POE::Component::IRC');

POE::Session->create(
    package_states => [
        main => [qw(
            _start
            ircd_listener_add
            ircd_listener_failure
            _shutdown
            irc_connected
            irc_raw_out
            irc_001
            irc_disconnected
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
    my ($kernel, $heap, $port) = @_[KERNEL, HEAP, ARG0];

    $bot->yield(register => 'all');
    $bot->yield( connect => {
        nick    => 'TestBot',
        server  => '127.0.0.1',
        port    => $port,
    });
}

sub irc_connected {
    pass('Connected');
}

sub irc_raw_out {
    my ($raw) = $_[ARG0];
    pass('Got raw nick string') if $raw =~ /^NICK /;
}

sub irc_001 {
    my ($sender) = $_[SENDER];
    my $irc = $sender->get_heap();

    ok($irc->logged_in(), 'Logged in');
    $irc->yield('quit');
}

sub irc_disconnected {
    pass('Got irc_disconnected');
    $poe_kernel->yield('_shutdown');
}

sub _shutdown {
    my ($kernel, $error) = @_[KERNEL, ARG0];
    fail($error) if defined $error;

    $kernel->alarm_remove_all();
    $ircd->yield('shutdown');
    $bot->yield('shutdown');
}
