use strict;
use warnings FATAL => 'all';
use lib 't/inc';
use POE::Component::IRC;
use POE::Component::Server::IRC;
use POE;
use Test::More tests => 16;

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
            _shutdown
            ircd_listener_add
            ircd_listener_failure
            irc_001
            irc_join
            irc_invite
            irc_mode
            irc_public
            irc_notice
            irc_ctcp_action
            irc_nick
            irc_topic
            irc_kick
            irc_msg
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
    pass('Logged in');

    $_[HEAP]->{logged_in}++;
    if ($_[HEAP]->{logged_in} == 2) {
        $bot1->yield(join => '#testchannel');
    }
}

sub irc_join {
    my ($sender, $who, $where) = @_[SENDER, ARG0, ARG1];
    my $nick = ( split /!/, $who )[0];
    my $irc = $sender->get_heap();

    if ($nick eq $irc->nick_name()) {
        is($where, '#testchannel', 'Joined Channel Test');

        if ($irc == $bot1) {
            $bot1->yield(invite => $bot2->nick_name(), $where);
        }
        else {
            $bot1->yield(mode => $where, '+m');
        }
    }
}

sub irc_invite {
    pass('irc_invite');
    $_[SENDER]->get_heap()->yield(join => $_[ARG1]);
}

sub irc_mode {
    my ($sender, $where, $mode) = @_[SENDER, ARG1, ARG2];
    my $irc = $sender->get_heap();
    my $chantypes = join('', @{ $irc->isupport('CHANTYPES') || ['#', '&']});
    return if $where !~ /^[$chantypes]/;
    return if $irc != $bot1;

    if ($mode =~ /\+[nt]/) {
        pass('Got initial channel modes');
    }
    else {
        is($mode, '+m', 'irc_mode');
        $bot1->yield(privmsg => $where, 'Test message 1');
    }
}

sub irc_public {
    my ($sender, $where, $msg) = @_[SENDER, ARG1, ARG2];
    my $irc = $sender->get_heap();
    return if $irc != $bot2;

    is($msg, 'Test message 1', 'irc_public');
    $bot1->yield(notice => $where->[0], 'Test message 2');
}

sub irc_notice {
    my ($sender, $where, $msg) = @_[SENDER, ARG1, ARG2];
    my $irc = $sender->get_heap();
    return if $irc != $bot2;

    is($msg, 'Test message 2', 'irc_notice');
    $bot1->yield(ctcp => $where->[0], 'ACTION Test message 3');
}

sub irc_ctcp_action {
    my ($sender, $where, $msg) = @_[SENDER, ARG1, ARG2];
    my $irc = $sender->get_heap();
    return if $irc != $bot2;

    is($msg, 'Test message 3', 'irc_ctcp_action');
    $bot1->yield(topic => $where->[0], 'Test topic');
}

sub irc_topic {
    my ($sender, $chan, $msg) = @_[SENDER, ARG1, ARG2];
    my $irc = $sender->get_heap();
    return if $irc != $bot2;

    is($msg, 'Test topic', 'irc_topic');
    $bot1->yield(nick => 'NewNick');
}

sub irc_nick {
    my $irc = $_[SENDER]->get_heap();
    return if $irc != $bot2;
    pass('irc_nick');
    $bot1->yield(kick => '#testchannel', $bot2->nick_name(), 'Good bye');
}

sub irc_kick {
    my ($sender, $error) = @_[SENDER, ARG3];
    my $irc = $sender->get_heap();
    return if $irc != $bot2;

    is($error, 'Good bye', 'irc_kick');
    $bot1->yield(privmsg => $bot2->nick_name(), 'Test message 4');
}

sub irc_msg {
    my ($sender, $msg) = @_[SENDER, ARG2];
    my $irc = $sender->get_heap();
    return if $irc != $bot2;

    is($msg, 'Test message 4', 'irc_msg');
    $bot1->yield('quit');
    $bot2->yield('quit');
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

