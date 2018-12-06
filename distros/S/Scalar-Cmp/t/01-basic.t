#!perl

use 5.010;
use strict;
use warnings;
use Test::More 0.98;

use Scalar::Cmp qw(cmp_scalar cmpnum_scalar cmpstrornum_scalar);

subtest cmp_scalar => sub {
    is(cmp_scalar(undef, undef), 0);
    is(cmp_scalar(undef, 1), -1);
    is(cmp_scalar(1, undef), 1);
    is(cmp_scalar(undef, []), -1);
    is(cmp_scalar([], undef), 1);

    is(cmp_scalar(1, []), 2);
    is(cmp_scalar([], 1), 2);
    is(cmp_scalar([], []), 2);
    is(cmp_scalar([], {}), 2);
    is(cmp_scalar(1, \1), 2);

    is(cmp_scalar(\undef, \undef), 0);

    my $r;
    $r = \undef; is(cmp_scalar($r, $r), 0);
    $r = []; is(cmp_scalar($r, $r), 0);

    is(cmp_scalar(1, 2), -1);
    is(cmp_scalar(1, 1), 0);
    is(cmp_scalar("a", "A"), 1);
    is(cmp_scalar("1.0", 1), 1);
    is(cmp_scalar("A", "A"), 0);
};

subtest cmpnum_scalar => sub {
    is(cmpnum_scalar(undef, undef), 0);
    is(cmpnum_scalar(undef, 1), -1);
    is(cmpnum_scalar(1, undef), 1);
    is(cmpnum_scalar(undef, []), -1);
    is(cmpnum_scalar([], undef), 1);

    is(cmpnum_scalar(1, []), 2);
    is(cmpnum_scalar([], 1), 2);
    is(cmpnum_scalar([], []), 2);
    is(cmpnum_scalar([], {}), 2);
    is(cmpnum_scalar(1, \1), 2);

    is(cmpnum_scalar(\undef, \undef), 0);

    my $r;
    $r = \undef; is(cmpnum_scalar($r, $r), 0);
    $r = []; is(cmpnum_scalar($r, $r), 0);

    is(cmpnum_scalar(1, 2), -1);
    is(cmpnum_scalar(1, 1), 0);
    #is(cmpnum_scalar("a", "A"), 1); # warnings
    is(cmpnum_scalar("1.0", 1), 0);
    #is(cmpnum_scalar("A", "A"), 0);  # warnings
};

subtest cmpstrornum_scalar => sub {
    is(cmpstrornum_scalar(undef, undef), 0);
    is(cmpstrornum_scalar(undef, 1), -1);
    is(cmpstrornum_scalar(1, undef), 1);
    is(cmpstrornum_scalar(undef, []), -1);
    is(cmpstrornum_scalar([], undef), 1);

    is(cmpstrornum_scalar(1, []), 2);
    is(cmpstrornum_scalar([], 1), 2);
    is(cmpstrornum_scalar([], []), 2);
    is(cmpstrornum_scalar([], {}), 2);
    is(cmpstrornum_scalar(1, \1), 2);

    is(cmpstrornum_scalar(\undef, \undef), 0);

    my $r;
    $r = \undef; is(cmpstrornum_scalar($r, $r), 0);
    $r = []; is(cmpstrornum_scalar($r, $r), 0);

    is(cmpstrornum_scalar(1, 2), -1);
    is(cmpstrornum_scalar(1, 1), 0);
    is(cmpstrornum_scalar("a", "A"), 1);
    is(cmpstrornum_scalar("1.0", 1), 0);
    is(cmpstrornum_scalar("A", "A"), 0);
};

DONE_TESTING:
done_testing;
