use strict;
use warnings;
use Test::More tests => 2;
use Test::NoWarnings;

use syntax 'try';

try {
    exit 0;
}
catch ($e) {
    fail("This should not be called");
}
finally {
    ok("This must be called");
}
