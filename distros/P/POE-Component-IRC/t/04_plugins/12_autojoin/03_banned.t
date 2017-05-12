use strict;
use warnings FATAL => 'all';
use lib 't/inc';
use POE;
use POE::Component::IRC::State;
use POE::Component::IRC::Plugin::AutoJoin;
use POE::Component::Server::IRC;
use Test::More tests => 9;

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

$bot2->plugin_add(AutoJoin => POE::Component::IRC::Plugin::AutoJoin->new(
    Retry_when_banned => 1,
));

POE::Session->create(
    package_states => [
        main => [qw(
            _start
            ircd_listener_add
            ircd_listener_failure
            _shutdown
            irc_001
            irc_join
            irc_disconnected
            irc_chan_mode
            irc_474
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

sub irc_001 {
    my $irc = $_[SENDER]->get_heap();
    pass($irc->nick_name.' logged in');

    if ($irc == $bot1) {
        $irc->yield(join => '#testchannel');
    }
}

sub irc_join {
    my ($sender, $who, $where) = @_[SENDER, ARG0, ARG1];
    my $nick = ( split /!/, $who )[0];
    my $irc = $sender->get_heap();

    return if $nick ne $irc->nick_name();
    is($where, '#testchannel', $irc->nick_name. ' joined channel');

    if ($nick eq 'TestBot1') {
        $irc->yield(mode => $where, '+b TestBot2!*@*');
    }
    else {
        $bot1->yield('quit');
        $bot2->yield('quit');
    }
}

sub irc_chan_mode {
    my ($chan, $mode) = @_[ARG1, ARG2];

    if ($mode eq '+b') {
        pass('Ban set');
        $bot2->yield(join => $chan);
    }
    elsif ($mode eq '-b') {
        pass('Ban removed');
    }
}

sub irc_474 {
    my ($chan) = $_[ARG2]->[0];

    if (!$_[HEAP]->{denied}) {
        pass("Can't join due to ban");
        $bot1->yield(mode => $chan, '-b TestBot2!*@*');
        $_[HEAP]->{denied} = 1;
    }
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
