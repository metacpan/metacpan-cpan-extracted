#!perl

use strict;
use warnings;

BEGIN { *CORE::GLOBAL::sleep = sub { }; }

use Test::More;
use Net::Jabber::Bot;

use FindBin;
use lib "$FindBin::Bin/lib";
use MockJabberClient;

my $bot_alias = 'make_test_bot';
my $server    = 'talk.google.com';

my %forums_and_responses;
$forums_and_responses{'test_forum1'} = [ "jbot:", "" ];

my $bot = Net::Jabber::Bot->new(
    server                  => $server,
    conference_server       => "conference.$server",
    port                    => 5222,
    username                => 'test_username',
    password                => 'test_pass',
    alias                   => $bot_alias,
    message_function        => sub { },
    background_function     => sub { },
    loop_sleep_time         => 5,
    process_timeout         => 5,
    forums_and_responses    => \%forums_and_responses,
    ignore_server_messages  => 1,
    ignore_self_messages    => 1,
    out_messages_per_second => 5,
    max_message_size        => 1000,
    max_messages_per_hour   => 100,
    forum_join_grace        => 0,
);

isa_ok( $bot, "Net::Jabber::Bot" );
ok( $bot->IsConnected(), "Bot starts connected" );

# ─── AddUser ───────────────────────────────────────────────

subtest 'AddUser when connected' => sub {
    my $client = $bot->jabber_client;
    @{$client->{subscription_log}} = ();    # Reset log

    $bot->AddUser("friend\@$server");

    my @subs = @{$client->{subscription_log}};
    is( scalar @subs, 2, "AddUser sends 2 subscription stanzas" );
    is( $subs[0]{type}, 'subscribe',  "First stanza is subscribe request" );
    is( $subs[0]{to},   "friend\@$server", "Subscribe targets correct JID" );
    is( $subs[1]{type}, 'subscribed', "Second stanza is subscribed approval" );
    is( $subs[1]{to},   "friend\@$server", "Subscribed targets correct JID" );
};

subtest 'AddUser when disconnected' => sub {
    $bot->Disconnect();
    ok( !$bot->IsConnected(), "Bot is disconnected" );

    # Should not crash
    my $result = eval { $bot->AddUser("someone\@$server") };
    ok( !$@, "AddUser does not crash when disconnected" )
        or diag("AddUser died: $@");
};

# Reconnect for remaining tests
$bot->ReconnectToServer();
ok( $bot->IsConnected(), "Bot reconnected after AddUser disconnect test" );

# ─── RmUser ────────────────────────────────────────────────

subtest 'RmUser when connected' => sub {
    my $client = $bot->jabber_client;
    @{$client->{subscription_log}} = ();    # Reset log

    $bot->RmUser("enemy\@$server");

    my @subs = @{$client->{subscription_log}};
    is( scalar @subs, 2, "RmUser sends 2 subscription stanzas" );
    is( $subs[0]{type}, 'unsubscribe',  "First stanza is unsubscribe" );
    is( $subs[0]{to},   "enemy\@$server", "Unsubscribe targets correct JID" );
    is( $subs[1]{type}, 'unsubscribed', "Second stanza is unsubscribed" );
    is( $subs[1]{to},   "enemy\@$server", "Unsubscribed targets correct JID" );
};

subtest 'RmUser when disconnected' => sub {
    $bot->Disconnect();

    my $result = eval { $bot->RmUser("someone\@$server") };
    ok( !$@, "RmUser does not crash when disconnected" )
        or diag("RmUser died: $@");
};

$bot->ReconnectToServer();
ok( $bot->IsConnected(), "Bot reconnected after RmUser disconnect test" );

# ─── JoinForum (direct call) ──────────────────────────────

subtest 'JoinForum direct call' => sub {
    my $client = $bot->jabber_client;
    @{$client->{muc_join_log}} = ();    # Reset

    $bot->JoinForum('new_room');

    my @joins = @{$client->{muc_join_log}};
    is( scalar @joins, 1, "JoinForum sends one MUCJoin" );
    is( $joins[0]{room},   'new_room',                    "MUCJoin room is correct" );
    is( $joins[0]{server}, "conference.$server",           "MUCJoin server is correct" );
    is( $joins[0]{nick},   $bot_alias,                     "MUCJoin nick is bot alias" );

    ok( exists $bot->forum_join_time->{'new_room'}, "forum_join_time recorded" );
    ok( $bot->forum_join_time->{'new_room'} > 0,    "forum_join_time is positive timestamp" );
};

