use strict;
use warnings;
use Test::More;

eval "use Test::Cmd";
plan skip_all => 'Test::Cmd required' if $@;
plan tests    => 13;

use lib('t');
use TestUtils;

TestUtils::test_montt('t/data/251-error-2', {
    like    => [ '/generating config from/' ],
    errlike => [ '/var.undef error - undefined variable: undefined/', '/occurs in: t/data/251-error-2/in/test.cfg:6/' ],
    exit    => 1,
});
