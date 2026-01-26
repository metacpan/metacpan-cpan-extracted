#!/usr/bin/env perl
use v5.40;
use lib 'lib';
use Net::BitTorrent::Protocol::BEP03::Bencode qw[bencode bdecode];
use Data::Dumper;

# Simple Scalars
my $int = bencode(42);
say "Encoded 42: $int";
say 'Decoded: ' . bdecode($int);
#
my $str = bencode('Hello Perl');
say "Encoded string: $str";
say 'Decoded: ' . bdecode($str);

# Complex Data Structures
my $data = {
    announce => 'http://tracker.example.com/announce',
    info     => { name => 'example_file.txt', length => 1024, pieces => pack( 'H*', 'deadbeef' x 5 ), },
    tags     => [ 'p2p', 'perl', 'bencode' ],
};
#
my $encoded = bencode($data);
say "Encoded: $encoded";
#
my $decoded = bdecode($encoded);
print 'Decoded structure: ' . Dumper($decoded);
