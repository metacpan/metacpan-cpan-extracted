use strict;
use warnings FATAL => 'all';
use utf8;

use lib '.';
use t::Util;

use_ok $_ for qw(
    Scope::UndefSafe
);

done_testing;

