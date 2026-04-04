#!perl

use strict;
use warnings;

# Override sleep to avoid delays in tests
BEGIN { *CORE::GLOBAL::sleep = sub { }; }

use Test::More tests => 22;
use Net::Jabber::Bot;

# stuff for mock client object
use FindBin;
use lib "$FindBin::Bin/lib";
use MockJabberClient;    # Test object

my $server = 'talk.google.com';

my %forums_and_responses;
$forums_and_responses{'test_forum1'} = [ "jbot:", "" ];

# Test 1: Stop() method exists and returns true
{
    my $bot = Net::Jabber::Bot->new(
        server               => $server,
        conference_server     => "conference.$server",
        port                 => 5222,
        username             => 'test_username',
        password             => 'test_pass',
        alias                => 'stop_test_bot',
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
    ok( $bot->Stop(), "Stop() returns true" );
}

# Test 2: Start() exits when Stop() is called from background_function
{
    my $bg_count = 0;
    my $bot = Net::Jabber::Bot->new(
        server               => $server,
        conference_server     => "conference.$server",
        port                 => 5222,
        username             => 'test_username',
        password             => 'test_pass',
        alias                => 'start_stop_bot',
        message_function     => sub { },
        background_function  => sub {
            my ( $bot_obj, $counter ) = @_;
            $bg_count = $counter;
            $bot_obj->Stop() if $counter >= 3;
        },
        loop_sleep_time      => 0.01,
        process_timeout      => 0.01,
        forums_and_responses => \%forums_and_responses,
        out_messages_per_second => 5,
        max_message_size       => 800,
        max_messages_per_hour  => 100,
        forum_join_grace       => 0,
    );

    my $iterations = $bot->Start();
    ok( !$bot->_running, "Bot is no longer running after Start() returns" );
    is( $bg_count, 3, "Background function was called 3 times" );
    is( $iterations, 3, "Start() returns the iteration count" );
}

# Test 3: Calling Stop() before Start() does not prevent Start() from running
{
    my $bg_count = 0;
    my $bot = Net::Jabber::Bot->new(
        server               => $server,
        conference_server     => "conference.$server",
        port                 => 5222,
        username             => 'test_username',
        password             => 'test_pass',
        alias                => 'prestop_bot',
        message_function     => sub { },
        background_function  => sub {
            my ( $bot_obj, $counter ) = @_;
            $bg_count = $counter;
            $bot_obj->Stop();    # Stop on first background call
        },
        loop_sleep_time      => 0.01,
        process_timeout      => 0.01,
        forums_and_responses => \%forums_and_responses,
        out_messages_per_second => 5,
        max_message_size       => 800,
        max_messages_per_hour  => 100,
        forum_join_grace       => 0,
    );

    $bot->Stop();    # Stop before Start — should have no lasting effect
    my $iterations = $bot->Start();

    # Start() resets _running to 1, so a prior Stop() does not prevent the loop.
    ok( $bg_count > 0, "Start() still runs despite prior Stop() call" );
}

# Test 4: Start() can be called again after Stop()
{
    my $total_bg_calls = 0;
    my $run_number     = 0;
    my $bot = Net::Jabber::Bot->new(
        server               => $server,
        conference_server     => "conference.$server",
        port                 => 5222,
        username             => 'test_username',
        password             => 'test_pass',
        alias                => 'restart_bot',
        message_function     => sub { },
        background_function  => sub {
            my ( $bot_obj, $counter ) = @_;
            $total_bg_calls++;
            $bot_obj->Stop() if $counter >= 2;
        },
        loop_sleep_time      => 0.01,
        process_timeout      => 0.01,
        forums_and_responses => \%forums_and_responses,
        out_messages_per_second => 5,
        max_message_size       => 800,
        max_messages_per_hour  => 100,
        forum_join_grace       => 0,
    );

    my $iters1 = $bot->Start();
    is( $iters1, 2, "First Start() ran 2 iterations" );

    my $iters2 = $bot->Start();
    is( $iters2, 2, "Second Start() ran 2 iterations" );

    is( $total_bg_calls, 4, "Background function called 4 times total across both runs" );
}

# Test 5: Stop() from message_function also works
{
    my $msg_received = 0;
    my $bot = Net::Jabber::Bot->new(
        server               => $server,
        conference_server     => "conference.$server",
        port                 => 5222,
        username             => 'test_username',
        password             => 'test_pass',
        alias                => 'msg_stop_bot',
        message_function     => sub {
            my %args = @_;
            $msg_received++;
            $args{bot_object}->Stop();
        },
        background_function  => sub { },
        loop_sleep_time      => 0.01,
        process_timeout      => 0.01,
        forums_and_responses => \%forums_and_responses,
        out_messages_per_second => 5,
        max_message_size       => 800,
        max_messages_per_hour  => 100,
        forum_join_grace       => 0,
        ignore_self_messages   => 0,
        safety_mode            => 0,
    );

    # Inject a message that will trigger the callback
    $bot->SendPersonalMessage( 'test_user@' . $server . '/res', "trigger stop" );

    my $iterations = $bot->Start();
    ok( $msg_received > 0, "Message function was called" );
    ok( !$bot->_running, "Bot stopped from message_function" );
}

# Test 6: Start() returns cleanly after normal operation
{
    my $bot = Net::Jabber::Bot->new(
        server               => $server,
        conference_server     => "conference.$server",
        port                 => 5222,
        username             => 'test_username',
        password             => 'test_pass',
        alias                => 'error_stop_bot',
        message_function     => sub { },
        background_function  => sub {
            my ( $bot_obj, $counter ) = @_;
            $bot_obj->Stop();
        },
        loop_sleep_time      => 0.01,
        process_timeout      => 0.01,
        forums_and_responses => \%forums_and_responses,
        out_messages_per_second => 5,
        max_message_size       => 800,
        max_messages_per_hour  => 100,
        forum_join_grace       => 0,
    );

    ok( $bot->IsConnected(), "Bot connected before Start" );

    my $iterations = $bot->Start();
    ok( defined $iterations, "Start() returned cleanly after normal operation" );
}

# Test 7: Start() reconnects when Process() dies (exception)
{
    my $bg_count = 0;
    my $bot = Net::Jabber::Bot->new(
        server               => $server,
        conference_server     => "conference.$server",
        port                 => 5222,
        username             => 'test_username',
        password             => 'test_pass',
        alias                => 'die_reconnect_bot',
        message_function     => sub { },
        background_function  => sub {
            my ( $bot_obj, $counter ) = @_;
            $bg_count = $counter;
            $bot_obj->Stop() if $counter >= 2;
        },
        loop_sleep_time      => 0.01,
        process_timeout      => 0.01,
        forums_and_responses => \%forums_and_responses,
        out_messages_per_second => 5,
        max_message_size       => 800,
        max_messages_per_hour  => 100,
        forum_join_grace       => 0,
    );

    # Make Process() die on the first call — Start() should catch it and reconnect
    $Net::Jabber::Client::process_die_remaining = 1;

    my $iterations = $bot->Start();
    ok( $bot->IsConnected(), "Bot reconnected after Process() exception" );
    is( $bg_count, 2, "Background function ran after reconnection from exception" );
    is( $Net::Jabber::Client::process_die_remaining, 0, "Process die counter exhausted" );
}

# Test 8: Start() reconnects when Process() returns undef (silent disconnect)
{
    my $bg_count = 0;
    my $bot = Net::Jabber::Bot->new(
        server               => $server,
        conference_server     => "conference.$server",
        port                 => 5222,
        username             => 'test_username',
        password             => 'test_pass',
        alias                => 'undef_reconnect_bot',
        message_function     => sub { },
        background_function  => sub {
            my ( $bot_obj, $counter ) = @_;
            $bg_count = $counter;
            $bot_obj->Stop() if $counter >= 2;
        },
        loop_sleep_time      => 0.01,
        process_timeout      => 0.01,
        forums_and_responses => \%forums_and_responses,
        out_messages_per_second => 5,
        max_message_size       => 800,
        max_messages_per_hour  => 100,
        forum_join_grace       => 0,
    );

    # Make Process() return undef (simulating silent connection loss)
    $Net::Jabber::Client::process_return_undef_remaining = 1;

    my $iterations = $bot->Start();
    ok( $bot->IsConnected(), "Bot reconnected after silent disconnect (Process undef)" );
    is( $bg_count, 2, "Background function ran after reconnection from undef" );
    is( $Net::Jabber::Client::process_return_undef_remaining, 0, "Process undef counter exhausted" );
}

# Test 9: Start() survives multiple reconnections in one run
{
    my $bg_count = 0;
    my $bot = Net::Jabber::Bot->new(
        server               => $server,
        conference_server     => "conference.$server",
        port                 => 5222,
        username             => 'test_username',
        password             => 'test_pass',
        alias                => 'multi_reconnect_bot',
        message_function     => sub { },
        background_function  => sub {
            my ( $bot_obj, $counter ) = @_;
            $bg_count = $counter;
            $bot_obj->Stop() if $counter >= 3;
        },
        loop_sleep_time      => 0.01,
        process_timeout      => 0.01,
        forums_and_responses => \%forums_and_responses,
        out_messages_per_second => 5,
        max_message_size       => 800,
        max_messages_per_hour  => 100,
        forum_join_grace       => 0,
    );

    # Two failures: first a die, then a undef return
    $Net::Jabber::Client::process_die_remaining = 1;
    $Net::Jabber::Client::process_return_undef_remaining = 1;

    my $iterations = $bot->Start();
    ok( $bot->IsConnected(), "Bot survived multiple reconnections" );
    is( $bg_count, 3, "Background function ran 3 times after multiple reconnections" );
}
