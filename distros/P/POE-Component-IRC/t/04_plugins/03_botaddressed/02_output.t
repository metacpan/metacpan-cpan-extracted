use strict;
use warnings FATAL => 'all';
use lib 't/inc';
use POE;
use POE::Component::IRC;
use POE::Component::IRC::Plugin::BotAddressed;
use POE::Component::Server::IRC;
use Test::More tests => 10;

my $bot1 = POE::Component::IRC->spawn(
    Flood        => 1,
    plugin_debug => 1,
);
my $bot2 = POE::Component::IRC->spawn(
    Flood        => 1,
    plugin_debug => 1,
);
my $ircd = POE::Component::Server::IRC->spawn(
    Auth      => 0,
    AntiFlood => 0,
);

$bot2->plugin_add(BotAddressed => POE::Component::IRC::Plugin::BotAddressed->new());

POE::Session->create(
    package_states => [
        main => [qw(
            _start
            ircd_listener_add
            ircd_listener_failure
            _shutdown
            irc_001
            irc_disconnected
            irc_join
            irc_bot_addressed
            irc_bot_mentioned
            irc_bot_mentioned_action
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
    pass($irc->nick_name() . ' logged in');
    $irc->yield(join => '#testchannel');
}

sub irc_join {
    my ($sender, $heap, $who, $where) = @_[SENDER, HEAP, ARG0, ARG1];
    my $nick = (split /!/, $who)[0];
    my $irc = $sender->get_heap();

    return if $nick ne $irc->nick_name();
    $heap->{joined}++;
    pass($irc->nick_name() . ' joined channel');
    return if $heap->{joined} != 2;

    $bot1->yield(privmsg => $where, $bot2->nick_name . ': y halo thar');
    $bot1->yield(privmsg => $where, '@' . $bot2->nick_name . ': y halo thar');
    $bot1->yield(privmsg => $where, 'y halo thar, ' . $bot2->nick_name());
    $bot1->yield(ctcp => $where, 'ACTION greets ' . $bot2->nick_name());
}

sub irc_bot_addressed {
    my ($sender, $heap, $msg) = @_[SENDER, HEAP, ARG2];
    my $irc = $sender->get_heap();

    is($msg, 'y halo thar', 'irc_bot_addressed');
}

sub irc_bot_mentioned {
    my ($sender, $heap, $msg) = @_[SENDER, HEAP, ARG2];
    my $irc = $sender->get_heap();

    is($msg, 'y halo thar, ' . $irc->nick_name(), 'irc_bot_mentioned');
}

sub irc_bot_mentioned_action {
    my ($sender, $heap, $msg) = @_[SENDER, HEAP, ARG2];
    my $irc = $sender->get_heap();

    is($msg, 'greets ' . $irc->nick_name(), 'irc_bot_mentioned_action');

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

