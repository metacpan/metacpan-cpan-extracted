package TheClass;
use strict;
use warnings;

use Moo;
use TheParameterizedRole;

TheParameterizedRole->apply(
    [
        { attribute => 'foo', method => 'xxx' },
        { attribute => 'bar', method => 'yyy' }
    ]
);

1;
