use strict;
use warnings;

use Test::More;

{
    package Example;
    no indirect;
    use Test::More;
    use OpenTracing::DSL qw(:v1);

    my $x = 0;
    trace {
        is(++$x, 1, 'can run code inside the trace block');
    };
    is($x, 1, 'code ran successfully');
}

done_testing;
