use strict;
use Test::More tests => 4;

BEGIN {
    require_ok('Number::Phone::JP');
    ok(scalar(keys %Number::Phone::JP::TEL_TABLE) == 0, 'not imported');
    use_ok 'Number::Phone::JP';
    ok(scalar(keys %Number::Phone::JP::TEL_TABLE), 'imported');
}
