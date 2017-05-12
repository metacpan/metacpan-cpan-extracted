use strict;
use warnings FATAL => 'all';
use lib 't/inc';
use POE;
use POE::Component::IRC::Common qw(parse_user);
use POE::Component::IRC::State;
use POE::Component::Server::IRC;
use Test::More 'no_plan';

my $bot = POE::Component::IRC::State->spawn(Flood => 1);
my $ircd = POE::Component::Server::IRC->spawn(
    Auth      => 0,
    AntiFlood => 0,
);

isa_ok($bot, 'POE::Component::IRC::State');

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
            irc_221
            irc_305
            irc_306
            irc_whois
            irc_join
            irc_topic
            irc_chan_sync
            irc_user_mode
            irc_chan_mode
            irc_mode
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

    $bot->yield(register => 'all');
    $bot->yield(connect => {
        nick    => 'TestBot',
        server  => '127.0.0.1',
        port    => $port,
        ircname => 'Test test bot',
    });
}

sub _shutdown {
    my ($kernel, $error) = @_[KERNEL, ARG0];
    fail($error) if defined $error;

    $kernel->alarm_remove_all();
    $ircd->yield('shutdown');
    $bot->yield('shutdown');
}

sub irc_registered {
    my ($irc) = $_[ARG0];
    isa_ok($irc, 'POE::Component::IRC::State');
}

sub irc_connected {
    pass('Connected');
}

sub irc_001 {
    my ($heap, $server) = @_[HEAP, ARG0];
    my $irc = $_[SENDER]->get_heap();
    $heap->{server} = $server;

    pass('Logged in');
    is($irc->server_name(), 'poco.server.irc', 'Server Name Test');
    is($irc->nick_name(), 'TestBot', 'Nick Name Test');

    ok(!$irc->is_operator($irc->nick_name()), 'We are not an IRC op');
    ok(!$irc->is_away($irc->nick_name()), 'We are not away');
    $irc->yield(away => 'Gone for now');

    $irc->yield(whois => 'TestBot');
}

sub irc_305 {
    my $irc = $_[SENDER]->get_heap();
    ok(!$irc->is_away($irc->nick_name()), 'We are back');
}

sub irc_306 {
    my $irc = $_[SENDER]->get_heap();
    ok($irc->is_away($irc->nick_name()), 'We are away now');
    $irc->yield('away');
}

sub irc_whois {
    my ($sender, $whois) = @_[SENDER, ARG0];
    is($whois->{nick}, 'TestBot', 'Whois hash test');
    $sender->get_heap()->yield(join => '#testchannel');
}

sub irc_join {
    my ($sender, $who, $where) = @_[SENDER, ARG0, ARG1];
    my $nick = parse_user($who);
    my $irc = $sender->get_heap();

    is($nick, $irc->nick_name(), 'JOINER Test');
    is($where, '#testchannel', 'Joined Channel Test');
    is($who, $irc->nick_long_form($nick), 'nick_long_form()');

    my $chans = $irc->channels();
    is(keys %$chans, 1, 'Correct number of channels');
    is((keys %$chans)[0], $where, 'Correct channel name');

    my @nicks = $irc->nicks();
    is(@nicks, 1, 'Only one nick known');
    is($nicks[0], $nick, 'Nickname correct');

    $irc->yield(topic => $where, 'Test topic');
}

sub irc_topic {
    my ($sender, $heap, $chan, $topic) = @_[SENDER, HEAP, ARG1, ARG2];
    my $irc = $sender->get_heap();

    $heap->{got_topic}++;

    if ($heap->{got_topic} == 1) {
        my $topic_info = $irc->channel_topic($chan);
        is($topic, $topic_info->{Value}, 'Channel topic set');
        $heap->{topic} = $topic_info;
        $irc->yield(topic => $chan, 'New test topic');
    }
    elsif ($heap->{got_topic} == 2) {
        my $old_topic = $_[ARG3];
        is_deeply($old_topic, $heap->{topic}, 'Got old topic');
    }
}

sub irc_chan_sync {
    my ($sender, $heap, $chan) = @_[SENDER, HEAP, ARG0];
    my $irc = $sender->get_heap();
    my ($nick, $user, $host) = parse_user($irc->nick_long_form($irc->nick_name()));
    my ($occupant) = $irc->channel_list($chan);

    is($occupant, 'TestBot', 'Channel Occupancy Test');
    ok($irc->channel_creation_time($chan), 'Got channel creation time');
    ok(!$irc->channel_limit($chan), 'There is no channel limit');
    ok(!$irc->is_channel_mode_set($chan, 'i'), 'Channel mode i not set yet');
    ok($irc->is_channel_member($chan, $nick), 'Is Channel Member');
    ok($irc->is_channel_operator($chan, $nick), 'Is Channel Operator');
    ok(!$irc->is_channel_halfop($chan, $nick), 'Is not channel halfop');
    ok(!$irc->has_channel_voice($chan, $nick), 'Does not have channel voice');
    ok($irc->ban_mask($chan, $nick), 'Ban Mask Test');

    my @channels = $irc->nick_channels($nick);
    is(@channels, 1, 'Only present in one channel');
    is($channels[0], $chan, 'The channel name matches');

    my $info = $irc->nick_info($nick);
    is($info->{Nick}, $nick, 'nick_info() - Nick');
    is($info->{User}, $user, 'nick_info() - User');
    is($info->{Host}, $host, 'nick_info() - Host');
    is($info->{Userhost}, "$user\@$host", 'nick_info() - Userhost');
    is($info->{Hops}, 0, 'nick_info() - Hops');
    is($info->{Real}, 'Test test bot', 'nick_info() - Realname');
    is($info->{Server}, $heap->{server}, 'nick_info() - Server');
    ok(!$info->{IRCop}, 'nick_info() - IRCop');

    $irc->yield(mode => $chan, '+l 100');
    $heap->{mode_changed} = 1;
}

sub irc_chan_mode {
    my ($sender, $heap, $who, $chan, $mode) = @_[SENDER, HEAP, ARG0..ARG2];
    my $irc = $sender->get_heap();
    return if !$heap->{mode_changed};

    $mode =~ s/\+//g;
    ok($irc->is_channel_mode_set($chan, $mode), "Channel Mode Set: $mode");
    is($irc->channel_limit($chan), 100, 'Channel limit correct');
    $irc->yield('quit');
}

sub irc_user_mode {
    my ($sender, $who, $mode) = @_[SENDER, ARG0, ARG2];
    my $irc = $sender->get_heap();

    $mode =~ s/\+//g;
    ok($irc->is_user_mode_set($mode), "User Mode Set: $mode");
    like($irc->umode(), qr/$mode/, 'Correct user mode in state');
}

sub irc_mode {
    my $irc = $_[SENDER]->get_heap();
    return if $_[ARG1] !~ /^\#/;
}

sub irc_221 {
    my $irc = $_[SENDER]->get_heap();
    pass('State did a MODE query');
    $irc->yield(mode => $irc->nick_name(), '+iw');
}

sub irc_error {
    pass('irc_error');
}

sub irc_disconnected {
    pass('irc_disconnected');
    $poe_kernel->yield('_shutdown');
}
