#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

plan tests => 10;

use_ok('Telemetry::Any');

subtest simple => sub {
    plan tests => 8;

    my $report = _process()->report();

    like( $report, qr/0000 -> 0001 .* INIT -> A/, "step 0" );
    like( $report, qr/0001 -> 0002 .* A -> B/,    "step 1" );
    like( $report, qr/0002 -> 0003 .* B -> A/,    "step 2" );
    like( $report, qr/0003 -> 0004 .* A -> B/,    "step 3" );
    like( $report, qr/0004 -> 0005 .* B -> A/,    "step 4" );
    like( $report, qr/0005 -> 0006 .* A -> B/,    "step 5" );
    like( $report, qr/0006 -> 0007 .* B -> C/,    "step 6" );
    unlike( $report, qr/0007 -> 0008/, "no step 7" );
};

subtest collapse => sub {
    plan tests => 5;

    my $report = _process()->report( collapse => 1 );

    like( $report, qr/ + 3 .* A -> B\n/,                      "A -> B" );
    like( $report, qr/ + 1 .* B -> C\n/,                      "B -> C" );
    like( $report, qr/ + 2 .* B -> A\n/,                      "B -> A" );
    like( $report, qr/ + 1 .* INIT -> A/,                     "INIT -> A" );
    like( $report, qr/A -> B.* B -> C.* B -> A.* INIT -> A/s, "order by time descending" );
};

subtest collapse_sort => sub {
    plan tests => 5;

    my $report = _process()->report( collapse => 1, sort_by => 'count' );

    like( $report, qr/ + 3 .* A -> B\n/,  "A -> B" );
    like( $report, qr/ + 1 .* B -> C/,    "B -> C" );
    like( $report, qr/ + 2 .* B -> A\n/,  "B -> A" );
    like( $report, qr/ + 1 .* INIT -> A/, "INIT -> A" );

    # If we sort by count there are two possible versions of the report
    # that are correct (because B -> C and INIT -> A both only happened one time
    # so we don't care which one shows up first on the report.
    my $test = (
               ( $report =~ /A -> B.* B -> A.* B -> C.* INIT -> A/s )
            or ( $report =~ /A -> B.* B -> A.* INIT -> A.* B -> C/s )
    );

    ok( $test, "sort by count" ) or diag $report;
};

subtest simple_reset => sub {
    plan tests => 8;

    my $t      = _process()->reset();
    my $report = _process_work($t)->report();

    unlike( $report, qr/INIT/, "no INIT" );
    like( $report, qr/0000 -> 0001 .* A -> B/, "step 0" );
    like( $report, qr/0001 -> 0002 .* B -> A/, "step 1" );
    like( $report, qr/0002 -> 0003 .* A -> B/, "step 2" );
    like( $report, qr/0003 -> 0004 .* B -> A/, "step 3" );
    like( $report, qr/0004 -> 0005 .* A -> B/, "step 4" );
    like( $report, qr/0005 -> 0006 .* B -> C/, "step 5" );
    unlike( $report, qr/0006 -> 0007/, "no step 6" );
};

subtest stats => sub {
    plan tests => 24;

    my $t = _process();

    my ( $time, $percent, $count );

    ok( ( $time, $percent, $count ) = $t->get_stats( "A", "B" ), "get_stats('A', 'B')" );

    cmp_ok( $time,    '>=', 0.6, '$time' );
    cmp_ok( $time,    '<=', 0.8, '$time' );
    cmp_ok( $percent, '>=', 60,  '$percent' );
    cmp_ok( $percent, '<=', 70,  '$percent' );
    cmp_ok( $count,   '==', 3,   '$count' );

    ok( ( $time, $percent, $count ) = $t->get_stats( "B", "A" ), "get_stats('B', 'A')" );

    cmp_ok( $time,    '>=', 0,    '$time' );
    cmp_ok( $time,    '<=', 0.15, '$time' );
    cmp_ok( $percent, '>=', 0,    '$percent' );
    cmp_ok( $percent, '<=', 10,   '$percent' );
    cmp_ok( $count,   '==', 2,    '$count' );

    ok( ( $time, $percent, $count ) = $t->get_stats( "B", "C" ), "get_stats('B', 'C')" );

    cmp_ok( $time,    '>=', 0.2, '$time' );
    cmp_ok( $time,    '<=', 0.4, '$time' );
    cmp_ok( $percent, '>=', 25,  '$percent' );
    cmp_ok( $percent, '<=', 32,  '$percent' );
    cmp_ok( $count,   '==', 1,   '$count' );

    ok( ( $time, $percent, $count ) = $t->get_stats( "INIT", "A" ), "get_stats('INIT', 'A')" );

    cmp_ok( $time,    '>=', 0,   '$time' );
    cmp_ok( $time,    '<=', 0.1, '$time' );
    cmp_ok( $percent, '>=', 0,   '$percent' );
    cmp_ok( $percent, '<=', 5,   '$percent' );
    cmp_ok( $count,   '==', 1,   '$count' );
};

