#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical qw(:all);

BEGIN {
    eval { require Test::LeakTrace };
    plan skip_all => 'Test::LeakTrace required' if $@;
}
use Test::LeakTrace;

use Numeric::Vector;

# Warmup
for (1..10) {
    my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);
    $v->sum;
    $v->min;
    $v->max;
}

# ============================================
# Math functions
# ============================================

subtest 'abs no leak' => sub {
    no_leaks_ok {
        my $v = Numeric::Vector::new([-1, 2, -3, 4, -5]);
        my $r = $v->abs;
    } 'abs does not leak';
};

subtest 'sqrt no leak' => sub {
    no_leaks_ok {
        my $v = Numeric::Vector::new([1, 4, 9, 16, 25]);
        my $r = $v->sqrt;
    } 'sqrt does not leak';
};

subtest 'pow no leak' => sub {
    no_leaks_ok {
        my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);
        my $r = $v->pow(2);
    } 'pow does not leak';
};

subtest 'exp no leak' => sub {
    no_leaks_ok {
        my $v = Numeric::Vector::new([0, 1, 2]);
        my $r = $v->exp;
    } 'exp does not leak';
};

subtest 'log no leak' => sub {
    no_leaks_ok {
        my $v = Numeric::Vector::new([1, 2.71828, 10]);
        my $r = $v->log;
    } 'log does not leak';
};

subtest 'sin/cos/tan no leak' => sub {
    no_leaks_ok {
        my $v = Numeric::Vector::new([0, 0.5, 1.0, 1.5]);
        my $s = $v->sin;
        my $c = $v->cos;
        my $t = $v->tan;
    } 'sin/cos/tan does not leak';
};

# ============================================
# Statistical reductions
# ============================================

subtest 'min/max no leak' => sub {
    no_leaks_ok {
        my $v = Numeric::Vector::new([5, 3, 8, 1, 9, 2]);
        for (1..100) {
            my $min = $v->min;
            my $max = $v->max;
        }
    } 'min/max does not leak';
};

subtest 'mean no leak' => sub {
    no_leaks_ok {
        my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);
        for (1..100) {
            my $m = $v->mean;
        }
    } 'mean does not leak';
};

subtest 'variance no leak' => sub {
    no_leaks_ok {
        my $v = Numeric::Vector::new([2, 4, 4, 4, 5, 5, 7, 9]);
        for (1..100) {
            my $var = $v->variance;
        }
    } 'variance does not leak';
};

subtest 'std no leak' => sub {
    no_leaks_ok {
        my $v = Numeric::Vector::new([2, 4, 4, 4, 5, 5, 7, 9]);
        for (1..100) {
            my $s = $v->std;
        }
    } 'std does not leak';
};

subtest 'argmin/argmax no leak' => sub {
    no_leaks_ok {
        my $v = Numeric::Vector::new([5, 3, 8, 1, 9, 2]);
        for (1..100) {
            my $imin = $v->argmin;
            my $imax = $v->argmax;
        }
    } 'argmin/argmax does not leak';
};

subtest 'median no leak' => sub {
    no_leaks_ok {
        my $v = Numeric::Vector::new([3, 1, 4, 1, 5, 9, 2, 6]);
        for (1..50) {
            my $m = $v->median;
        }
    } 'median does not leak';
};

# ============================================
# Slicing and copying
# ============================================

subtest 'slice no leak' => sub {
    no_leaks_ok {
        my $v = Numeric::Vector::new([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
        for (1..100) {
            my $s = $v->slice(2, 5);
        }
    } 'slice does not leak';
};

subtest 'copy no leak' => sub {
    no_leaks_ok {
        my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);
        for (1..100) {
            my $c = $v->copy;
        }
    } 'copy does not leak';
};

subtest 'concat no leak' => sub {
    no_leaks_ok {
        my $a = Numeric::Vector::new([1, 2, 3]);
        my $b = Numeric::Vector::new([4, 5, 6]);
        for (1..100) {
            my $c = $a->concat($b);
        }
    } 'concat does not leak';
};

subtest 'reverse no leak' => sub {
    no_leaks_ok {
        my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);
        for (1..100) {
            my $r = $v->reverse;
        }
    } 'reverse does not leak';
};

# ============================================
# Cumulative operations
# ============================================

subtest 'cumsum no leak' => sub {
    no_leaks_ok {
        my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);
        for (1..100) {
            my $cs = $v->cumsum;
        }
    } 'cumsum does not leak';
};

subtest 'cumprod no leak' => sub {
    no_leaks_ok {
        my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);
        for (1..100) {
            my $cp = $v->cumprod;
        }
    } 'cumprod does not leak';
};

