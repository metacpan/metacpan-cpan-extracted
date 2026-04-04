#!perl

use strict;
use warnings;

BEGIN { *CORE::GLOBAL::sleep = sub { }; }

use Test::More;
use Net::Jabber::Bot;

use FindBin;
use lib "$FindBin::Bin/lib";
use MockJabberClient;

my $bot_alias = 'test_bot';
my $server    = 'jabber.example.com';

my %forums_and_responses;
$forums_and_responses{'test_room'} = [ "bot:", "" ];

my $bot = Net::Jabber::Bot->new(
    server                  => $server,
    conference_server       => "conference.$server",
    port                    => 5222,
    username                => 'testuser',
    password                => 'testpass',
    alias                   => $bot_alias,
    message_function        => sub { },
    background_function     => sub { },
    loop_sleep_time         => 5,
    process_timeout         => 5,
    forums_and_responses    => \%forums_and_responses,
    out_messages_per_second => 5,
    max_message_size        => 150,
    max_messages_per_hour   => 100,
    forum_join_grace        => 0,
);

isa_ok( $bot, "Net::Jabber::Bot" );

# Helper: drain the sent_messages_log and return the entries
sub drain_sent {
    my $client = shift || $bot->jabber_client;
    my @msgs = @{ $client->{sent_messages_log} };
    @{ $client->{sent_messages_log} } = ();
    @{ $client->{message_queue} }     = ();
    return @msgs;
}

# ─── SendGroupMessage ─────────────────────────────────────

subtest 'SendGroupMessage appends conference_server when no @ present' => sub {
    drain_sent();
    $bot->SendGroupMessage( "myroom", "hello" );
    my @msgs = drain_sent();
    ok( scalar @msgs >= 1, "At least one message sent" );
    is( $msgs[0]->{to}, "myroom\@conference.$server",
        "Recipient has conference server appended" );
    is( $msgs[0]->{type}, 'groupchat', "Message type is groupchat" );
    is( $msgs[0]->{body}, 'hello',     "Body preserved" );
};

subtest 'SendGroupMessage preserves full JID when @ present' => sub {
    drain_sent();
    $bot->SendGroupMessage( "myroom\@custom.conference.example.com", "hello" );
    my @msgs = drain_sent();
    is( $msgs[0]->{to}, 'myroom@custom.conference.example.com',
        "Full JID preserved, conference_server not appended" );
};

# ─── SendPersonalMessage ──────────────────────────────────

subtest 'SendPersonalMessage sends as chat type' => sub {
    drain_sent();
    $bot->SendPersonalMessage( "friend\@$server/resource", "hey" );
    my @msgs = drain_sent();
    is( scalar @msgs, 1, "One message sent" );
    is( $msgs[0]->{type}, 'chat', "Message type is chat" );
    is( $msgs[0]->{body}, 'hey',  "Body preserved" );
    is( $msgs[0]->{to}, "friend\@$server/resource", "Recipient preserved" );
};

# ─── Message chunking ─────────────────────────────────────

subtest 'Short message not chunked' => sub {
    drain_sent();
    my $msg = "short message";
    $bot->SendPersonalMessage( "friend\@$server/res", $msg );
    my @msgs = drain_sent();
    is( scalar @msgs, 1, "Single chunk for short message" );
    is( $msgs[0]->{body}, $msg, "Body unchanged" );
};

subtest 'Long message chunked to max_message_size' => sub {
    drain_sent();
    my $max = $bot->max_message_size;
    my $msg = "a" x ( $max * 3 );
    $bot->SendPersonalMessage( "friend\@$server/res", $msg );
    my @msgs = drain_sent();
    ok( scalar @msgs >= 3, "Message split into 3+ chunks (got " . scalar(@msgs) . ")" );
    for my $i ( 0 .. $#msgs ) {
        my $len = length( $msgs[$i]->{body} );
        # Each chunk should be at most max_message_size (+1 for possible delimiter)
        ok( $len <= $max + 1, "Chunk $i is $len bytes (<= " . ( $max + 1 ) . ")" );
        ok( $len > 0,         "Chunk $i is non-empty" );
    }
    # Reassembled message should equal original
    my $reassembled = join( '', map { $_->{body} } @msgs );
    is( $reassembled, $msg, "Chunks reassemble to original message" );
};

subtest 'Chunking prefers newline boundaries' => sub {
    drain_sent();
    my $max = $bot->max_message_size;
    # Build a message where a newline sits before max_size
    # so the chunker prefers to split there
    my $first_part  = "a" x ( $max - 10 );
    my $second_part = "b" x ( $max - 10 );
    my $msg         = $first_part . "\n" . $second_part;
    $bot->SendPersonalMessage( "friend\@$server/res", $msg );
    my @msgs = drain_sent();
    is( scalar @msgs, 2, "Split into 2 chunks at newline" );
    like( $msgs[0]->{body}, qr/^a+\n$/,  "First chunk ends with newline" );
    like( $msgs[1]->{body}, qr/^b+$/,    "Second chunk is the remainder" );
};

subtest 'Chunking prefers whitespace boundaries' => sub {
    drain_sent();
    my $max         = $bot->max_message_size;
    my $first_part  = "a" x ( $max - 10 );
    my $second_part = "b" x ( $max - 10 );
    my $msg         = $first_part . " " . $second_part;
    $bot->SendPersonalMessage( "friend\@$server/res", $msg );
    my @msgs = drain_sent();
    is( scalar @msgs, 2, "Split into 2 chunks at whitespace" );
    like( $msgs[0]->{body}, qr/^a+ $/,   "First chunk ends with space" );
    like( $msgs[1]->{body}, qr/^b+$/,    "Second chunk is the remainder" );
};

