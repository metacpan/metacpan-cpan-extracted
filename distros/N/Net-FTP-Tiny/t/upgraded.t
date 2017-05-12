use warnings;
use strict;

use Test::More tests => 1;

use Net::FTP::Tiny qw(ftp_get);

eval { ftp_get("ftp://ftp.funet.example/pub/a\x{100}b") };
like $@, qr/\AWide character /;

1;