subtest table => sub {
    plan tests => 11;

    my $report = _process()->report( format => 'table' );

    like( $report, qr/Total time/,                    "Total time" );
    like( $report, qr/Interval      Time    Percent/, "header" );
    like( $report, qr/-{46}/,                         "line" );
    like( $report, qr/0000 -> 0001 .* INIT -> A/,     "step 0" );
    like( $report, qr/0001 -> 0002 .* A -> B/,        "step 1" );
    like( $report, qr/0002 -> 0003 .* B -> A/,        "step 2" );
    like( $report, qr/0003 -> 0004 .* A -> B/,        "step 3" );
    like( $report, qr/0004 -> 0005 .* B -> A/,        "step 4" );
    like( $report, qr/0005 -> 0006 .* A -> B/,        "step 5" );
    like( $report, qr/0006 -> 0007 .* B -> C/,        "step 6" );
    unlike( $report, qr/0007 -> 0008/, "no step 7" );
};

subtest collapse_table => sub {
    plan tests => 8;

    my $report = _process()->report( collapse => 1, format => 'table' );

    like( $report, qr/Total time/,                            "Total time" );
    like( $report, qr/Count     Time    Percent/,             "header" );
    like( $report, qr/-{46}/,                                 "line" );
    like( $report, qr/\n + 3 .* A -> B/,                      "A -> B" );
    like( $report, qr/\n + 1 .* B -> C/,                      "B -> C" );
    like( $report, qr/\n + 2 .* B -> A/,                      "B -> A" );
    like( $report, qr/\n + 1 .* INIT -> A/,                   "INIT -> A" );
    like( $report, qr/A -> B.* B -> C.* B -> A.* INIT -> A/s, "order by time descending" );
};

subtest simple_with_any_labels => sub {
    plan tests => 7;

    my $report = _process()->report( labels => [ [ 'INIT', 'B' ], [ 'INIT', 'C' ], [ 'A', 'B' ], [ 'A', 'C' ], ], );

    like( $report, qr/0000 -> 0007 .* INIT -> C/, "step 1" );
    like( $report, qr/0000 -> 0002 .* INIT -> B/, "step 2" );
    like( $report, qr/0001 -> 0002 .* A -> B/,    "step 3" );
    like( $report, qr/0005 -> 0007 .* A -> C/,    "step 4" );
    like( $report, qr/0003 -> 0004 .* A -> B/,    "step 5" );
    like( $report, qr/0005 -> 0006 .* A -> B/,    "step 6" );
    unlike( $report, qr/0002 -> 0003/, "no step 7" );
};

subtest collapse_with_any_labels => sub {
    plan tests => 5;

    my $report = _process()->report(
        collapse => 1,
        labels   => [ [ 'INIT', 'B' ], [ 'INIT', 'C' ], [ 'A', 'B' ], [ 'A', 'C' ], ],
    );

    like( $report, qr/ + 1 .* INIT -> C\n/, "INIT -> C" );
    like( $report, qr/ + 3 .* A -> B\n/,    "A -> B" );
    like( $report, qr/ + 1 .* INIT -> B/,   "INIT -> B" );
    like( $report, qr/ + 1 .* A -> C/,      "A -> C" );

    like( $report, qr/ INIT -> C.* A -> B.* INIT -> B.* A -> C/s, "order by time descending" );
};

#@returns Telemetry::Any
sub _process {
    my $t;

    $t = _process_init();
    $t = _process_work($t);

    return $t;
}

sub _process_init {

    my $t = Telemetry::Any->new();

    return $t;
}

#@returns Telemetry::Any
sub _process_work {

    #@type Telemetry::Any
    my ($t) = @_;

    $t->mark("A");

    ## do some more work
    select( undef, undef, undef, 0.7 );
    $t->mark("B");

    ## do some work
    select( undef, undef, undef, 0.05 );
    $t->mark("A");
    $t->mark("B");
    $t->mark("A");
    $t->mark("B");

    ## do some more work
    select( undef, undef, undef, 0.3 );
    $t->mark("C");

    return $t;
}
