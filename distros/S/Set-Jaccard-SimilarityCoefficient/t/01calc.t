# -*- mode: cperl; -*-
# ------ basic require/use testing

use utf8;
use autodie;
use strict;
use warnings;
use lib 'lib';
use Test::Most tests => 19;
use Set::Jaccard::SimilarityCoefficient;
use Time::gmtime;
use Try::Tiny;

my $res;
my $exception_msg = undef;
my $got_exception = undef;

try {
    $res = Set::Jaccard::SimilarityCoefficient::calc();
} catch {
    $exception_msg = $_;
    $got_exception++;
};
is($got_exception, 1, 'missing set A - threw exception');
like(
    $exception_msg,
    qr{must have either ArrayRef or Set::Scalar value for set A},
    'missing set A - threw correct exception'
);

$exception_msg = undef;
$got_exception = undef;

try {
    $res = Set::Jaccard::SimilarityCoefficient::calc([]);
} catch {
    $exception_msg = $_;
    $got_exception++;
};
is($got_exception, 1, 'missing set B - threw exception');
like(
    $exception_msg,
    qr{must have either ArrayRef or Set::Scalar value for set B},
    'missing set B - threw correct exception'
);

$exception_msg = undef;
$got_exception = undef;

try {
    $res = Set::Jaccard::SimilarityCoefficient::calc([], []);
} catch {
    $exception_msg = $_;
    $got_exception++;
};
is($got_exception, 1, '2 empty sets - threw exception');
like(
    $exception_msg,
    qr{\QCannot calculate when size(Union(A B)) == 0\E},
    '2 empty sets - threw correct exception'
);

$exception_msg = undef;
$got_exception = undef;

try {
    $res = Set::Jaccard::SimilarityCoefficient::calc('a', []);
} catch {
    $exception_msg = $_;
    $got_exception++;
};
is($got_exception, 1, 'wrong type for set A - threw exception');
like(
    $exception_msg,
    qr{\Qmust have either ArrayRef or Set::Scalar value for set A\E},
    'wrong type for set A - threw correct exception'
);

$exception_msg = undef;
$got_exception = undef;

try {
    $res = Set::Jaccard::SimilarityCoefficient::calc(['a'], 'b');
} catch {
    $exception_msg = $_;
    $got_exception++;
};
is($got_exception, 1, 'wrong type for set B - threw exception');
like(
    $exception_msg,
    qr{\Qmust have either ArrayRef or Set::Scalar value for set B\E},
    'wrong type for set B - threw correct exception'
);

$exception_msg = undef;
$got_exception = undef;

$res = Set::Jaccard::SimilarityCoefficient::calc(['a'], ['b']);
is($res, 0, 'two disjoint sets of 1 - result = 0');

$res = Set::Jaccard::SimilarityCoefficient::calc(['a', 'c'], ['b', 'd']);
is($res, 0, 'two disjoint sets of many - result = 0');

my $gmtime_a = gmtime();
my $gmtime_b = gmtime();
$res = Set::Jaccard::SimilarityCoefficient::calc(['a', \$gmtime_a], ['b', \$gmtime_b]);
is($res, 0, 'two disjoint sets of many with objects - result = 0');

my $gmtime_c = gmtime();
my $gmtime_d = gmtime();
$res = Set::Jaccard::SimilarityCoefficient::calc(
    [\$gmtime_a, \$gmtime_b],
    [\$gmtime_c, \$gmtime_d]
);
is($res, 0, 'two disjoint sets of many with all objects - result = 0');

$res = Set::Jaccard::SimilarityCoefficient::calc(['a'], ['a']);
is($res, 1, 'two identical sets of 1 - result = 1');

$res = Set::Jaccard::SimilarityCoefficient::calc([\$gmtime_a], [\$gmtime_a]);
is($res, 1, 'two identical sets of 1 with objects - result = 1');

$res = Set::Jaccard::SimilarityCoefficient::calc(['a', 'c'], ['a', 'c']);
is($res, 1, 'two identical sets of many - result = 1');

$res = Set::Jaccard::SimilarityCoefficient::calc(['a', 'c'], ['b', 'c']);
cmp_ok($res - 0.33, '<', 0.01, 'two similar sets of many - result = 0.33...');

$res = Set::Jaccard::SimilarityCoefficient::calc(
    [\$gmtime_a, \$gmtime_c],
    [\$gmtime_b, \$gmtime_c]
);
cmp_ok($res - 0.33, '<', 0.01, 'two similar sets of many with objects - result = 0.33...');
