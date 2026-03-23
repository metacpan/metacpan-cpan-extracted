#!perl

use strict;
use warnings;
use Test::More tests => 5;
use Net::Jabber::Bot;

use FindBin;
use lib "$FindBin::Bin/lib";
use MockJabberClient;

my $bot_alias = 'grace_test_bot';
my $server    = 'talk.google.com';

my %forums_and_responses;
my $forum1 = 'test_forum1';
$forums_and_responses{$forum1} = ["jbot:", ""];

my $messages_seen = 0;

# Use a short but nonzero grace period so the test runs fast
my $bot = Net::Jabber::Bot->new({
    server               => $server,
    conference_server     => "conference.$server",
    port                 => 5222,
    username             => 'test_username',
    password             => 'test_pass',
    alias                => $bot_alias,
    message_function     => sub { $messages_seen++ },
    background_function  => sub {},
    loop_sleep_time      => 5,
    process_timeout      => 5,
    forums_and_responses => \%forums_and_responses,
    ignore_server_messages  => 1,
    ignore_self_messages    => 0,
    out_messages_per_second => 5,
    max_message_size        => 800,
    max_messages_per_hour   => 100,
    forum_join_grace        => 2,
});

isa_ok($bot, "Net::Jabber::Bot");
is($bot->forum_join_grace, 2, "Forum join grace set to 2 seconds");

# Enable responding to self messages (safety_mode forces ignore_self_messages on,
# and the mock echoes messages back with the same resource as the bot)
$bot->respond_to_self_messages(1);

# Send a message immediately — should be ignored (within grace period)
my $personal_address = "test_user\@$server/$bot_alias";
$bot->SendPersonalMessage($personal_address, "Hello during grace period");
$bot->Process(1);
is($messages_seen, 0, "Message during grace period is ignored");

# Wait past the grace period
sleep 3;

# Send another message — should be processed now
$messages_seen = 0;
$bot->SendPersonalMessage($personal_address, "Hello after grace period");
$bot->Process(1);
is($messages_seen, 1, "Message after grace period is processed");

# Test that forum_join_grace => 0 means no grace period at all
my $bot2 = Net::Jabber::Bot->new({
    server               => $server,
    conference_server     => "conference.$server",
    port                 => 5222,
    username             => 'test_username2',
    password             => 'test_pass',
    alias                => $bot_alias,
    message_function     => sub { $messages_seen++ },
    background_function  => sub {},
    loop_sleep_time      => 5,
    process_timeout      => 5,
    forums_and_responses => \%forums_and_responses,
    ignore_server_messages  => 1,
    ignore_self_messages    => 0,
    out_messages_per_second => 5,
    max_message_size        => 800,
    max_messages_per_hour   => 100,
    forum_join_grace        => 0,
});

$bot2->respond_to_self_messages(1);
$messages_seen = 0;
$bot2->SendPersonalMessage($personal_address, "Immediate message with zero grace");
$bot2->Process(1);
is($messages_seen, 1, "Message processed immediately when forum_join_grace is 0");
