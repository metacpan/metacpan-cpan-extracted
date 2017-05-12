use strict;
use warnings;

use Test::More tests => 1;

use Protocol::SPDY::Constants;
use Compress::Zlib qw(adler32);

is(sprintf("%08x", adler32(Protocol::SPDY::Constants->ZLIB_DICTIONARY)), 'e3c6a7c2', 'adler32 CRC is correct for SPDY3 dictionary');

