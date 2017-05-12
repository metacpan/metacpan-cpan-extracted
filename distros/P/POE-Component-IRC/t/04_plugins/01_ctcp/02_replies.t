use strict;
use warnings FATAL => 'all';
use lib 't/inc';
use POE;
use POE::Component::IRC;
use POE::Component::IRC::Plugin::CTCP;
use POE::Component::Server::IRC;
use Test::More tests => 8;

my $bot = POE::Component::IRC->spawn(
    Flood        => 1,
    plugin_debug => 1,
);
my $ircd = POE::Component::Server::IRC->spawn(
    Auth      => 0,
    AntiFlood => 0,
);

$bot->plugin_add(CTCP => POE::Component::IRC::Plugin::CTCP->new(
    version    => 'Test version',
    userinfo   => 'Test userinfo',
    clientinfo => 'Test clientinfo',
    source     => 'Test source',
));

POE::Session->create(
    package_states => [
        main => [qw(
            _start
            ircd_listener_add
            ircd_listener_failure
            _shutdown
            irc_001
            irc_disconnected
            irc_ctcpreply_version
            irc_ctcpreply_userinfo
            irc_ctcpreply_clientinfo
            irc_ctcpreply_source
            irc_ctcpreply_ping
            irc_ctcpreply_time
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

    $bot->yield(register => 'all');
    $bot->yield(connect => {
        nick    => 'TestBot1',
        server  => '127.0.0.1',
        port    => $port,
    });
}

sub irc_001 {
    my $irc = $_[SENDER]->get_heap();
    pass('Logged in');
    $irc->yield(ctcp => $irc->nick_name(), 'VERSION');
    $irc->yield(ctcp => $irc->nick_name(), 'USERINFO');
    $irc->yield(ctcp => $irc->nick_name(), 'CLIENTINFO');
    $irc->yield(ctcp => $irc->nick_name(), 'SOURCE');
    $irc->yield(ctcp => $irc->nick_name(), 'PING test');
    $irc->yield(ctcp => $irc->nick_name(), 'TIME');
}

sub irc_ctcpreply_version {
    my ($sender, $heap, $msg) = @_[SENDER, HEAP, ARG2];
    $heap->{replies}++;
    is($msg, 'Test version', 'CTCP VERSION reply');
    $sender->get_heap()->yield('quit') if $heap->{replies} == 6;
}

sub irc_ctcpreply_userinfo {
    my ($sender, $heap, $msg) = @_[SENDER, HEAP, ARG2];
    $heap->{replies}++;
    is($msg, 'Test userinfo', 'CTCP USERINFO reply');
    $sender->get_heap()->yield('quit') if $heap->{replies} == 6;
}

sub irc_ctcpreply_clientinfo {
    my ($sender, $heap, $msg) = @_[SENDER, HEAP, ARG2];
    $heap->{replies}++;
    is($msg, 'Test clientinfo', 'CTCP CLIENTINFO reply');
    $sender->get_heap()->yield('quit') if $heap->{replies} == 6;
}

sub irc_ctcpreply_source {
    my ($sender, $heap, $msg) = @_[SENDER, HEAP, ARG2];
    $heap->{replies}++;
    is($msg, 'Test source', 'CTCP SOURCE reply');
    $sender->get_heap()->yield('quit') if $heap->{replies} == 6;
}

sub irc_ctcpreply_ping {
    my ($sender, $heap, $msg) = @_[SENDER, HEAP, ARG2];
    $heap->{replies}++;
    is($msg, 'test', 'CTCP PING reply');
    $sender->get_heap()->yield('quit') if $heap->{replies} == 6;
}

sub irc_ctcpreply_time {
    my ($sender, $heap, $msg) = @_[SENDER, HEAP, ARG2];
    $heap->{replies}++;
    ok(length $msg, 'CTCP TIME reply');
    $sender->get_heap()->yield('quit') if $heap->{replies} == 6;
}

sub irc_disconnected {
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    pass('irc_disconnected');
    $kernel->yield('_shutdown');
}

sub _shutdown {
    my ($kernel, $error) = @_[KERNEL, ARG0];
    fail($error) if defined $error;

    $kernel->alarm_remove_all();
    $ircd->yield('shutdown');
    $bot->yield('shutdown');
}

