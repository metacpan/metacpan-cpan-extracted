#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Test::More;

plan tests => 1;

use File::Temp;

use IO::Framed::Read ();

use Net::WebSocket::Parser ();
use Net::WebSocket::Streamer::Client ();

my $start = 'We have come to dedicate a portion of that field as a final resting-place to those who here gave their lives that that nation might live. It is altogether fitting and proper that we should do this; yet, in a larger sense, we cannot dedicate, we cannot consecrate, we cannot hallow this ground. The brave men, living and dead, who struggled here have consecrated it far beyond our poor power to add or detract. The world will little note …';

my $start_copy = $start;

my ($fh, $file) = File::Temp::tempfile( CLEANUP => 1 );

$fh->autoflush(1);

while (my $chunk = substr($start_copy, 0, 25, q<>)) {
    my $streamer = Net::WebSocket::Streamer::Client->new('text');
    while( length($chunk) > 10 ) {
        my $subchunk = substr($chunk, 0, 10, q<>);
        print {$fh} $streamer->create_chunk($subchunk)->to_bytes();
    }

    print {$fh} $streamer->create_final($chunk)->to_bytes();
}

close $fh;

open my $rdr, '<', $file;

my $parse = Net::WebSocket::Parser->new( IO::Framed::Read->new($rdr) );

my $received = q<>;

eval {
    while ( my $msg = $parse->get_next_frame() ) {
        $received .= $msg->get_payload();
    }

    1;
}
or do {
    my $err = $@;
    if (!$@->isa('IO::Framed::X::EmptyRead')) {
        local $@ = $_;
        die;
    }
};

is(
    $received,
    $start,
    'round-trip',
);

1;
