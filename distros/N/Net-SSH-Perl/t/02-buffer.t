#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 19;

use Net::SSH::Perl::Buffer qw( SSH1 );

my $buffer = Net::SSH::Perl::Buffer->new;

ok( $buffer, 'make a buffer' );
$buffer->put_str("foo");

is( $buffer->length, 7, 'buffer length is 7' );
is( $buffer->get_str, "foo", 'get_str returns "foo"' );
is( $buffer->offset, 7, 'offset is 7' );

$buffer->put_str(0);
is( $buffer->get_str, 0, 'get_str returns 0' );

$buffer->put_int32(999_999_999);
is( $buffer->get_int32, 999_999_999, 'get_int32 returns 999,99,999' );

$buffer->put_int8(2);
is( $buffer->get_int8, 2, 'get_int8 returns 2' );

$buffer->put_char('a');
is( $buffer->get_char, 'a', 'get_char returns "a"' );

eval {
	require Math::GMP;
	Math::GMP->import;
};

SKIP: {
	if ($@) {
		skip 'Math::GMP not installed',1;
	}

	my $gmp = Math::GMP->new("999999999999999999999999999999");
	$buffer->put_mp_int($gmp);
	my $tmp = $buffer->get_mp_int;
	is( "$tmp", "$gmp", 'get_mp_int returns very large number' );
}

$buffer->empty;
is( $buffer->offset, 0, 'offset is 0 after empty()' );
is( $buffer->length, 0, 'length is 0 after empty()' );
is( $buffer->bytes, '', 'bytes is "" after empty()' );

$buffer->append("foobar");
is( $buffer->length, 6, 'length is 6 after append' );
is( $buffer->bytes, "foobar", 'bytes is "foobar" after append' );

$buffer->empty;
is( $buffer->length, 0, 'length is 0 after empty() again' );
is( $buffer->dump, '' , 'dump returns ""' );

$buffer->put_int16(129);
is( $buffer->get_int16, 129, 'get_int16 returns 129' );
is( $buffer->dump, '00 81', 'dump returns "00 81"' );
is( $buffer->dump(1), '81', 'dump(1) returns "81"' );
