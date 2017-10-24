#!/usr/bin/env perl

use Test::More;

plan tests => 3;

use Net::WebSocket::Message ();
use Net::WebSocket::PMCE::deflate ();
use Net::WebSocket::PMCE::deflate::Data::Server ();

my $deflate = Net::WebSocket::PMCE::deflate::Data::Server->new(
    'deflate_no_context_takeover' => 1,
);

my $streamer = $deflate->create_streamer( 'Net::WebSocket::Frame::text' );

my @frames = (
    $streamer->create_chunk('Hello') || (),
    $streamer->create_final('Hello'),
);

#----------------------------------------------------------------------

my $msg = Net::WebSocket::Message::create_from_frames(@frames);

my $round_trip = $deflate->decompress( $msg->get_payload() );

is( $round_trip, 'HelloHello', 'round-trip single message' ) or do {
    diag( sprintf "%v.02x\n", $_ ) for map { $_->to_bytes() } @frames;
};

my $streamer2 = $deflate->create_streamer( 'Net::WebSocket::Frame::text' );

my @frames2 = (
    $streamer2->create_chunk('Hello') || (),
    $streamer2->create_final('Hello'),
);

my $msg2 = Net::WebSocket::Message::create_from_frames(@frames2);

TODO: {
    local $TODO = 'apparent bug in Compress::Raw::Zlib (https://rt.cpan.org/Ticket/Display.html?id=122695)';

    is(
        $msg2->get_payload(),
        $msg->get_payload(),
        'with “deflate_no_context_takeover” two identical successive messages compress the same (i.e., context is reset)',
    ) or do {
        diag( sprintf "%v.02x\n", $_ ) for map { $_->get_payload() } @frames, @frames2;
    };
}

#This is here because the former is broken.
is(
    sprintf( '%v.02x', substr( $frames[0]->get_payload(), 0, length $frames2[0]->get_payload() ) ),
    sprintf( '%v.02x', $frames2[0]->get_payload() ),
    'first message starts the same as the second (i.e., context is reset)',
) or do {
    diag( sprintf "%v.02x\n", $_ ) for map { $_->get_payload() } @frames, @frames2;
};
