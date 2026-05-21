package TheClass;
use v5.12;
use strict;
use warnings;

use Moo;
use TheParameterizedRole;

TheParameterizedRole->apply_roles_to_target(
    [   { attribute => 'foo', method => 'xxx' },
        { attribute => 'bar', method => 'yyy' }
    ]
);

1;
