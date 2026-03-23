#!perl

use strict;
use warnings;

BEGIN { *CORE::GLOBAL::sleep = sub { }; }

use Test::More tests => 9;
use Net::Jabber::Bot;

use FindBin;
use lib "$FindBin::Bin/lib";
use MockJabberClient;

my $bot_alias = 'make_test_bot';
my $server    = 'talk.google.com';

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
    max_messages_per_hour  => 100,
    forum_join_grace       => 0,
);

isa_ok( $bot, "Net::Jabber::Bot" );
ok( $bot->IsConnected(), "Bot starts connected" );

# Disconnect the bot
$bot->Disconnect();
ok( !$bot->IsConnected(), "Bot is disconnected" );

# Test that public API methods don't crash when disconnected.
# Before this fix, each of these would die with:
#   "Can't call method ... on an undefined value"
# because jabber_client is undef after Disconnect().

# ChangeStatus should return 0 (failure), not crash
my $status_result = eval { $bot->ChangeStatus("available", "test status") };
ok( !$@, "ChangeStatus does not crash when disconnected" )
    or diag("ChangeStatus died: $@");

# GetRoster should return empty list, not crash
my @roster = eval { $bot->GetRoster() };
ok( !$@, "GetRoster does not crash when disconnected" )
    or diag("GetRoster died: $@");
is( scalar @roster, 0, "GetRoster returns empty list when disconnected" );

# GetStatus should return 'unavailable', not crash
my $get_status = eval { $bot->GetStatus("someone\@$server") };
ok( !$@, "GetStatus does not crash when disconnected" )
    or diag("GetStatus died: $@");
is( $get_status, "unavailable", "GetStatus returns 'unavailable' when disconnected" );

# Process should return undef, not crash
my $process_result = eval { $bot->Process(1) };
ok( !$@, "Process does not crash when disconnected" )
    or diag("Process died: $@");
