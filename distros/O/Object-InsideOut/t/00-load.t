use strict;
use warnings;

use Test::More 'tests' => 1;

package My::Class; {
    BEGIN {
        Test::More::use_ok('Object::InsideOut');
    }
}

package main;

if ($Object::InsideOut::VERSION) {
    diag('Testing Object::InsideOut ' . $Object::InsideOut::VERSION);
}

exit(0);

# EOF
