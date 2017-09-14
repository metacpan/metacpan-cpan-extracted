
use 5.018;
use Test::More;

BEGIN {
    *bar::is = *is;
}

use Sub::Inject;

# From t/op/lexsub.t

sub bar::foo {43}

{

    BEGIN {
        Sub::Inject::sub_inject( 'foo', sub {44} );
    }

    isnt \&::foo, \&foo, 'state sub is not stored in the package';
    is foo, 44, 'calling state sub from same package';
    is &foo, 44, 'calling state sub from same package (amper)';

    package bar;
    is foo, 44, 'calling state sub from another package';
    is &foo, 44, 'calling state sub from another package (amper)';
}

package bar;
is foo, 43, 'our sub falling out of scope';
is &foo, 43, 'our sub falling out of scope (called via amper)';

package main;
done_testing;

