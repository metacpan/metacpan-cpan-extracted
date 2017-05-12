use strict;
use warnings;

use Test::More;

BEGIN {
    $ENV{PV_TEST_PERL}                  = 1;
    $ENV{PV_WARN_FAILED_IMPLEMENTATION} = 1;
}

use Module::Implementation 0.04 ();
use Params::Validate;

is(
    Module::Implementation::implementation_for('Params::Validate'),
    'PP',
    'PP implementation is loaded when env var is set'
);

done_testing();
