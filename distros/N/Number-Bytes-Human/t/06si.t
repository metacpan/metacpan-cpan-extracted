#!perl -T

use Test::More tests => 20;

use_ok('Number::Bytes::Human', 'format_bytes', 'parse_bytes');

# Checks for format_bytes
is(format_bytes(0, si => 1), '0', "0 still turns to '0' on SI with base 1024");
is(format_bytes(0, si => 1, bs => 1000), '0', "0 still turns to '0' on SI with base 1000");

is(format_bytes(1000, si => 1, bs => 1000), '1.0kB', "1000 turns to '1.0kB' on SI with base 1000");
is(format_bytes(10E6, si => 1, bs => 1000), '10MB', "10E6 turns to '10MB' on SI with base 1000");

is(format_bytes(1000, si => 1), '1000B', "1000 turns to '1000B' on SI with base 1024");

# Checks for parse_bytes
is(parse_bytes('0'), 0, "'0' still turns to 0");
is(parse_bytes('0', si => 1), 0, "'0' still turns to 0 with SI only enabled");
is(parse_bytes('0', si => 1, bs => 1000), 0, "'0' still turns to 0 with SI only enabled and base 1000");

is(parse_bytes('1.0K'), 1024, "'1.0K' turns to 1024");
is(parse_bytes('1.0K', bs => 1000), 1000, "'1.0K' turns to 1000 with base 1000");
is(parse_bytes('1.0kB'), 1000, "'1.0kB' turns to 1000");
is(parse_bytes('1.0kB', si => 1), 1000, "'1.0kB' turns to 1000 with SI only enabled");
is(parse_bytes('1.0KiB'), 1024, "'1.0KiB' turns to 1024");
is(parse_bytes('1.0KiB', si => 1), 1024, "'1.0kB' turns to 1024 with SI only enabled");
is(parse_bytes('10MB'), 10E6, "10MB turns to 10E6 on SI with base 1000");
is(parse_bytes('10MB', si => 1), 10E6, "10MB turns to 10E6 on SI");
is(parse_bytes('10MiB', si => 1), 10*1024*1024, "10MB turns to 10*1024^2 on SI");

is(parse_bytes('1000B'), 1000, "'1000B' turns to 1000");
is(parse_bytes('1000B', si => 1), 1000, "'1000B' turns to 1000 even when accepting only SI units");
