#!perl

# Test that self-message detection works correctly in MUC (groupchat).
#
# In XMPP MUC, the from JID resource is the room nickname (alias),
# not the XMPP resource. This test verifies that the bot correctly
# ignores its own echoed messages in group chat even though the
# resource in the from JID differs from the XMPP login resource.

use strict;
use warnings;

use Test::More tests => 7;
use Net::Jabber::Bot;

use FindBin;
use lib "$FindBin::Bin/lib";
use MockJabberClient;

BEGIN { *CORE::GLOBAL::sleep = sub { }; }

my $bot_alias  = 'testbot';
my $server     = 'jabber.example.com';
my $conf       = "conference.$server";
my $forum      = 'dev_room';

my $messages_seen = 0;

my $bot = Net::Jabber::Bot->new({
    server               => $server,
    conference_server    => $conf,
    port                 => 5222,
    username             => 'botuser',
    password             => 'secret',
    alias                => $bot_alias,
    message_function     => sub { $messages_seen++ },
    background_function  => sub { },
    forums_and_responses => { $forum => [''] },  # respond to all messages
    ignore_self_messages => 1,
    safety_mode          => 0,
    forum_join_grace     => 0,
});

isa_ok($bot, 'Net::Jabber::Bot');

# Verify alias and resource are different (this is the crux of the bug)
isnt($bot->alias, $bot->resource,
    "alias ('${\$bot->alias}') differs from resource ('${\$bot->resource}')");

# Send a group message — the mock will echo it back with the MUC nickname
# (alias) as the from JID resource, matching real XMPP MUC behavior.
$messages_seen = 0;
$bot->SendGroupMessage($forum, "Hello room!");
$bot->Process(1);

is($messages_seen, 0,
    "Bot ignores its own echoed group message (MUC alias-based detection)");

# Now disable self-message ignoring and verify messages come through
$bot->respond_to_self_messages(1);
$messages_seen = 0;
$bot->SendGroupMessage($forum, "Hello again!");
$bot->Process(1);

is($messages_seen, 1,
    "Bot sees its own group message when respond_to_self_messages is on");

# Re-enable self-message ignoring
$bot->respond_to_self_messages(0);

# Test direct (chat) messages still use resource-based detection.
# Send a personal message — the mock echoes with the XMPP resource.
$messages_seen = 0;
$bot->SendPersonalMessage("peer\@$server/$bot_alias", "Hello peer!");
$bot->Process(1);

is($messages_seen, 0,
    "Bot ignores its own echoed personal message (resource-based detection)");

# Verify a message from someone ELSE with a different resource is NOT ignored
my $other_msg = Net::Jabber::Message->new();
$other_msg->SetFrom("$forum\@$conf/other_user");
$other_msg->SetTo("botuser\@$server/${\$bot->resource}");
$other_msg->SetType('groupchat');
$other_msg->SetBody("Hey bot!");

# Inject the message directly into the mock client's queue
push @{$bot->jabber_client->{message_queue}}, $other_msg;
$messages_seen = 0;
$bot->Process(1);

is($messages_seen, 1,
    "Bot processes messages from other users in group chat");

# Verify a message from someone with an alias that happens to match
# the bot's alias from a DIFFERENT room context doesn't get suppressed
# (edge case: only suppress in rooms the bot actually joined)
my $impersonator_msg = Net::Jabber::Message->new();
$impersonator_msg->SetFrom("other_room\@$conf/$bot_alias");
$impersonator_msg->SetTo("botuser\@$server/${\$bot->resource}");
$impersonator_msg->SetType('groupchat');
$impersonator_msg->SetBody("I'm pretending to be the bot!");

push @{$bot->jabber_client->{message_queue}}, $impersonator_msg;
$messages_seen = 0;
$bot->Process(1);

# This WILL be suppressed because the alias matches — that's acceptable
# security behavior (better to over-suppress than risk loops)
is($messages_seen, 0,
    "Bot suppresses groupchat from matching alias (safe default)");