subtest 'diff no leak' => sub {
    no_leaks_ok {
        my $v = Numeric::Vector::new([1, 2, 4, 7, 11]);
        for (1..100) {
            my $d = $v->diff;
        }
    } 'diff does not leak';
};

# ============================================
# Sorting
# ============================================

subtest 'sort no leak' => sub {
    no_leaks_ok {
        my $v = Numeric::Vector::new([5, 2, 8, 1, 9, 3]);
        for (1..50) {
            my $s = $v->sort;
        }
    } 'sort does not leak';
};

subtest 'argsort no leak' => sub {
    no_leaks_ok {
        my $v = Numeric::Vector::new([5, 2, 8, 1, 9, 3]);
        for (1..50) {
            my $idx = $v->argsort;
        }
    } 'argsort does not leak';
};

# ============================================
# Boolean reductions
# ============================================

subtest 'all/any no leak' => sub {
    no_leaks_ok {
        my $v = Numeric::Vector::new([1, 1, 1, 0, 1]);
        for (1..200) {
            my $a = $v->all;
            my $b = $v->any;
        }
    } 'all/any does not leak';
};

subtest 'count no leak' => sub {
    no_leaks_ok {
        my $v = Numeric::Vector::new([1, 0, 1, 0, 1]);
        for (1..200) {
            my $c = $v->count;
        }
    } 'count does not leak';
};

# ============================================
# Comparison operations
# ============================================

subtest 'eq/ne no leak' => sub {
    no_leaks_ok {
        my $a = Numeric::Vector::new([1, 2, 3, 4, 5]);
        my $b = Numeric::Vector::new([1, 2, 0, 4, 0]);
        for (1..100) {
            my $eq = $a->eq($b);
            my $ne = $a->ne($b);
        }
    } 'eq/ne does not leak';
};

subtest 'lt/le/gt/ge no leak' => sub {
    no_leaks_ok {
        my $a = Numeric::Vector::new([1, 2, 3, 4, 5]);
        my $b = Numeric::Vector::new([3, 3, 3, 3, 3]);
        for (1..50) {
            my $lt = $a->lt($b);
            my $le = $a->le($b);
            my $gt = $a->gt($b);
            my $ge = $a->ge($b);
        }
    } 'lt/le/gt/ge does not leak';
};

# ============================================
# Special value checks
# ============================================

subtest 'isnan/isinf/isfinite no leak' => sub {
    my $inf = 9e999;
    my $nan = $inf - $inf;
    no_leaks_ok {
        my $v = Numeric::Vector::new([1, $nan, $inf, -$inf, 0]);
        for (1..100) {
            my $n = $v->isnan;
            my $i = $v->isinf;
            my $f = $v->isfinite;
        }
    } 'isnan/isinf/isfinite does not leak';
};

# ============================================
# Rounding
# ============================================

subtest 'floor/ceil/round no leak' => sub {
    no_leaks_ok {
        my $v = Numeric::Vector::new([1.2, 2.5, 3.7, -1.2, -2.5]);
        for (1..100) {
            my $f = $v->floor;
            my $c = $v->ceil;
            my $r = $v->round;
        }
    } 'floor/ceil/round does not leak';
};

subtest 'clip no leak' => sub {
    no_leaks_ok {
        my $v = Numeric::Vector::new([1, 5, 10, 15, 20]);
        for (1..100) {
            my $c = $v->clip(5, 15);
        }
    } 'clip does not leak';
};

# ============================================
# Operator overloading
# ============================================

subtest 'operator overloading no leak' => sub {
    no_leaks_ok {
        my $a = Numeric::Vector::new([1, 2, 3]);
        my $b = Numeric::Vector::new([4, 5, 6]);
        for (1..50) {
            my $c = $a + $b;
            my $d = $a - $b;
            my $e = $a * $b;
            my $f = $a / $b;
            my $g = $a + 10;
            my $h = $a * 2;
        }
    } 'operator overloading does not leak';
};

subtest 'compound assignment no leak' => sub {
    no_leaks_ok {
        for (1..50) {
            my $v = Numeric::Vector::new([1, 2, 3]);
            $v += Numeric::Vector::new([1, 1, 1]);
            $v *= 2;
        }
    } 'compound assignment does not leak';
};

# ============================================
# SIMD info
# ============================================

subtest 'simd_info no leak' => sub {
    no_leaks_ok {
        for (1..500) {
            my $info = Numeric::Vector::simd_info();
        }
    } 'simd_info does not leak';
};

# ============================================
# Random
# ============================================

subtest 'random no leak' => sub {
    no_leaks_ok {
        for (1..100) {
            my $v = Numeric::Vector::random(100);
        }
    } 'random does not leak';
};

done_testing();
