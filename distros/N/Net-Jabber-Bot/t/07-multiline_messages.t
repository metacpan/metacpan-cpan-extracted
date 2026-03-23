#!perl

use strict;
use warnings;
use Test::More tests => 8;
use Net::Jabber::Bot;

use FindBin;
use lib "$FindBin::Bin/lib";
use MockJabberClient;

my $bot_alias = 'make_test_bot';
my $server = 'talk.google.com';
my $personal_address = "test_user\@$server/$bot_alias";

my %forums_and_responses;
my $forum1 = 'test_forum1';
$forums_and_responses{$forum1} = ["jbot:", ""];

my $bot = Net::Jabber::Bot->new({
    server               => $server,
    conference_server     => "conference.$server",
    port                 => 5222,
    username             => 'test_username',
    password             => 'test_pass',
    alias                => $bot_alias,
    message_function     => sub {},
    background_function  => sub {},
    loop_sleep_time      => 5,
    process_timeout      => 5,
    forums_and_responses => \%forums_and_responses,
    ignore_server_messages  => 1,
    ignore_self_messages    => 1,
    out_messages_per_second => 5,
    max_message_size        => 800,
    max_messages_per_hour   => 100,
    forum_join_grace        => 0,
});

isa_ok($bot, "Net::Jabber::Bot");

# Test 1: Newlines are preserved in sent messages
{
    my $multiline_msg = "Line one\nLine two\nLine three";
    my $result = $bot->SendPersonalMessage($personal_address, $multiline_msg);
    ok(!defined $result, "Sent multiline message successfully");

    # Check that the mock client received the message with newlines intact
    my $client = $bot->jabber_client;
    my @queue = @{$client->{message_queue}};
    is(scalar @queue, 1, "One message in queue");

    my $body = $queue[0]->GetBody();
    like($body, qr/Line one\nLine two\nLine three/, "Newlines preserved in message body");

    # Clear the queue
    @{$client->{message_queue}} = ();
}

# Test 2: Carriage return + newline preserved
{
    my $crlf_msg = "Line one\r\nLine two";
    my $result = $bot->SendPersonalMessage($personal_address, $crlf_msg);
    ok(!defined $result, "Sent CRLF message successfully");

    my $client = $bot->jabber_client;
    my @queue = @{$client->{message_queue}};
    my $body = $queue[0]->GetBody();
    like($body, qr/Line one\r\nLine two/, "CRLF preserved in message body");

    @{$client->{message_queue}} = ();
}

# Test 3: Non-printable characters (other than newlines) are still stripped
{
    my $msg_with_control = "Hello\x00\x01\x02World";
    my $result = $bot->SendPersonalMessage($personal_address, $msg_with_control);
    ok(!defined $result, "Sent message with control chars successfully");

    my $client = $bot->jabber_client;
    my @queue = @{$client->{message_queue}};
    my $body = $queue[0]->GetBody();
    is($body, "Hello.World", "Control characters replaced with dot, printable text preserved");

    @{$client->{message_queue}} = ();
}
