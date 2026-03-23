#!perl

use strict;
use warnings;
use Test::More tests => 13;
use Net::Jabber::Bot;

# stuff for mock client object
use FindBin;
use lib "$FindBin::Bin/lib";
use MockJabberClient;    # Test object

my $bot_alias = 'reconnect_test_bot';
my $server    = 'talk.google.com';

my %forums_and_responses;
$forums_and_responses{'test_forum1'} = [ "jbot:", "" ];

my $bot = Net::Jabber::Bot->new(
    server               => $server,
    conference_server     => "conference.$server",
    port                 => 5222,
    username             => 'test_username',
    password             => 'test_pass',
    alias                => $bot_alias,
    message_function     => sub { },
    background_function  => sub { },
    loop_sleep_time      => 5,
    process_timeout      => 5,
    forums_and_responses => \%forums_and_responses,
    out_messages_per_second => 5,
    max_message_size       => 800,
    max_messages_per_hour  => 100,
    forum_join_grace       => 0,
);

isa_ok( $bot, "Net::Jabber::Bot" );

# Test 1: IsConnected returns true when connected
ok( $bot->IsConnected(), "Bot reports connected after init" );
ok( defined $bot->jabber_client, "jabber_client is defined when connected" );

# Test 2: IsConnected returns false after Disconnect
$bot->Disconnect();
ok( !$bot->IsConnected(), "Bot reports NOT connected after Disconnect" );

# Test 3: ReconnectToServer successfully reconnects
eval { $bot->ReconnectToServer(); };
ok( !$@, "ReconnectToServer does not die" ) or diag("ReconnectToServer died: $@");
ok( $bot->IsConnected(), "Bot reports connected after ReconnectToServer" );
ok( defined $bot->jabber_client, "jabber_client is defined after reconnect" );

# Test 4: Process works after reconnect
my $process_result = $bot->Process(1);
ok( defined $process_result, "Process works after reconnect" );

# Test 5: messages_sent_today does not leak old day entries
{
    my $personal_address = "test_user\@$server/$bot_alias";

    # Simulate sending messages "yesterday" by injecting an old day entry
    my $today_yday     = ( localtime() )[7];
    my $yesterday_yday = $today_yday > 0 ? $today_yday - 1 : 364;
    $bot->messages_sent_today->{$yesterday_yday} = { 0 => 50, 1 => 30 };

    ok( exists $bot->messages_sent_today->{$yesterday_yday}, "Old day entry exists before sending" );

    # Send a message - this should trigger cleanup of old day entries
    $bot->SendPersonalMessage( $personal_address, "test cleanup" );

    ok( !exists $bot->messages_sent_today->{$yesterday_yday},
        "Old day entry cleaned up after sending a message" );
    ok( exists $bot->messages_sent_today->{$today_yday},
        "Today's entry still exists" );
}

# Test 6: Multiple disconnect/reconnect cycles work
for my $cycle ( 1 .. 2 ) {
    $bot->Disconnect();
    ok( !$bot->IsConnected(), "Disconnected in cycle $cycle" );
    $bot->ReconnectToServer();
}