subtest 'Chunking hard-cuts when no natural boundaries' => sub {
    drain_sent();
    my $max = $bot->max_message_size;
    my $msg = "x" x ( $max * 2 + 1 );    # No newlines or spaces
    $bot->SendPersonalMessage( "friend\@$server/res", $msg );
    my @msgs = drain_sent();
    is( scalar @msgs, 3, "Split into 3 chunks" );
    is( length( $msgs[0]->{body} ), $max, "First chunk is exactly max_size" );
    is( length( $msgs[1]->{body} ), $max, "Second chunk is exactly max_size" );
    is( length( $msgs[2]->{body} ), 1,    "Third chunk is remainder" );
};

# ─── Non-printable character stripping ────────────────────

subtest 'Non-printable characters stripped from messages' => sub {
    drain_sent();
    my $msg = "hello\x00world\x07!";
    $bot->SendPersonalMessage( "friend\@$server/res", $msg );
    my @msgs = drain_sent();
    unlike( $msgs[0]->{body}, qr/\x00/, "Null byte stripped" );
    unlike( $msgs[0]->{body}, qr/\x07/, "Bell character stripped" );
    like( $msgs[0]->{body}, qr/hello.*world/, "Printable text preserved" );
};

subtest 'Newlines preserved in messages' => sub {
    drain_sent();
    my $msg = "line1\nline2\r\nline3";
    $bot->SendPersonalMessage( "friend\@$server/res", $msg );
    my @msgs = drain_sent();
    like( $msgs[0]->{body}, qr/\n/, "LF preserved" );
    like( $msgs[0]->{body}, qr/\r/, "CR preserved" );
};

# ─── Rate limiting ────────────────────────────────────────

subtest 'Rate limit enforced at max_messages_per_hour' => sub {
    my $rate_bot = Net::Jabber::Bot->new(
        server                  => $server,
        conference_server       => "conference.$server",
        port                    => 5222,
        username                => 'testuser',
        password                => 'testpass',
        alias                   => 'rate_bot',
        message_function        => sub { },
        loop_sleep_time         => 5,
        process_timeout         => 5,
        forums_and_responses    => {},
        out_messages_per_second => 5,
        max_message_size        => 1000,
        max_messages_per_hour   => 3,
        forum_join_grace        => 0,
    );

    # Send up to the limit
    for my $i ( 1 .. 3 ) {
        my $result = $rate_bot->SendPersonalMessage( "user\@$server/res", "msg $i" );
        ok( !defined $result, "Message $i sent successfully (within limit)" );
    }

    # The 4th message should be rate-limited
    my $result = $rate_bot->SendPersonalMessage( "user\@$server/res", "msg 4" );
    like( $result, qr/Too many messages/, "4th message rejected by rate limit" );
};

subtest 'Panic message sent when hitting rate limit exactly' => sub {
    my $panic_bot = Net::Jabber::Bot->new(
        server                  => $server,
        conference_server       => "conference.$server",
        port                    => 5222,
        username                => 'testuser',
        password                => 'testpass',
        alias                   => 'panic_bot',
        message_function        => sub { },
        loop_sleep_time         => 5,
        process_timeout         => 5,
        forums_and_responses    => {},
        out_messages_per_second => 5,
        max_message_size        => 1000,
        max_messages_per_hour   => 2,
        forum_join_grace        => 0,
    );

    my $client = $panic_bot->jabber_client;

    # Send first message (below limit)
    $panic_bot->SendPersonalMessage( "user\@$server/res", "msg 1" );
    drain_sent($client);

    # Send the message that hits the limit exactly
    $panic_bot->SendPersonalMessage( "user\@$server/res", "msg 2" );
    my @msgs = drain_sent($client);

    # Should have the actual message AND the panic notification
    is( scalar @msgs, 2, "Two messages: the actual send + panic notification" );
    like( $msgs[1]->{body}, qr/Cannot send more messages this hour/,
        "Panic message warns about rate limit" );
};

# ─── SetForumSubject ──────────────────────────────────────

subtest 'SetForumSubject sends subject with groupchat message' => sub {
    drain_sent();
    my $result = $bot->SetForumSubject( "myroom\@conference.$server", "New Topic" );
    ok( !defined $result, "Returns undef on success" );
    my @msgs = drain_sent();
    is( scalar @msgs, 1, "One message sent" );
    is( $msgs[0]->{type}, 'groupchat', "Type is groupchat" );
    is( $msgs[0]->{subject}, 'New Topic', "Subject set correctly" );
    like( $msgs[0]->{body}, qr/Setting subject to New Topic/, "Body announces subject change" );
};

# ─── Edge cases ───────────────────────────────────────────

subtest 'SendJabberMessage with undefined message_type returns error' => sub {
    my $result = $bot->SendJabberMessage( "user\@$server", "test", undef );
    like( $result, qr/No message type/, "Returns error for undefined type" );
};

subtest 'SendJabberMessage with undefined recipient returns error' => sub {
    my $result = $bot->SendJabberMessage( undef, "test", "chat" );
    like( $result, qr/No recipient/, "Returns error for undefined recipient" );
};

subtest 'Sending while disconnected returns error' => sub {
    $bot->Disconnect();
    my $result = $bot->SendPersonalMessage( "user\@$server/res", "test" );
    like( $result, qr/Server is down/, "Returns server down error" );
};

done_testing();
