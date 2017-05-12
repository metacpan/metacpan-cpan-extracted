use strict;
use warnings FATAL => 'all';
use lib 't/inc';
use POE;
use POE::Component::IRC::State;
use POE::Component::IRC::Plugin::AutoJoin;
use POE::Component::Server::IRC;
use Test::More tests => 17;

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
    Channels          => { '#testchannel' => 'secret' },
    RejoinOnKick      => 1,
    Rejoin_delay      => 1,
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
            irc_kick
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
    $heap->{port} = $port;

    $bot1->yield(register => 'all');
    $bot1->yield(connect => {
        nick    => 'TestBot1',
        server  => '127.0.0.1',
        port    => $port,
    });

}

sub irc_001 {
    my $irc = $_[SENDER]->get_heap();
    pass($irc->nick_name() . ' logged in');

    if ($irc == $bot1) {
        $irc->yield(join => '#testchannel');
        $irc->yield(join => '#testchannel2');
    }
}

sub irc_join {
    my ($sender, $heap, $who, $where) = @_[SENDER, HEAP, ARG0, ARG1];
    my $nick = ( split /!/, $who )[0];
    my $irc = $sender->get_heap();
    return if $nick ne $irc->nick_name();

    like($where, qr/#testchannel2?/, "$nick joined $where");

    if ($nick eq 'TestBot1') {
        if ($where eq '#testchannel') {
            $bot1->yield(mode => $where, '+k secret');
        }
        else {
            $bot1->yield(mode => $where, '+k secret2');
        }
    }
    elsif ($where eq '#testchannel') {
        $heap->{bot2_joined}++;
        if ($heap->{bot2_joined} == 1) {
            $bot1->yield(mode => $where, '+k topsecret');
        }
        else {
            $bot2->yield(join => '#testchannel2', 'secret2');
        }
    }
    else {
        $heap->{bot2_joined_2}++;
        if ($heap->{bot2_joined_2} == 1) {
            $bot1->yield(kick => $where, 'TestBot2');
        }
        else {
            $bot1->yield('quit');
            $bot2->yield('quit');
        }
    }
}

sub irc_chan_mode {
    my ($heap, $where, $mode) = @_[HEAP, ARG1, ARG2];
    return if $bot1 != $_[SENDER]->get_heap();

    if ($mode eq '+k') {
        pass("$where key set");
        $heap->{key_set}++;

        if ($heap->{key_set} == 2) {
            $bot2->yield(register => 'all');
            $bot2->yield(connect => {
                nick    => 'TestBot2',
                server  => '127.0.0.1',
                port    => $heap->{port},
            });
        }
        elsif ($heap->{key_set} == 3) {
            $bot1->yield(mode => $where, '+b TestBot2!*@*');
            $bot1->yield(kick => $where, 'TestBot2');
        }
    }
    elsif ($mode eq '+b') {
        pass('Ban set');
    }
    elsif ($mode eq '-b') {
        pass('Ban removed');
    }
}

sub irc_kick {
    my ($sender, $where, $victim) = @_[SENDER, ARG1, ARG2];
    my $irc = $sender->get_heap();
    return if $victim ne $irc->nick_name();
    pass("$victim kicked from $where");
    $bot1->delay([mode => $where, '-b TestBot2!*@*'], 4);
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

