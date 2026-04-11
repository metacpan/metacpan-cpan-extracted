#!/usr/bin/env perl
# Test Numeric::Vector comparison operations: eq, ne, lt, le, gt, ge
use strict;
use warnings;
use Test2::Bundle::Numerical qw(:all);
use Numeric::Vector;

if (is_quadmath()) {
    diag("Testing with quadmath (128-bit precision)");
}

subtest 'eq - element-wise equality' => sub {
    my $a = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $b = Numeric::Vector::new([1, 2, 0, 4, 5]);

    my $result = $a->eq($b);
    is($result->len, 5, 'eq result has correct length');

    my @vals = @{$result->to_array};
    is($vals[0], 1, 'eq: 1 == 1');
    is($vals[1], 1, 'eq: 2 == 2');
    is($vals[2], 0, 'eq: 3 != 0');
    is($vals[3], 1, 'eq: 4 == 4');
    is($vals[4], 1, 'eq: 5 == 5');
};

subtest 'eq with scalar' => sub {
    my $v = Numeric::Vector::new([1, 2, 2, 3, 2]);
    my $result = $v->eq(2);

    my @vals = @{$result->to_array};
    is($vals[0], 0, 'eq scalar: 1 != 2');
    is($vals[1], 1, 'eq scalar: 2 == 2');
    is($vals[2], 1, 'eq scalar: 2 == 2');
    is($vals[3], 0, 'eq scalar: 3 != 2');
    is($vals[4], 1, 'eq scalar: 2 == 2');
};

subtest 'ne - element-wise inequality' => sub {
    my $a = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $b = Numeric::Vector::new([1, 2, 0, 4, 5]);

    my $result = $a->ne($b);
    my @vals = @{$result->to_array};
    is($vals[0], 0, 'ne: 1 == 1');
    is($vals[1], 0, 'ne: 2 == 2');
    is($vals[2], 1, 'ne: 3 != 0');
    is($vals[3], 0, 'ne: 4 == 4');
    is($vals[4], 0, 'ne: 5 == 5');
};

subtest 'ne with scalar' => sub {
    my $v = Numeric::Vector::new([1, 2, 3]);
    my $result = $v->ne(2);

    my @vals = @{$result->to_array};
    is($vals[0], 1, 'ne scalar: 1 != 2');
    is($vals[1], 0, 'ne scalar: 2 == 2');
    is($vals[2], 1, 'ne scalar: 3 != 2');
};

subtest 'lt - element-wise less than' => sub {
    my $a = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $b = Numeric::Vector::new([2, 2, 2, 2, 2]);

    my $result = $a->lt($b);
    my @vals = @{$result->to_array};
    is($vals[0], 1, 'lt: 1 < 2');
    is($vals[1], 0, 'lt: 2 < 2 is false');
    is($vals[2], 0, 'lt: 3 < 2 is false');
    is($vals[3], 0, 'lt: 4 < 2 is false');
    is($vals[4], 0, 'lt: 5 < 2 is false');
};

subtest 'lt with scalar' => sub {
    my $v = Numeric::Vector::new([1, 3, 5, 7, 9]);
    my $result = $v->lt(5);

    my @vals = @{$result->to_array};
    is($vals[0], 1, 'lt scalar: 1 < 5');
    is($vals[1], 1, 'lt scalar: 3 < 5');
    is($vals[2], 0, 'lt scalar: 5 < 5 is false');
    is($vals[3], 0, 'lt scalar: 7 < 5 is false');
    is($vals[4], 0, 'lt scalar: 9 < 5 is false');
};

subtest 'le - element-wise less than or equal' => sub {
    my $a = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $b = Numeric::Vector::new([2, 2, 2, 2, 2]);

    my $result = $a->le($b);
    my @vals = @{$result->to_array};
    is($vals[0], 1, 'le: 1 <= 2');
    is($vals[1], 1, 'le: 2 <= 2');
    is($vals[2], 0, 'le: 3 <= 2 is false');
    is($vals[3], 0, 'le: 4 <= 2 is false');
    is($vals[4], 0, 'le: 5 <= 2 is false');
};

