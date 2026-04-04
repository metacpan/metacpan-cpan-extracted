#!perl

use strict;
use warnings;

use Test::More tests => 13;
use Net::Jabber::Bot;

# Mock client
use FindBin;
use lib "$FindBin::Bin/lib";
use MockJabberClient;

BEGIN { *CORE::GLOBAL::sleep = sub { }; }

my $bot_alias = 'make_test_bot';
my $server    = 'talk.google.com';
my $conf_server = "conference.$server";

my %forums_and_responses;
my $forum1 = 'test_forum1';
$forums_and_responses{$forum1} = [ "jbot:", "" ];

my $bot = Net::Jabber::Bot->new(
    server                  => $server,
    conference_server       => $conf_server,
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
    max_message_size        => 200,
    max_messages_per_hour   => 100,
    forum_join_grace        => 0,
);

isa_ok( $bot, "Net::Jabber::Bot" );

# Track MessageSend calls
my @sent_messages;
{
    no warnings 'redefine';
    my $original = \&Net::Jabber::Client::MessageSend;
    *Net::Jabber::Client::MessageSend = sub {
        my $self = shift;
        my %args = @_;
        push @sent_messages, \%args;
        $original->( $self, @_ );
    };
}

# Use full conference JID as recipient (mirrors how real code works)
my $forum_jid = "$forum1\@$conf_server";

# Test 1: Normal subject setting
@sent_messages = ();
my $result = $bot->SetForumSubject( $forum_jid, "New Topic" );
ok( !defined $result, "SetForumSubject returns undef on success" );
is( scalar @sent_messages, 1, "Exactly one message sent" );
is( $sent_messages[0]{type}, 'groupchat', "Message sent as groupchat" );
is( $sent_messages[0]{subject}, 'New Topic', "Subject field is set correctly" );
like( $sent_messages[0]{body}, qr/Setting subject to New Topic/, "Body describes the subject change" );

# Test 2: Subject exceeding max_message_size is rejected early
@sent_messages = ();
my $long_subject = 'X' x 201;    # max_message_size is 200 (safety capped from constructor)
$result = $bot->SetForumSubject( $forum_jid, $long_subject );
is( $result, "Subject is too long!", "Returns error for oversized subject" );
is( scalar @sent_messages, 0, "No message sent for oversized subject" );

# Test 3: Subject exactly at max_message_size succeeds
@sent_messages = ();
my $exact_subject = 'Y' x 200;
$result = $bot->SetForumSubject( $forum_jid, $exact_subject );
ok( !defined $result, "Subject at exact max size succeeds" );
is( $sent_messages[0]{subject}, $exact_subject, "Full subject preserved at max size" );

# Test 4: Subject one char below max_message_size succeeds
@sent_messages = ();
my $under_subject = 'Z' x 199;
$result = $bot->SetForumSubject( $forum_jid, $under_subject );
ok( !defined $result, "Subject one below max size succeeds" );

# Test 5: SetForumSubject while disconnected
# _send_individual_message returns "Server is down.\n" when not connected,
# and SetForumSubject propagates that return value.
$bot->Disconnect();
@sent_messages = ();
$result = $bot->SetForumSubject( $forum_jid, "Should fail" );
like( $result, qr/Server is down/, "Returns error string when disconnected" );
is( scalar @sent_messages, 0, "No message sent when disconnected" );

exit;
