use Test::More tests => 1;

use Parse::Pegex;

eval {
    Parse::Pegex->new(stream => 'abc');
};

$@
    ? pass "new() dies appropriately"
    : fail "new() should die";
