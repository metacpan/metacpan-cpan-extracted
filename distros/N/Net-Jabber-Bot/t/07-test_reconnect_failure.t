#!perl

use strict;
use warnings;

# Override sleep to avoid delays in tests
BEGIN { *CORE::GLOBAL::sleep = sub { }; }

use Test::More tests => 10;
use Net::Jabber::Bot;

# stuff for mock client object
use FindBin;
use lib "$FindBin::Bin/lib";
use MockJabberClient;    # Test object

my $bot_alias = 'reconnect_fail_bot';
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
ok( $bot->IsConnected(), "Bot connected after init" );

# Test 1: _init_jabber dies when Connect returns undef
$bot->Disconnect();
ok( !$bot->IsConnected(), "Bot disconnected" );

$Net::Jabber::Client::connect_fail_remaining = 1;
eval { $bot->_init_jabber() };
like( $@, qr/Jabber server is down/, "_init_jabber dies on connection failure" );

# The partial jabber_client object is left behind — this is the state
# that ReconnectToServer must clean up
ok( defined $bot->jabber_client, "Partial client exists after failed _init_jabber" );

# Clean up for next test
$bot->jabber_client(undef);

# Test 2: ReconnectToServer survives transient failures and reconnects
$Net::Jabber::Client::connect_fail_remaining = 2;
$bot->ReconnectToServer();
ok( $bot->IsConnected(), "ReconnectToServer reconnects after 2 transient failures" );
is( $Net::Jabber::Client::connect_fail_remaining, 0, "All failures consumed" );

# Test 3: Background function runs after successful reconnect
my $bg_called = 0;
my $bot2 = Net::Jabber::Bot->new(
    server               => $server,
    conference_server     => "conference.$server",
    port                 => 5222,
    username             => 'test_username2',
    password             => 'test_pass',
    alias                => 'bg_test_bot',
    message_function     => sub { },
    background_function  => sub { $bg_called++ },
    loop_sleep_time      => 5,
    process_timeout      => 5,
    forums_and_responses => \%forums_and_responses,
    out_messages_per_second => 5,
    max_message_size       => 800,
    max_messages_per_hour  => 100,
    forum_join_grace       => 0,
);

$bg_called = 0;
$Net::Jabber::Client::connect_fail_remaining = 1;
$bot2->Disconnect();
$bot2->ReconnectToServer();
ok( $bot2->IsConnected(), "Bot2 reconnects after 1 failure" );
ok( $bg_called > 0, "Background function called after successful reconnect" );

# Test 4: Multiple failures with increasing backoff (all caught)
$Net::Jabber::Client::connect_fail_remaining = 5;
$bot->Disconnect();
$bot->ReconnectToServer();
ok( $bot->IsConnected(), "ReconnectToServer survives 5 consecutive failures" );
