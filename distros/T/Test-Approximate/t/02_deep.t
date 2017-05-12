use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Approximate;
use Test::Builder::Tester;

my $got = [ 1.00001, 2, 3, 4 ];
my $expect = [ 1, 2, 3, 4 ];
cmp_deeply($got, approx($expect, '1%'), 'array');

$got = { a => 1, b => 1e-3, c => [ 1.1, 2.5, 5, 1e-9 ] };
$expect = { a => 1.0001, b => 1e-03, c => [ 1.1, 2.5, 5, 1.00001e-9 ] };
cmp_deeply( $got, approx($expect, '0.01%'), 'hash mix array');

$got = [ 1, 2, 'string'];
$expect = [ 0.999, 2.001, 'string'];
cmp_deeply( $got, approx($expect, '1%'), 'array element is str');

{
    $got = { a => 1, b => 1e-3, c => [ 1.1, 2.5, 5, 1e-9 ] };
    $expect = { a => 1.01, b => 1e-03, c => [ 1.1, 2.5, 5, 1.00001e-9 ] };
    test_out('not ok 1 - hash mix array');
    test_fail(+1);
    cmp_deeply( $got, approx($expect, '0.01%'), 'hash mix array');
    test_diag('Comparing $data->{"a"}');
    test_diag('     got : 1');
    test_diag('expected : 1.01');
    test_test('not under tolerance');

}

{
    $got = [ 1, 2, 'strign'];
    $expect = [ 0.999, 2.001, 'string'];
    test_out('not ok 1 - array element is str');
    test_fail(+1);
    cmp_deeply( $got, approx($expect, '1%'), 'array element is str');
    test_diag('Comparing $data->[2]');
    test_diag('     got : strign');
    test_diag('expected : string');
    test_test('str should be equal');

}

done_testing;
