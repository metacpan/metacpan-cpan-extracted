#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 8;

use lib 't/data';

BEGIN {
    use_ok('Two');
    use_ok('Mock::Sub');
};

{# called_count()

    my $mock = Mock::Sub->new;
    my $test = $mock->mock('One::foo');

    Two::test;
    is ($test->called_count, 1, "does the right thing after one call");

    Two::test;
    Two::test;
    Two::test;
    Two::test;
    is ($test->called_count, 5, "does the right thing after five calls");

    $test->reset;

    is ($test->called_count, 0, "does the right thing after reset");

    Two::test;

    is ($test->called_count, 1, "does the right thing after reset, and one run");

    $test->unmock;
    is ($test->called_count, 0, "does the right thing after unmock");

    $test->remock;
    Two::test;
    is ($test->called_count, 1, "does the right thing after re-mock");
}

