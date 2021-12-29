use strict;
use warnings;
use POE qw(Wheel::SocketFactory);
use POE::Component::IRC;
use POE::Component::Server::IRC;
use Test::More tests => 4;

my $bot1 = POE::Component::IRC->spawn(flood => 1);
my $ircd = POE::Component::Server::IRC->spawn(
    Auth         => 0,
    AntiFlood    => 0,
    plugin_debug => 1,
    config       => { sid => '1PP', },
);

POE::Session->create(
    package_states => [
        main => [qw(
            _start
            ircd_listener_add
            ircd_listener_failure
            _shutdown
            irc_001
            irc_433
            irc_error
            irc_disconnected
        )],
    ],
);

$poe_kernel->run();

sub _start {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    $ircd->yield('register', 'all');
    $ircd->add_listener();
    $ircd->add_auth(
        mask     => "*",
        password => 'foo',
    );
    $kernel->delay(_shutdown => 60, 'Timed out');
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
        ircname => 'Test test bot',
    });
}

sub irc_001 {
    my $irc = $_[SENDER]->get_heap();
    fail("Shouldn't be able to log in");
}

sub irc_error {
    my ($error) = $_[ARG0];
    like($error, qr/not authorized/, 'Not authorized to connect');
}

sub irc_433 {
    my $irc = $_[SENDER]->get_heap();
    fail("The nick shouldn't be taken");
}

sub irc_disconnected {
    my ($kernel, $sender, $heap) = @_[KERNEL, SENDER, HEAP];
    my $irc = $sender->get_heap();

    pass('Disconnected');
    $heap->{count}++;
    $irc->yield('connect') if $heap->{count} == 1;
    $kernel->yield('_shutdown') if $heap->{count} == 2;
}

sub _shutdown {
    my ($kernel) = $_[KERNEL];

    $kernel->alarm_remove_all();
    $ircd->yield('shutdown');
    $bot1->yield('shutdown');
}
