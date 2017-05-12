#!/usr/bin/perl
use strict;
use warnings;

use Test::More;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{# called()

    my $mock = Mock::Sub->new;
    my $test = $mock->mock('One::foo');

    is ($test->called, 0, "called() before a call is correct");

    Two::test;
    is ($test->called, 1, "called() is 1 after one call");

    Two::test;
    is ($test->called, 1, "called() is still 1 after two calls");

    $test->unmock;
    is ($test->called, 0, "after unmock, called() is 0");

    $test->remock('One::foo');

    Two::test;
    is ($test->called, 1, "after re-mock, called is 1 again");


}

done_testing();