subtest 'JoinForum when disconnected' => sub {
    $bot->Disconnect();

    my $result = eval { $bot->JoinForum('some_room') };
    ok( !$@, "JoinForum does not crash when disconnected" )
        or diag("JoinForum died: $@");
};

$bot->ReconnectToServer();

# ─── ChangeStatus (connected) ─────────────────────────────

subtest 'ChangeStatus when connected' => sub {
    my $client = $bot->jabber_client;
    @{$client->{presence_send_log}} = ();

    my $result = $bot->ChangeStatus("away", "brb");
    is( $result, 1, "ChangeStatus returns 1 on success" );

    my @sends = @{$client->{presence_send_log}};
    # The init also does PresenceSend, so filter by our call
    # Actually the log was reset, so we only see our call
    ok( scalar @sends >= 1, "PresenceSend was called" );
    is( $sends[-1]{show},   'away', "Presence show is correct" );
    is( $sends[-1]{status}, 'brb',  "Presence status is correct" );
};

subtest 'ChangeStatus with no status string' => sub {
    my $client = $bot->jabber_client;
    @{$client->{presence_send_log}} = ();

    my $result = $bot->ChangeStatus("chat");
    is( $result, 1, "ChangeStatus returns 1 with mode only" );

    my @sends = @{$client->{presence_send_log}};
    is( $sends[-1]{show}, 'chat', "Presence show is 'chat'" );
};

# ─── GetRoster (with data) ────────────────────────────────

{
    # Create mock JID objects for the roster
    package MockJID;
    sub new {
        my ($class, $jid) = @_;
        return bless { jid => $jid }, $class;
    }
    sub GetJID { return $_[0]->{jid} }
}

subtest 'GetRoster with users' => sub {
    my $client = $bot->jabber_client;

    # Populate roster
    my @jids = (
        MockJID->new("alice\@$server"),
        MockJID->new("bob\@$server"),
        MockJID->new("carol\@$server"),
    );
    $client->{roster_jids} = \@jids;

    my @roster = $bot->GetRoster();
    is( scalar @roster, 3, "GetRoster returns 3 users" );
    is( $roster[0], "alice\@$server", "First roster entry correct" );
    is( $roster[1], "bob\@$server",   "Second roster entry correct" );
    is( $roster[2], "carol\@$server", "Third roster entry correct" );
};

subtest 'GetRoster with empty roster' => sub {
    my $client = $bot->jabber_client;
    $client->{roster_jids} = [];

    my @roster = $bot->GetRoster();
    is( scalar @roster, 0, "GetRoster returns empty list for empty roster" );
};

# ─── GetStatus (with presence data) ───────────────────────

subtest 'GetStatus for user with show value' => sub {
    my $client = $bot->jabber_client;

    # Create a presence entry in the mock DB
    my $presence = Net::Jabber::Presence->new();
    $presence->SetFrom("alice\@$server");
    $presence->SetShow("away");

    $client->{presence_db}{"alice\@$server"} = $presence;

    my $status = $bot->GetStatus("alice\@$server");
    is( $status, 'away', "GetStatus returns show value for present user" );
};

subtest 'GetStatus for available user (no show)' => sub {
    my $client = $bot->jabber_client;

    my $presence = Net::Jabber::Presence->new();
    $presence->SetFrom("bob\@$server");
    # No SetShow — user is just "available"

    $client->{presence_db}{"bob\@$server"} = $presence;

    my $status = $bot->GetStatus("bob\@$server");
    is( $status, 'available', "GetStatus returns 'available' when no show value" );
};

subtest 'GetStatus for unknown user' => sub {
    my $status = $bot->GetStatus("unknown\@$server");
    is( $status, 'unavailable', "GetStatus returns 'unavailable' for unknown JID" );
};

