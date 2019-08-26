#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Capture::Tiny qw(capture);

plan tests => 6;

use_ok('Telemetry::Any');

subtest simple => sub {
    plan tests => 8;

    my ( $stdout, $stderr, $exit ) = capture {
        my $t = _process();
        $t->report();
    };

    like( $stderr, qr/00 -> 01 .* INIT -> A/, "step 0" );
    like( $stderr, qr/01 -> 02 .* A -> B/,    "step 1" );
    like( $stderr, qr/02 -> 03 .* B -> A/,    "step 2" );
    like( $stderr, qr/03 -> 04 .* A -> B/,    "step 3" );
    like( $stderr, qr/04 -> 05 .* B -> A/,    "step 4" );
    like( $stderr, qr/05 -> 06 .* A -> B/,    "step 5" );
    like( $stderr, qr/06 -> 07 .* B -> C/,    "step 6" );
    unlike( $stderr, qr/07 -> 08/, "no step 7" );
};

subtest collapse => sub {
    plan tests => 5;

    my ( $stdout, $stderr, $exit ) = capture {
        my $t = _process();
        $t->report( collapse => 1 );
    };

    like( $stderr, qr/ + 3 .* A -> B\n/,                      "A -> B" );
    like( $stderr, qr/ + 1 .* B -> C\n/,                      "B -> C" );
    like( $stderr, qr/ + 2 .* B -> A\n/,                      "B -> A" );
    like( $stderr, qr/ + 1 .* INIT -> A\n/,                   "INIT -> A" );
    like( $stderr, qr/A -> B.* B -> C.* B -> A.* INIT -> A/s, "order by time descending" );
};

subtest table => sub {
    plan tests => 11;

    my ( $stdout, $stderr, $exit ) = capture {
        my $t = _process();
        $t->report( format => 'table' );
    };

    like( $stderr, qr/Total time/,                "Total time" );
    like( $stderr, qr/Interval  Time    Percent/, "header" );
    like( $stderr, qr/-{46}/,                     "line" );
    like( $stderr, qr/00 -> 01 .* INIT -> A/,     "step 0" );
    like( $stderr, qr/01 -> 02 .* A -> B/,        "step 1" );
    like( $stderr, qr/02 -> 03 .* B -> A/,        "step 2" );
    like( $stderr, qr/03 -> 04 .* A -> B/,        "step 3" );
    like( $stderr, qr/04 -> 05 .* B -> A/,        "step 4" );
    like( $stderr, qr/05 -> 06 .* A -> B/,        "step 5" );
    like( $stderr, qr/06 -> 07 .* B -> C/,        "step 6" );
    unlike( $stderr, qr/07 -> 08/, "no step 7" );
};

subtest collapse_table => sub {
    plan tests => 8;

    my ( $stdout, $stderr, $exit ) = capture {
        my $t = _process();
        $t->report( collapse => 1, format => 'table' );
    };

    like( $stderr, qr/Total time/,                            "Total time" );
    like( $stderr, qr/Count     Time    Percent/,             "header" );
    like( $stderr, qr/-{46}/,                                 "line" );
    like( $stderr, qr/\n + 3 .* A -> B/,                      "A -> B" );
    like( $stderr, qr/\n + 1 .* B -> C/,                      "B -> C" );
    like( $stderr, qr/\n + 2 .* B -> A/,                      "B -> A" );
    like( $stderr, qr/\n + 1 .* INIT -> A/,                   "INIT -> A" );
    like( $stderr, qr/A -> B.* B -> C.* B -> A.* INIT -> A/s, "order by time descending" );
};

subtest simple_reset => sub {
    plan tests => 8;

    my ( $stdout, $stderr, $exit ) = capture {
        my $t = _process();
        $t->reset();
        $t = _process_work($t);
        $t->report();
    };

    unlike( $stderr, qr/INIT/, "no INIT" );
    like( $stderr, qr/00 -> 01 .* A -> B/, "step 0" );
    like( $stderr, qr/01 -> 02 .* B -> A/, "step 1" );
    like( $stderr, qr/02 -> 03 .* A -> B/, "step 2" );
    like( $stderr, qr/03 -> 04 .* B -> A/, "step 3" );
    like( $stderr, qr/04 -> 05 .* A -> B/, "step 4" );
    like( $stderr, qr/05 -> 06 .* B -> C/, "step 5" );
    unlike( $stderr, qr/06 -> 07/, "no step 6" );
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
