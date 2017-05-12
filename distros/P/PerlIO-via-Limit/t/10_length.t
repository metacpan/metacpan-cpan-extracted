use strict;
use Test::More tests => 3;

use PerlIO::via::Limit length => 10;
is( PerlIO::via::Limit->length, 10, 'PerlIO::via::Limit::length');

PerlIO::via::Limit->length(undef);
is( PerlIO::via::Limit->length, undef, 'set PerlIO::via::Limit::length to undef');

PerlIO::via::Limit->length(100);
is( PerlIO::via::Limit->length, 100, 'set PerlIO::via::Limit::length to num');
