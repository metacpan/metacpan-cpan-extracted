use strict;
use warnings;
use Test::More;

eval "use Test::Cmd";
plan skip_all => 'Test::Cmd required' if $@;
plan tests    => 12;

use lib('t');
use TestUtils;

TestUtils::test_montt('t/data/250-error-1', {
    like    => [ '/generating config from/' ],
    errlike => [ '/file error - parse error - t/data/250-error-1/in/conf.d/hosts.cfg line 17: unexpected token/' ],
    exit    => 1,
});
