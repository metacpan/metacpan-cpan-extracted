use strict;
use warnings;

use Test::More;
use Test::Approximate;
use Test::Builder::Tester;

is_approx(1, 1, 'first', '1%');
is_approx(1, 1.00001, 'second', '1%');
is_approx(3.1415926, 3.1415, 'third', '1%');
is_approx(0.0001001, '1e-04', 'str vs num', '1%');
is_approx('str', 'str', 'str vs str', '1%');

{
    test_out('not ok 1 - number');
    test_fail(+1);
    is_approx(11, 10, 'number', '1%');
    test_diag('  test: number');
    test_diag('  error: diff 10% is not under tolerance 1%');
    test_test('number not approx');
}

done_testing;
