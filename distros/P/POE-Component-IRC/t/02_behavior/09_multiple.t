use strict;
use warnings FATAL => 'all';
use lib 't/inc';
use POE;
use POE::Component::IRC;
use POE::Component::Server::IRC;
use Test::More tests => 20;

my $bot1 = POE::Component::IRC->spawn(Flood => 1);
my $bot2 = POE::Component::IRC->spawn(Flood => 1);
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
            irc_join
            irc_mode
            irc_public
            irc_error
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
    my ($kernel, $port) = @_[KERNEL, ARG0];

    $bot1->yield(register => 'all');
    $bot1->yield(connect => {
        nick    => 'TestBot1',
        server  => '127.0.0.1',
        port    => $port,
    });

    $bot2->yield(register => 'all');
    $bot2->yield(connect => {
        nick    => 'TestBot2',
        server  => '127.0.0.1',
        port    => $port,
    });
}

sub irc_registered {
    my ($irc) = $_[ARG0];
    isa_ok($irc, 'POE::Component::IRC');
}

sub irc_connected {
    pass('Connected');
}

sub irc_001 {
    my ($kernel, $sender, $text) = @_[KERNEL, SENDER, ARG1];
    my $irc = $sender->get_heap();

    pass('Logged in');
    is($irc->server_name(), 'poco.server.irc', 'Server Name Test');
    $irc->yield(join => '#testchannel');
}

sub irc_join {
    my ($sender, $who, $where) = @_[SENDER, ARG0, ARG1];
    my $nick = ( split /!/, $who )[0];
    my $irc = $sender->get_heap();

    if ($nick eq $irc->nick_name()) {
        is($where, '#testchannel', 'Joined Channel Test');
    }
    else {
        $irc->yield(mode => $where => '+o' => $nick);
        $irc->yield(privmsg => $where => 'HELLO');
        $irc->yield('quit');
  }
}

sub irc_mode {
    pass('Mode Test');
}

sub irc_public {
    my ($sender, $who, $where, $what) = @_[SENDER, ARG0..ARG2];
    my $nick = ( split /!/, $who )[0];
    my $irc = $sender->get_heap();

    is($what, 'HELLO', 'irc_public test');
    $irc->yield('quit');
}

sub irc_error {
    pass('irc_error');
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
    $bot1->yield('shutdown');
    $bot2->yield('shutdown');
    $ircd->yield('shutdown');
}
