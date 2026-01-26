#!/usr/bin/env perl
use v5.40;
use lib 'lib';
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode bdecode];
use Time::HiRes                               qw[gettimeofday tv_interval];
#
my $data = { list => [ 1 .. 1000 ], dict => { map { 'key_' . $_ => 'value_' . $_ } 1 .. 500 }, nest => { a => { b => { c => [ 1, 2, 3 ] } } } };
#
say 'Encoding large structure...';
my $t0          = [gettimeofday];
my $encoded     = bencode($data);
my $elapsed_enc = tv_interval($t0);
say sprintf( 'Encoded %d bytes in %.4fs', length($encoded), $elapsed_enc );
say 'Decoding large structure...';
$t0 = [gettimeofday];
my $decoded     = bdecode($encoded);
my $elapsed_dec = tv_interval($t0);
say sprintf( 'Decoded in %.4fs', $elapsed_dec );

# Round trip check
my $re_encoded = bencode($decoded);
if ( $re_encoded eq $encoded ) {
    say 'Round-trip successful (data integrity maintained)';
}
else {
    say 'Round-trip FAILED!';
}
