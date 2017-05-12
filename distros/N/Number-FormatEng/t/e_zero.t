
use warnings;
use strict;
use Test::More tests => 13;

# Check if module loads ok
BEGIN { use_ok('Number::FormatEng', qw(:all)) }

is(format_eng(1)            , '1');
is(format_eng(99999)        , '99.999e3');
is(format_eng(-12)          , '-12');
is(format_eng(0)            , '0', 'zero');
is(format_eng(0.00)         , '0', 'zero with decimals');

Number::FormatEng::use_e_zero();

is(format_eng(1)            , '1e0');
is(format_eng(99999)        , '99.999e3');
is(format_eng(-12)          , '-12e0');
is(format_eng(0)            , '0e0', 'zero');
is(format_eng(0.00)         , '0e0', 'zero with decimals');

Number::FormatEng::no_e_zero();

is(format_eng(55.23456)     , '55.23456');
is(format_eng(999.99)       , '999.99');