subtest 'le with scalar' => sub {
    my $v = Numeric::Vector::new([1, 3, 5, 7, 9]);
    my $result = $v->le(5);

    my @vals = @{$result->to_array};
    is($vals[0], 1, 'le scalar: 1 <= 5');
    is($vals[1], 1, 'le scalar: 3 <= 5');
    is($vals[2], 1, 'le scalar: 5 <= 5');
    is($vals[3], 0, 'le scalar: 7 <= 5 is false');
    is($vals[4], 0, 'le scalar: 9 <= 5 is false');
};

subtest 'gt - element-wise greater than' => sub {
    my $a = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $b = Numeric::Vector::new([2, 2, 2, 2, 2]);

    my $result = $a->gt($b);
    my @vals = @{$result->to_array};
    is($vals[0], 0, 'gt: 1 > 2 is false');
    is($vals[1], 0, 'gt: 2 > 2 is false');
    is($vals[2], 1, 'gt: 3 > 2');
    is($vals[3], 1, 'gt: 4 > 2');
    is($vals[4], 1, 'gt: 5 > 2');
};

subtest 'gt with scalar' => sub {
    my $v = Numeric::Vector::new([1, 3, 5, 7, 9]);
    my $result = $v->gt(5);

    my @vals = @{$result->to_array};
    is($vals[0], 0, 'gt scalar: 1 > 5 is false');
    is($vals[1], 0, 'gt scalar: 3 > 5 is false');
    is($vals[2], 0, 'gt scalar: 5 > 5 is false');
    is($vals[3], 1, 'gt scalar: 7 > 5');
    is($vals[4], 1, 'gt scalar: 9 > 5');
};

subtest 'ge - element-wise greater than or equal' => sub {
    my $a = Numeric::Vector::new([1, 2, 3, 4, 5]);
    my $b = Numeric::Vector::new([2, 2, 2, 2, 2]);

    my $result = $a->ge($b);
    my @vals = @{$result->to_array};
    is($vals[0], 0, 'ge: 1 >= 2 is false');
    is($vals[1], 1, 'ge: 2 >= 2');
    is($vals[2], 1, 'ge: 3 >= 2');
    is($vals[3], 1, 'ge: 4 >= 2');
    is($vals[4], 1, 'ge: 5 >= 2');
};

subtest 'ge with scalar' => sub {
    my $v = Numeric::Vector::new([1, 3, 5, 7, 9]);
    my $result = $v->ge(5);

    my @vals = @{$result->to_array};
    is($vals[0], 0, 'ge scalar: 1 >= 5 is false');
    is($vals[1], 0, 'ge scalar: 3 >= 5 is false');
    is($vals[2], 1, 'ge scalar: 5 >= 5');
    is($vals[3], 1, 'ge scalar: 7 >= 5');
    is($vals[4], 1, 'ge scalar: 9 >= 5');
};

subtest 'comparison with negative values' => sub {
    my $a = Numeric::Vector::new([-3, -1, 0, 1, 3]);
    my $result = $a->gt(0);

    my @vals = @{$result->to_array};
    is($vals[0], 0, 'gt 0: -3 > 0 is false');
    is($vals[1], 0, 'gt 0: -1 > 0 is false');
    is($vals[2], 0, 'gt 0: 0 > 0 is false');
    is($vals[3], 1, 'gt 0: 1 > 0');
    is($vals[4], 1, 'gt 0: 3 > 0');
};

subtest 'comparison with floats' => sub {
    my $a = Numeric::Vector::new([1.5, 2.5, 3.5]);
    my $b = Numeric::Vector::new([1.5, 2.0, 4.0]);

    my $result = $a->eq($b);
    my @vals = @{$result->to_array};
    is($vals[0], 1, 'eq float: 1.5 == 1.5');
    is($vals[1], 0, 'eq float: 2.5 != 2.0');
    is($vals[2], 0, 'eq float: 3.5 != 4.0');
};

subtest 'chained comparisons' => sub {
    my $v = Numeric::Vector::new([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);

    # Find values > 3 AND <= 7
    my $gt3 = $v->gt(3);
    my $le7 = $v->le(7);
    my $in_range = $gt3->mul($le7);  # element-wise AND via multiplication

    my @vals = @{$in_range->to_array};
    my @expected = (0, 0, 0, 1, 1, 1, 1, 0, 0, 0);
    is_deeply(\@vals, \@expected, 'chained comparison: 3 < x <= 7');
};

done_testing();
