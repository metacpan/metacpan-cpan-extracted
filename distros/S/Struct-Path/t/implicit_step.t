#!perl -T

use 5.006;
use strict;
use warnings;
use Test::More tests => 8;

use Struct::Path qw(implicit_step);

ok(
    implicit_step([]),
    "Empty array"
);

ok(
    ! implicit_step([1,2,3]),
    "Explicit array items"
);

ok(
    implicit_step({}),
    "Empty hash"
);

ok(
    implicit_step({K => []}),
    "Empty hash keys"
);

ok(
    ! implicit_step({K => ['a']}),
    "Explicit hash step"
);

ok(
    ! implicit_step({K => ['a'], R => []}),
    "Empty hash regs"
);

ok(
    implicit_step({K => ['a'], R => [qr/abc/]}),
    "Hash regs"
);

ok(
    implicit_step(sub{}),
    "Filter"
);


