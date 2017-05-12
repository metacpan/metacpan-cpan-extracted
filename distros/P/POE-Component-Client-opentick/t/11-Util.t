#!/usr/bin/perl
#
#   Unit tests for ::Util.pm
#
#   infi/2008
#

use strict;
use warnings;
use Test::More tests => 15;

# Misc junk
my $template = 'v v a*';
my $template2 = 'v C C x16 a6 a64 a64';
my $template3 = 'v C C x x a6 a64 x83 xxxxx x     x    xxxx   x42 a64';
my $data      = "\x01\x00\x00\x00\x02\x00\x00\x00";
my $macaddr  = '5a:A5f0-0f-42:FF';  # Test a really insane mac address
my $err_code = 0xA5F0;
my $err_msg  = 'Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.';
my $err_len  = length($err_msg);
my( $results, $target );
my @fields;

BEGIN {
# Test #1: Can use Util module
    use_ok( 'POE::Component::Client::opentick::Util' );
}

# Test #2: Count fields
is( count_fields( $template ), 3, 'count_fields basic' );

# Test #3: Count fields
is( count_fields( $template2 ), 6, 'count_fields extended' );

# Test #4: Count fields
is( count_fields( $template3), 6, 'count_fields insane' );

# Test #5: Check Fields
is( check_fields( 4, $template, $err_code, $err_msg, $err_len ),
    1,
    'check_fields'
);

# Test #6: check_Fields with too many fields
isnt(
    check_fields( 2, $template, $err_code, $err_msg ),
    1,
    'check_fields too many',
);

# Test #7: check_Fields with too few fields
isnt(
    check_fields( 3, $template, $err_code ),
    1,
    'check_fields too few',
);

# Test #8: check_Fields with undefined fields
isnt(
    check_fields( 3, $template, undef, $err_code ),
    1,
    'check_fields with undefined',
);

# Test #9: pack_binary
ok(
    $results = pack_binary( $template, $err_code, $err_len, $err_msg ),
    'pack_binary',
);

# Test #10: unpack_binary
ok(
    ( @fields = unpack_binary( $template, $results ) ) == 3,
    'unpack_binary'
);

# Test #11: pack_binary && unpack_binary consistency.
ok(
    $fields[0] == $err_code         &&
    $fields[1] == $err_len          &&
    $fields[2] eq $err_msg,
    'pack_binary() == unpack_binary()',
);

# Test #12: Sane output from dump_hex
is(
    dump_hex( 'akhkj35jkb13ajbwaj51bc02whrjqbr5' ),
    "61 6b 68 6b 6a 33 35 6a 6b 62 31 33 61 6a 62 77\n" .
        "61 6a 35 31 62 63 30 32 77 68 72 6a 71 62 72 35\n",
    'dump_hex() sanity',
);

# Test #13: Make sure pack_macaddr returns sane results.

# Set up the test
($results) = unpack_binary( 'H*', pack_macaddr( $macaddr ) );
($target = $macaddr) =~ s/[:-]//g;
$target = lc( $target );

# Run the test
is( $results, $target, 'pack_macaddr() sanity' );

# Test #14: pack_bytes() correctness.
is(
    pack_bytes( 'C a12 a12 d V a4 a2 a2 a a9 a3 a' ),
    59,
    'pack_bytes() correctness',
);

my $chunks = unpack( 'a8', $data );

# Test: asc2longlong()
is( asc2longlong( $chunks ), 8589934593, 'asc2longlong() correctness' );

__END__
