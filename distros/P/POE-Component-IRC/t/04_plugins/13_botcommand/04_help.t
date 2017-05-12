use strict;
use warnings FATAL => 'all';
use lib 't/inc';
use POE;
use POE::Component::IRC;
use POE::Component::IRC::Plugin::BotCommand;
use POE::Component::Server::IRC;
use Test::More tests => 25;

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

POE::Session->create(
    package_states => [
        main => [qw(
            _start
            ircd_listener_add
            ircd_listener_failure
            _shutdown
            irc_001
            irc_join
            irc_notice
            irc_disconnected
        )],
    ],
);

my @bar_help = (
    "Syntax: TestBot1: bar arg1 arg2 ...",
    "Description: Test command2",
    "Arguments:",
    "    arg1: What to bar (table|chair)",
    "    arg2: Where to bar"
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

sub _shutdown {
    my ($kernel, $error) = @_[KERNEL, ARG0];
    fail($error) if defined $error;

    $kernel->alarm_remove_all();
    $ircd->yield('shutdown');
    $bot1->yield('shutdown');
    $bot2->yield('shutdown');
}

sub irc_001 {
    my $irc = $_[SENDER]->get_heap();

    pass('Logged in');
    $irc->yield(join => '#testchannel');
    return if $irc != $bot1;

    my $plugin = POE::Component::IRC::Plugin::BotCommand->new();
    ok($irc->plugin_add(BotCommand => $plugin), 'Add plugin with no commands');
}

sub irc_join {
    my ($heap, $sender, $who, $where) = @_[HEAP, SENDER, ARG0, ARG1];
    my $nick = (split /!/, $who)[0];
    my $irc = $sender->get_heap();

    return if $nick ne $irc->nick_name();
    pass('Joined channel');
    $heap->{joined}++;
    return if $heap->{joined} != 2;

    $bot2->yield(privmsg => $where, "TestBot1: help");
    $bot2->yield(privmsg => $where, "TestBot1: help foo");
}

sub irc_notice {
    my ($sender, $heap, $who, $where, $what) = @_[SENDER, HEAP, ARG0..ARG2];
    my $irc = $sender->get_heap();
    my $nick = (split /!/, $who)[0];

    return if $irc != $bot2;

    $heap->{replies}++;
    ## no critic (ControlStructures::ProhibitCascadingIfElse)
    if ($heap->{replies} == 1) {
        is($nick, $bot1->nick_name(), 'Bot nickname');
        like($what, qr/^No commands/, 'Bot reply');
    }
    elsif ($heap->{replies} == 2) {
        is($nick, $bot1->nick_name(), 'Bot nickname');
        like($what, qr/^Unknown command:/, 'Bot reply');
        my ($p) = grep { $_->isa('POE::Component::IRC::Plugin::BotCommand') } values %{ $bot1->plugin_list() };
        ok($p->add(foo => 'Test command'), 'Add command foo');
        ok($p->add(bar => {
                    info => 'Test command2',
                    args => [qw(arg1 arg2)],
                    arg1 => ['What to bar', qw(table chair)],
                    arg2 => 'Where to bar',
                    variable => 1,
        }), 'Add command bar');
        $irc->yield(privmsg => $where, "TestBot1: help");
        $irc->yield(privmsg => $where, "TestBot1: help bar");
    }
    elsif ($heap->{replies} == 4) {
        is($nick, $bot1->nick_name(), 'Bot nickname');
        like($what, qr/^Commands: bar, foo/, 'Bot reply');
    }
    elsif ($heap->{replies} >= 6 && $heap->{replies} <= 11) {
        is($nick, $bot1->nick_name(), 'Bot nickname');
        is($what, shift @bar_help, 'Command with args help');

        $bot1->yield('quit');
        $bot2->yield('quit');
    }
}

sub irc_disconnected {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    pass('irc_disconnected');
    $heap->{count}++;
    $poe_kernel->yield('_shutdown') if $heap->{count} == 2;
}
