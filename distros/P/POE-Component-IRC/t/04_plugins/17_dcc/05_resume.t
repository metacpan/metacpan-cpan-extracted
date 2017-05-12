use strict;
use warnings FATAL => 'all';
use lib 't/inc';
use File::Temp qw(tempfile);
use POE;
use POE::Component::IRC;
use POE::Component::Server::IRC;
use Test::Differences;
use Test::More tests => 12;

my ($resume_fh, $resume_file) = tempfile(UNLINK => 1);

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
            irc_disconnected
            irc_dcc_request
            irc_dcc_done
            irc_dcc_start
            irc_dcc_error
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
    $irc->yield(join => '#testchannel');
}

sub irc_join {
    my ($heap, $sender, $who, $where) = @_[HEAP, SENDER, ARG0, ARG1];
    my $nick = ( split /!/, $who )[0];
    my $irc = $sender->get_heap();

    return if $nick ne $irc->nick_name();
    is($where, '#testchannel', 'Joined Channel Test');

    $heap->{joined}++;
    return if $heap->{joined} != 2;
    $bot1->yield(dcc => $bot2->nick_name() => SEND => 'Changes', undef, 5);
}

sub irc_dcc_request {
    my ($sender, $type, $cookie) = @_[SENDER, ARG1, ARG3];
    return if $type ne 'SEND';
    pass('Got dcc request');

    open (my $orig, '<', 'Changes') or die "Can't open Changes file: $!";
    sysread $orig, my $partial, 12000;
    truncate $resume_fh, 12000;
    syswrite $resume_fh, $partial;

    $sender->get_heap()->yield(dcc_resume => $cookie => $resume_file);
}

sub irc_dcc_start {
    pass('DCC started');
}

sub irc_dcc_done {
    my ($sender, $size1, $size2) = @_[SENDER, ARG5, ARG6];
    my $irc = $sender->get_heap();
    return if $irc != $bot2;
    pass('Got dcc done');
    is($size1, $size2, 'Send test results');

    open my $orig, '<', 'Changes' or die $!;
    open my $resume, '<', $resume_file or die $!;
    my $orig_changes = do { local $/; <$orig> };
    my $resume_changes = do { local $/; <$resume> };
    eq_or_diff($resume_changes, $orig_changes, 'File contents match');

    $bot1->yield('quit');
    $bot2->yield('quit');
}

sub irc_dcc_error {
    my ($sender, $error) = @_[SENDER, ARG1];
    my $irc = $sender->get_heap();
    fail('('. $irc->nick_name() .") DCC failed: $error");
    $sender->get_heap()->yield('quit');
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

