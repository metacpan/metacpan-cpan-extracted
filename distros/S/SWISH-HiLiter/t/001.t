use strict;
use Test::More tests => 1;

SKIP: {

    eval { require SWISH::API };

    if ($@) {
        diag "SWISH::API v0.04 or higher required";
        skip "SWISH::API is not installed - can't test SWISH::HiLiter", 1;
    }

    skip "SWISH::API 0.04 or higher required", 1
        unless ( $SWISH::API::VERSION && $SWISH::API::VERSION gt '0.03' );

    require_ok('SWISH::HiLiter');
    diag("Testing SWISH::HiLiter version $SWISH::HiLiter::VERSION");

}
