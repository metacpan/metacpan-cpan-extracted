use strict;
use warnings FATAL => 'all';
use lib 't/inc';
use File::Temp qw(tempdir);
use File::Spec::Functions qw(catfile);
use POE;
use POE::Component::IRC::State;
use POE::Component::IRC::Plugin::Logger;
use POE::Component::Server::IRC;
use Test::More;

my $log_dir = tempdir(CLEANUP => 1);

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

$bot2->plugin_add(Logger => POE::Component::IRC::Plugin::Logger->new(
    Path => $log_dir,
    Notices => 1,
));

my $file = catfile($log_dir, '#testchannel.log');

my @correct = (
    qr/^--> TestBot2 \(\S+@\S+\) joins #testchannel$/,
    '<TestBot1> Oh hi',
    '>TestBot1< Hello',
    '--- TestBot1 disables topic protection',
    '--- TestBot1 enables secret channel status',
    '--- TestBot1 enables channel moderation',
    '--- TestBot1 sets channel keyword to foo',
    '--- TestBot1 removes channel keyword',
    '--- TestBot1 sets channel user limit to 10',
    '--- TestBot1 removes channel user limit',
    '--- TestBot1 sets ban on TestBot2!*@*',
    '--- TestBot1 removes ban on TestBot2!*@*',
    '--- TestBot1 gives channel operator status to TestBot2',
    '--- TestBot1 changes the topic to: Testing, 1 2 3',
    '--- TestBot1 is now known as NewNick',
    qr/^<-- NewNick \(\S+@\S+\) leaves #testchannel \(NewNick\)$/,
    qr/^--> NewNick \(\S+@\S+\) joins #testchannel$/,
    '<-- TestBot2 kicks NewNick from #testchannel (Bye bye)',
    qr/^--> NewNick \(\S+@\S+\) joins #testchannel$/,
    qr/^<-- NewNick \(\S+@\S+\) quits \(.*\)$/,
);

plan tests => 10 + @correct;

POE::Session->create(
    package_states => [
        main => [qw(
            _start
            ircd_listener_add
            ircd_listener_failure
            _shutdown
            irc_001
            irc_join
            irc_part
            irc_kick
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

sub _shutdown {
    my ($kernel, $error) = @_[KERNEL, ARG0];
    fail($error) if defined $error;

    $kernel->alarm_remove_all();
    $ircd->yield('shutdown');
    $bot1->yield('shutdown');
    $bot2->yield('shutdown');
}

sub irc_001 {
    my ($heap, $server) = @_[HEAP, ARG0];
    my $irc = $_[SENDER]->get_heap();

    pass($irc->nick_name() . ' logged in');
    $heap->{logged_in}++;
    if ($heap->{logged_in} == 2) {
        $bot1->yield(join => '#testchannel');
    }
}

sub irc_join {
    my ($sender, $heap, $who, $where) = @_[SENDER, HEAP, ARG0, ARG1];
    my $nick = (split /!/, $who)[0];
    my $irc = $sender->get_heap();

    return if $nick ne $irc->nick_name();
    pass("$nick joined channel");

    $heap->{joined}++;
    if ($heap->{joined} == 1) {
        $bot2->yield(join => $where);
        return;
    }

    if ($heap->{done}) {
        $bot1->yield('quit');
        return;
    }

    if ($irc == $bot2) {
        $bot1->yield(privmsg => $where, 'Oh hi');
        $bot1->yield(notice => $where, 'Hello');
        $bot1->yield(mode => $where, '-t');
        $bot1->yield(mode => $where, '+s');
        $bot1->yield(mode => $where, '+m');
        $bot1->yield(mode => $where, '+k foo');
        $bot1->yield(mode => $where, '-k');
        $bot1->yield(mode => $where, '+l 10');
        $bot1->yield(mode => $where, '-l');
        $bot1->yield(mode => $where, '+b TestBot2!*@*');
        $bot1->yield(mode => $where, '-b TestBot2!*@*');
        $bot1->yield(mode => $where, '+o TestBot2');

        $bot1->yield(topic => $where, 'Testing, 1 2 3');
        $bot1->yield(nick => 'NewNick');
        $bot1->yield(part => $where);
    }
    else {
        $bot2->yield(kick => $where, $bot1->nick_name(), 'Bye bye');
    }
}

sub irc_part {
    my $irc = $_[SENDER]->get_heap();
    my $nick = (split /!/, $_[ARG0])[0];

    if ($nick eq $irc->nick_name()) {
        pass("$nick parted channel");
        $irc->yield(join => $_[ARG1]);
    }
}

sub irc_kick {
    my ($heap, $chan, $nick) = @_[HEAP, ARG1, ARG2];
    my $irc = $_[SENDER]->get_heap();
    return if $nick ne $irc->nick_name();

    pass($nick . ' kicked');
    $irc->yield(join => $chan);
    $heap->{done} = 1;
}

sub irc_disconnected {
    my ($kernel, $sender) = @_[KERNEL, SENDER];
    my $irc = $sender->get_heap();
    pass('irc_disconnected');

    if ($irc == $bot1) {
        $bot2->yield('quit');
    }
    else {
        verify_log();
        $kernel->yield('_shutdown');
    }
}

sub verify_log {
    open my $log, '<', $file or die "Can't open log file '$file': $!";
    my @lines = <$log>;
    close $log;

    my $check = 0;
    for my $line (@lines) {
        next if $line =~ /^\*{3}/;
        chomp $line;
        $line = substr($line, 20);
        last if !defined $correct[$check];

        if (ref $correct[$check] eq 'Regexp') {
            like($line, $correct[$check], 'Line ' . ($check+1));
        }
        else {
            is($line, $correct[$check], 'Line ' . ($check+1));
        }
        $check++;
    }
    fail('Log too short') if $check > @correct;
}
