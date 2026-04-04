#!perl

use strict;
use warnings;
use Test::More;
use Net::Jabber::Bot;

use FindBin;
use lib "$FindBin::Bin/lib";
use MockJabberClient;

BEGIN { *CORE::GLOBAL::sleep = sub { }; }

my $max_size = 200;
my $server   = 'test.example.com';
my $recipient = "user\@$server/res";

my $bot = Net::Jabber::Bot->new({
    server               => $server,
    conference_server     => "conference.$server",
    port                 => 5222,
    username             => 'test',
    password             => 'test',
    alias                => 'testbot',
    message_function     => sub {},
    forums_and_responses => { test => ["bot:"] },
    max_message_size     => $max_size,
    max_messages_per_hour => 10000,
    safety_mode          => 0,
    forum_join_grace     => 0,
});

sub send_and_get_chunks {
    my ($msg) = @_;
    @{$bot->jabber_client->{message_queue}} = ();
    $bot->SendPersonalMessage($recipient, $msg);
    return map { $_->GetBody() } @{$bot->jabber_client->{message_queue}};
}

sub all_chunks_within_limit {
    my (@chunks) = @_;
    for my $chunk (@chunks) {
        return 0 if length($chunk) > $max_size;
    }
    return 1;
}

# Short message — no splitting
{
    my @chunks = send_and_get_chunks("Hello world");
    is(scalar @chunks, 1, "Short message: single chunk");
    is($chunks[0], "Hello world", "Short message: content preserved");
}

# Exact max_size — no splitting needed
{
    my $msg = "x" x $max_size;
    my @chunks = send_and_get_chunks($msg);
    is(scalar @chunks, 1, "Exact max_size: single chunk");
    is(length($chunks[0]), $max_size, "Exact max_size: correct length");
}

# Newline at exactly position max_size (was the off-by-one trigger)
{
    my $msg = "x" x $max_size . "\n" . "y" x 50;
    my @chunks = send_and_get_chunks($msg);
    ok(all_chunks_within_limit(@chunks), "Newline at boundary: all chunks <= max_size");
    is(join('', @chunks), $msg, "Newline at boundary: content preserved");
}

# Newline just inside max_size
{
    my $msg = "x" x ($max_size - 1) . "\n" . "y" x 50;
    my @chunks = send_and_get_chunks($msg);
    ok(all_chunks_within_limit(@chunks), "Newline inside limit: all chunks <= max_size");
    is(length($chunks[0]), $max_size, "Newline inside limit: first chunk uses full max_size");
    is(join('', @chunks), $msg, "Newline inside limit: content preserved");
}

# Space at exactly position max_size
{
    my $msg = "x" x $max_size . " " . "y" x 50;
    my @chunks = send_and_get_chunks($msg);
    ok(all_chunks_within_limit(@chunks), "Space at boundary: all chunks <= max_size");
    is(join('', @chunks), $msg, "Space at boundary: content preserved");
}

# No natural break points — hard chop
{
    my $msg = "x" x 500;
    my @chunks = send_and_get_chunks($msg);
    is(scalar @chunks, 3, "No breaks: 500 chars split into 3 chunks");
    ok(all_chunks_within_limit(@chunks), "No breaks: all chunks <= max_size");
    is(join('', @chunks), $msg, "No breaks: content preserved");
}

# Multiple newlines — prefers breaking at last newline within window
{
    my $msg = "a" x 80 . "\n" . "b" x 80 . "\n" . "c" x 80;
    my @chunks = send_and_get_chunks($msg);
    ok(all_chunks_within_limit(@chunks), "Multiple newlines: all chunks <= max_size");
    is(join('', @chunks), $msg, "Multiple newlines: content preserved");
    # First chunk should break at the second newline (position 161)
    like($chunks[0], qr/\n$/, "Multiple newlines: first chunk ends with newline");
}

# Mixed spaces and newlines
{
    my $msg = "word " x 60;  # 300 chars
    my @chunks = send_and_get_chunks($msg);
    ok(all_chunks_within_limit(@chunks), "Space-separated words: all chunks <= max_size");
    is(join('', @chunks), $msg, "Space-separated words: content preserved");
}

# Empty message — no chunks produced (nothing to send)
{
    my @chunks = send_and_get_chunks("");
    is(scalar @chunks, 0, "Empty message: no chunks sent");
}

# Single newline
{
    my @chunks = send_and_get_chunks("\n");
    is(scalar @chunks, 1, "Single newline: one chunk");
    is($chunks[0], "\n", "Single newline: content preserved");
}

done_testing();
