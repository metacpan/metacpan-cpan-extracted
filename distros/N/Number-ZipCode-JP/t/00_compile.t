use strict;
use Test::More tests => 4;

BEGIN {
    require_ok('Number::ZipCode::JP');
    ok(scalar(keys %Number::ZipCode::JP::ZIP_TABLE) == 0, 'not imported');
    use_ok 'Number::ZipCode::JP';
    ok(scalar(keys %Number::ZipCode::JP::ZIP_TABLE), 'imported');
}
