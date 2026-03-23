#!perl

use strict;
use warnings;

BEGIN { *CORE::GLOBAL::sleep = sub { }; }

use Test::More tests => 10;
use Net::Jabber::Bot;

use FindBin;
use lib "$FindBin::Bin/lib";
use MockJabberClient;

my $bot_alias = 'make_test_bot';
my $server    = 'talk.google.com';
my $personal_address = "test_user\@$server/$bot_alias";

my %forums_and_responses;
$forums_and_responses{'test_forum1'} = [ "jbot:", "" ];

my $bot = Net::Jabber::Bot->new(
    server                 => $server,
    conference_server      => "conference.$server",
    port                   => 5222,
    username               => 'test_username',
    password               => 'test_pass',
    alias                  => $bot_alias,
    message_function       => sub { },
    background_function    => sub { },
    loop_sleep_time        => 5,
    process_timeout        => 5,
    forums_and_responses   => \%forums_and_responses,
    ignore_server_messages => 1,
    ignore_self_messages   => 1,
    out_messages_per_second => 5,
    max_message_size       => 1000,
    max_messages_per_hour  => 10,
    forum_join_grace       => 0,
);

isa_ok( $bot, "Net::Jabber::Bot" );

# Send one message while connected — should succeed and count
my $count_before = $bot->get_messages_this_hour();
my $result = $bot->SendPersonalMessage( $personal_address, "message while connected" );
ok( !defined $result, "Message sent successfully while connected" );
is( $bot->get_messages_this_hour(), $count_before + 1, "Counter incremented for sent message" );

# Now disconnect
$bot->Disconnect();
ok( !$bot->IsConnected(), "Bot is disconnected" );

# Send several messages while disconnected — they should all fail
my $count_after_disconnect = $bot->get_messages_this_hour();
for my $i ( 1 .. 5 ) {
    my $fail_result = $bot->SendPersonalMessage( $personal_address, "message while disconnected $i" );
    ok( defined $fail_result, "Message $i correctly rejected while disconnected" );
}

# The hourly counter should NOT have increased during disconnection
is( $bot->get_messages_this_hour(), $count_after_disconnect,
    "Hourly message counter unchanged by messages attempted while disconnected" );
