#!perl -T

use Test::More tests => 7;

use_ok('Number::Bytes::Human', 'format_bytes', 'parse_bytes');

# Checks for format_bytes
is(format_bytes(0, bs => 1000, unit => 'bps'), '0', "0 is still '0'");
is(format_bytes(200, bs => 1000, unit => 'bps'), '200bps', "200 is '200bps'"); 
is(format_bytes(2000, bs => 1000, unit => 'bps'), '2.0kbps', "2000 is '2.0kbps'"); 

# Checks for parse_bytes
is(parse_bytes('0', bs => 1000, unit => 'bps'), 0, "'0' is still 0");
is(parse_bytes('200bps', bs => 1000, unit => 'bps'), 200, "'200bps' is 200"); 
is(parse_bytes('2.0Kbps', bs => 1000, unit => 'bps'), 2000, "'2.0Kbps' is 2000"); 
