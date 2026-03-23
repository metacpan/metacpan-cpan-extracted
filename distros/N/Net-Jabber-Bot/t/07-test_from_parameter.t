#!perl

use strict;
use warnings;

use Test::More tests => 9;
use Net::Jabber::Bot;

# stuff for mock client object
use FindBin;
use lib "$FindBin::Bin/lib";
use MockJabberClient;    # Test object

my $bot_alias = 'make_test_bot';
my $server    = 'talk.google.com';
my $personal_address = "test_user\@$server/$bot_alias";

my %forums_and_responses;
my $forum1 = 'test_forum1';
$forums_and_responses{$forum1} = [ "jbot:", "" ];

ok( 1, "Creating Net::Jabber::Bot object for from parameter tests" );

my $bot = Net::Jabber::Bot->new(
    server                 => $server,
    conference_server      => "conference.$server",
    port                   => 5222,
    username               => 'test_username',
    password               => 'test_pass',
    alias                  => $bot_alias,
    message_function       => \&new_bot_message,
    background_function    => \&background_checks,
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

# Track the last MessageSend args for verification
my @last_message_send_args;

{
    no warnings 'redefine';
    my $original_message_send = \&Net::Jabber::Client::MessageSend;
    *Net::Jabber::Client::MessageSend = sub {
        my $self = shift;
        @last_message_send_args = @_;
        $original_message_send->( $self, @_ );
    };
}

# Test 1: SendPersonalMessage with from parameter
@last_message_send_args = ();
my $from_jid = 'original_sender@example.com/resource';
my $result = $bot->SendPersonalMessage( $personal_address, "Hello with from", $from_jid );
ok( !defined $result, "SendPersonalMessage with from param succeeds" );
{
    my %args = @last_message_send_args;
    is( $args{from}, $from_jid, "from parameter passed through in SendPersonalMessage" );
}

# Test 2: SendPersonalMessage without from parameter (backwards compatible)
@last_message_send_args = ();
$result = $bot->SendPersonalMessage( $personal_address, "Hello without from" );
ok( !defined $result, "SendPersonalMessage without from param succeeds" );
{
    my %args = @last_message_send_args;
    ok( !exists $args{from}, "No from parameter when not specified" );
}

# Test 3: SendGroupMessage with from parameter
@last_message_send_args = ();
$result = $bot->SendGroupMessage( $forum1, "Group hello with from", $from_jid );
ok( !defined $result, "SendGroupMessage with from param succeeds" );
{
    my %args = @last_message_send_args;
    is( $args{from}, $from_jid, "from parameter passed through in SendGroupMessage" );
}

# Test 4: SendGroupMessage without from parameter (backwards compatible)
@last_message_send_args = ();
$result = $bot->SendGroupMessage( $forum1, "Group hello without from" );
ok( !defined $result, "SendGroupMessage without from param succeeds" );

exit;

sub new_bot_message    { }
sub background_checks  { }
