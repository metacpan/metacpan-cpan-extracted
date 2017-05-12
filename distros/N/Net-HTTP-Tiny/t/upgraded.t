use warnings;
use strict;

use Test::More tests => 1;

use Net::HTTP::Tiny qw(http_get);

eval { http_get("http://www.funet.example/pub/a\x{100}b") };
like $@, qr/\AWide character /;

1;
