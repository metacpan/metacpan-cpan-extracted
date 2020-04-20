package UseEventTest;

use strict;
use warnings;

use parent 'EventTest';

use Promise::ES6 ();

# A couple overrides to (hackishly) achieve the goal:

sub _FULL_BACKEND { 'Promise::ES6' }

sub _REQUIRE_BACKEND {
    my ($class) = @_;

    Promise::ES6::use_event( $class->_BACKEND() );
}

1;
