#!perl -T

use Test::More tests => 11;

use_ok('Number::Bytes::Human', 'format_bytes', 'parse_bytes');

is(format_bytes(0), '0', "0 turns to '0' by default");
is(format_bytes(0, zero => '-'), '-', "0 turns to '-'");
is(format_bytes(0, zero => '*'), '*', "0 turns to '*'");
is(format_bytes(0, zero => '0%S', suffixes => [ 'B' ]), '0B', "0 turns to '0B'");

# zero => undef
is(format_bytes(0, zero => undef, suffixes => [ ' B' ]), '0.0 B', "0 turns to '0.0 B'");   #'0 B', wrong with the default being precision 1 with cutoff digits 1 and zero being undef
is(parse_bytes(undef, zero => undef), 0, "undef maps to 0");   # undef maps to 0 if zero is to be recognized as undef

is(parse_bytes('0'), 0, "0 turns to '0' by default");
is(parse_bytes('-', zero => '-'), 0, "0 turns to '-'");
is(parse_bytes('*', zero => '*'), 0, "0 turns to '*'");
is(parse_bytes('0B', zero => '0%S', suffixes => [ 'B' ]), 0, "0 turns to '0B'");
