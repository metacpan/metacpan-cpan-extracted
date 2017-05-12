use strict;
use warnings;

use Test::More;

BEGIN {
    $ENV{PARAMS_VALIDATE_IMPLEMENTATION} = 'XS';
    $ENV{PV_WARN_FAILED_IMPLEMENTATION} = 1;
}

use Params::Validate qw( validate SCALAR );

eval { foo( { a => 1 } ) };

ok(1, 'did not segfault');

done_testing();

sub foo {
    validate(
        @_,
        {
            a => { type => SCALAR, depends => ['%s%s%s'] },
        }
    );
}
