use strict;
use warnings;

use lib 't/lib';

use Test::More 0.96;
use Test::Specio qw( test_constraint );

use Specio::Library::Numeric;

my %tests = (
    PositiveNum => {
        accept => [ 1, 2, 3, 2**32, 1.2, 0.000000000000001, 1e20, 1.1e10 ],
        reject => [
            0, -1, -1 * ( 2**32 ), -1.2, -0.000000000000001, -1e19, -1.1e10
        ],
    },
    PositiveOrZeroNum => {
        accept => [ 0, 1, 2, 3, 2**32, 1.2, 0.000000000000001, 1e20, 1.1e10 ],
        reject =>
            [ -1, -1 * ( 2**32 ), -1.2, -0.000000000000001, -1e19, -1.1e10 ],
    },
    PositiveInt => {
        accept => [ 1, 2, 3, 2**32, 1e20 ],
        reject => [ 0, -1, -1 * ( 2**32 ), -1.2, -0.000000000000001, 1.1 ],
    },
    PositiveOrZeroInt => {
        accept => [ 0, 1, 2, 3, 2**32, 1e20 ],
        reject => [ -1, -1 * ( 2**32 ), -1.2, -0.000000000000001, 1.1 ],
    },
    NegativeNum => {
        accept =>
            [ -1, -1 * ( 2**32 ), -1.2, -0.000000000000001, -1e19, -1.1e10 ],
        reject => [ 0, 1, 2, 3, 2**32, 1.2, 0.000000000000001, 1e20, 1.1e10 ],
    },
    NegativeOrZeroNum => {
        accept => [
            0, -1, -1 * ( 2**32 ), -1.2, -0.000000000000001, -1e19, -1.1e10
        ],
        reject => [ 1, 2, 3, 2**32, 1.2, 0.000000000000001, 1e20, 1.1e10 ],
    },
    NegativeInt => {
        accept => [ -1, -2, -3, -1 * ( 2**32 ), -1e20 ],
        reject => [ 0, 1, 2**32, -1.2, -0.000000000000001, 1.1, 1.1e10 ],
    },
    NegativeOrZeroInt => {
        accept => [ 0, -1, -2, -3, -1 * ( 2**32 ), -1e20 ],
        reject => [ 1, 2**32, -1.2, -0.000000000000001, 1.1, 1.1e10 ],
    },
    SingleDigit => {
        accept => [ -9 .. 9 ],
        reject => [ 10, -10, 1.1, -1.1 ],
    },
);

for my $name ( sort keys %tests ) {
    test_constraint( $name, $tests{$name} );
}

done_testing();
