use strict;
use warnings FATAL => 'all';
use lib 't/inc';
use POE;
use POE::Component::IRC::State;
use POE::Component::IRC::Plugin::AutoJoin;
use POE::Component::Server::IRC;
use Test::More tests => 16;

my $bot1 = POE::Component::IRC::State->spawn(
    Flood        => 1,
    plugin_debug => 1,
);
my $bot2 = POE::Component::IRC::State->spawn(
    Flood        => 1,
    plugin_debug => 1,
    AwayPoll     => 1,
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
            _shutdown
            irc_001
            irc_366
            irc_join
            irc_nick_sync
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

sub irc_001 {
    my $irc = $_[SENDER]->get_heap();
    pass($irc->nick_name . ' logged in');

    if ($irc == $bot1) {
        $irc->yield(join => '#testchannel');
        $irc->yield(join => '#testchannel2');
    }
}

sub irc_join {
    my ($sender, $heap, $who, $where) = @_[SENDER, HEAP, ARG0, ARG1];
    my $nick = ( split /!/, $who )[0];
    my $irc = $sender->get_heap();

    if ($irc == $bot1 && $nick eq $bot2->nick_name() && !$heap->{seen_bot2}) {
        is($irc->nick_info($bot2->nick_name())->{Server}, undef,
            $bot1->nick_name(). " hasn't synced ".$bot2->nick_name(). " yet");
        $heap->{seen_bot2} = 1;
    }

    return if $nick ne $irc->nick_name();
    pass($irc->nick_name() . " joined channel $where");

    if (keys %{ $bot1->channels } == 2 && !keys %{ $bot2->channels }) {
        $bot2->yield(join => "#testchannel");
    }

    if ($irc == $bot2 && keys %{ $bot2->channels } == 1) {
        is($irc->nick_info($bot1->nick_name()), undef,
            $bot2->nick_name()." doesn't know about ".$bot1->nick_name." yet");
    }
}

sub irc_366 {
    my ($sender, $heap, $args) = @_[SENDER, HEAP, ARG2];
    my $irc = $sender->get_heap();
    my $chan = $args->[0];
    return if $irc != $bot2;
    return if $chan ne '#testchannel';
    my @nicks = $irc->channel_list($chan);
    ok(defined $_, 'Nickname is defined') for @nicks;
}

sub irc_nick_sync {
    my ($sender, $heap, $nick, $chan) = @_[SENDER, HEAP, ARG0, ARG1];
    my $irc = $sender->get_heap();

    if ($irc == $bot1) {
        is($nick, $bot2->nick_name(), 'Nick from irc_nick_sync is correct');

        $heap->{nick_sync}++;
        if ($heap->{nick_sync} == 1) {
            is($chan, '#testchannel', 'Channel from irc_nick_sync is correct');
            $bot2->yield(join => "#testchannel2");
        }
        if ($heap->{nick_sync} == 2) {
            is($chan, '#testchannel2', 'Channel from irc_nick_sync is correct');
            $_->yield('quit') for ($bot1, $bot2);
        }
    }
}

sub irc_disconnected {
    my ($kernel, $heap, $info) = @_[KERNEL, HEAP, ARG1];
    pass($info->{Nick} . ' disconnected');
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