subtest 'GetStatus various show values' => sub {
    my $client = $bot->jabber_client;

    for my $show_val (qw(chat xa dnd)) {
        my $presence = Net::Jabber::Presence->new();
        $presence->SetFrom("user_$show_val\@$server");
        $presence->SetShow($show_val);

        $client->{presence_db}{"user_$show_val\@$server"} = $presence;

        my $status = $bot->GetStatus("user_$show_val\@$server");
        is( $status, $show_val, "GetStatus returns '$show_val' correctly" );
    }
};

# ─── SetForumSubject (happy path) ─────────────────────────

subtest 'SetForumSubject successful' => sub {
    my $client = $bot->jabber_client;
    @{$client->{message_queue}} = ();    # Clear queue

    my $result = $bot->SetForumSubject("test_forum1\@conference.$server", "New Topic");
    ok( !defined $result, "SetForumSubject returns undef on success" );
};

subtest 'SetForumSubject too long' => sub {
    my $long_subject = 'x' x 1500;
    my $result = $bot->SetForumSubject("test_forum1\@conference.$server", $long_subject);
    is( $result, "Subject is too long!", "SetForumSubject rejects oversized subject" );
};

subtest 'SetForumSubject at boundary' => sub {
    my $exact_subject = 'y' x 1000;
    my $result = $bot->SetForumSubject("test_forum1\@conference.$server", $exact_subject);
    ok( !defined $result, "SetForumSubject accepts subject at exactly max_message_size" );
};

# ─── get_responses ─────────────────────────────────────────

subtest 'get_responses for known forum' => sub {
    my @resp = $bot->get_responses('test_forum1');
    is( scalar @resp, 2,      "test_forum1 has 2 response patterns" );
    is( $resp[0],     'jbot:', "First pattern is 'jbot:'" );
    is( $resp[1],     '',      "Second pattern is empty (respond to all)" );
};

subtest 'get_responses for unknown forum' => sub {
    my @resp = $bot->get_responses('nonexistent_forum');
    is( scalar @resp, 0, "Unknown forum returns empty response list" );
};

subtest 'get_responses with undef' => sub {
    my @resp = $bot->get_responses(undef);
    is( scalar @resp, 0, "undef forum returns empty response list" );
};

# ─── respond_to_self_messages ──────────────────────────────

subtest 'respond_to_self_messages toggling' => sub {
    # Safety mode is on, so ignore_self_messages was forced to 1
    ok( $bot->ignore_self_messages, "ignore_self_messages starts on (safety mode)" );

    $bot->respond_to_self_messages(1);
    ok( !$bot->ignore_self_messages, "respond_to_self_messages(1) disables ignore" );

    $bot->respond_to_self_messages(0);
    ok( $bot->ignore_self_messages, "respond_to_self_messages(0) enables ignore" );

    # Default argument
    $bot->respond_to_self_messages();
    ok( !$bot->ignore_self_messages, "respond_to_self_messages() defaults to 1" );

    # Restore
    $bot->ignore_self_messages(1);
};

# ─── get_messages_this_hour ────────────────────────────────

subtest 'get_messages_this_hour tracking' => sub {
    # The bot has been sending messages in SetForumSubject tests,
    # so the count should be > 0
    my $count = $bot->get_messages_this_hour();
    ok( $count >= 0, "get_messages_this_hour returns a non-negative number" );

    # Send a known number and verify increment
    my $before = $bot->get_messages_this_hour();
    $bot->SendPersonalMessage("test_user\@$server/resource", "counting test");
    my $after = $bot->get_messages_this_hour();
    is( $after, $before + 1, "Message count increments by 1 after sending" );
};

# ─── get_safety_mode ───────────────────────────────────────

subtest 'get_safety_mode reports correctly' => sub {
    ok( $bot->get_safety_mode(), "get_safety_mode returns true when safety is on" );
};

# ─── from_full attribute ──────────────────────────────────

subtest 'from_full uses resource not alias' => sub {
    # resource defaults to alias_hostname_pid, which differs from alias
    my $from = $bot->from_full;
    my $expected = $bot->username . '@' . $bot->server . '/' . $bot->resource;
    is( $from, $expected, "from_full matches username\@server/resource" );

    # Verify it uses resource (which includes hostname/pid) not bare alias
    like( $from, qr/\Q$bot_alias\E_/, "from_full resource starts with alias but includes more" );
    unlike( $from, qr/\/$bot_alias$/, "from_full does not end with bare alias" );
};

done_testing();
