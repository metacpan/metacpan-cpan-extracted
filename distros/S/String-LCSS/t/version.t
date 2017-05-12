
use warnings;
use strict;
use Test::More tests => 3;

# Check if module loads ok
BEGIN { use_ok('String::LCSS', qw()) }

BEGIN { use_ok('String::LCSS', '1.00') }

is(String::LCSS::lcss(qw(xyzzx abcxyzefg)), 'xyz');

