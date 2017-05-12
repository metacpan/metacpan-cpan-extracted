#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More tests => 8;

use Struct::Path qw(is_implicit_step);

ok(
    is_implicit_step([]),
    "Empty array"
);

ok(
    ! is_implicit_step([1,2,3]),
    "Explicit array items"
);

ok(
    is_implicit_step({}),
    "Empty hash"
);

ok(
    is_implicit_step({keys => []}),
    "Empty hash keys"
);

ok(
    ! is_implicit_step({keys => ['a']}),
    "Explicit hash step"
);

ok(
    ! is_implicit_step({keys => ['a'], regs => []}),
    "Empty hash regs"
);

ok(
    is_implicit_step({keys => ['a'], regs => [qr/abc/]}),
    "Hash regs"
);

ok(
    is_implicit_step(sub{}),
    "Filter"
);


