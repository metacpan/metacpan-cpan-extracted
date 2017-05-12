#!/usr/bin/env perl

BEGIN {
    unless ( $ENV{DEVEL_TESTS} ) {
        require Test::More;
        Test::More::plan(
            skip_all => 'Enable DEVEL_TESTS environment variable' );
    }
    my @needs = (
        'Test::More',
        'Data::Dumper qw/Dumper/',
        'List::Util qw(shuffle)',
        'Sort::Key qw(isort)',
        'Sort::Key::Radix',
        'IPC::System::Simple qw/capture/',
        'Benchmark qw/timethese cmpthese/'
    );

    foreach (@needs) {
        eval "use $_";
        plan( skip_all => "$_ required for benchmarks" )
          if $@;
    }
}

use strict;
use warnings;
use v5.10;
use Sort::XS;

my @sets = (

    # very small arrays
    { arrays => 1000, rows => [10] },

    # mixed of common usage
    { arrays => 10, rows => [ 10, 100, 1_000 ] },

    { arrays => 100, rows => [100] },
    { arrays => 100, rows => [1_000] },
    { arrays => 100, rows => [10_000] },
    { arrays => 10,  rows => [100_000] },
    { arrays => 1,   rows => [1_000_000] },
);

foreach my $set (@sets) {

    # generate set of arrays to test
    my @tests;
    my @tests_str;
    my $arrays = $set->{arrays} || 1;
    my @rows = @{ $set->{rows} };

    say "### benchmark with $arrays arrays of ", join( ', ', @rows ), " rows";
    my $first = 0;
    for my $id ( 1 .. $arrays ) {
        for my $nelt (@rows) {
            push @tests, generate_sample($nelt);
            if ( $id == 1 ) {
                push @tests_str, generate_str_sample($nelt);
                $first = $id;
            }
            else {
                my @a = shuffle @{ $tests_str[ $first - 1 ] };
                push @tests_str, \@a;
            }
        }
    }

    # benchmark the tests
    benchmark_integers( \@tests );

    # str
    benchmark_str( \@tests_str );
}

ok(1);
done_testing;

exit;

# helpers

sub generate_sample {
    my ($elt) = shift;

    return [] unless $elt;

    #
    my @reply;
    my $last;
    for my $n ( 1 .. $elt ) {
        push( @reply, ( $reply[$#reply] || 1 ) + int( rand(10) ) );
    }
    @reply = shuffle @reply;

    return \@reply;
}

sub generate_str_sample {
    my $max = shift || 10;
    my @reply;

    say "- generate an array of $max max lines";

    my $cmd = 'find';
    my @output =
      capture( join( ' ', $cmd, '/', '2>&1', '|', 'head', '-n', $max ) );
    foreach my $line (@output) {
        chomp $line;
        my @array = split( '/', $line );
        my $elt = $array[-1];
        next unless defined $elt;
        push @reply, $elt;
    }
    @reply = shuffle @reply;
    return \@reply;
}

sub benchmark_integers {
    my ($set) = @_;
    my @tests = @$set;

    my $count = -2;
    $count = -5 if ( scalar @{ $tests[0] } >= 100_000 );

    cmpthese(
        timethese(
            $count,
            {

                '[int] XS merge' => sub {
                    foreach my $t (@tests) {
                        my $sorted = Sort::XS::merge_sort($t);
                    }
                },

                '[int] XS quick' => sub {
                    foreach my $t (@tests) {
                        my $sorted = Sort::XS::quick_sort($t);
                    }
                },
                '[int] API quick' => sub {
                    foreach my $t (@tests) {
                        my $sorted = xsort($t);
                    }
                },
                '[int] API quick with hash' => sub {
                    foreach my $t (@tests) {
                        my $sorted = xsort(
                            list      => $t,
                            algorithm => 'quick',
                            type      => 'integer'
                        );
                    }
                },

                'void' => sub {
                    foreach my $t (@tests) {
                        my $sorted = Sort::XS::void_sort($t);
                    }
                },

                '[int] heap' => sub {
                    foreach my $t (@tests) {
                        my $sorted = Sort::XS::heap_sort($t);
                    }
                },

                '[int] Perl' => sub {
                    foreach my $t (@tests) {
                        my $sorted = [sort { $a <=> $b } @$t];

                    }
                },
                '[int] API Perl' => sub {
                    foreach my $t (@tests) {
                        my $sorted = xsort( $t, algorithm => 'perl' );
                    }
                },
                '[int] isort' => sub {
                    foreach my $t (@tests) {
                        my $sorted = [isort @$t];

                    }
                },
                '[int] isort radix' => sub {
                    foreach my $t (@tests) {
                        my $sorted = [Sort::Key::Radix::isort @$t];
                    }
                },
            }
        )
    );
    say "\n";
}

sub benchmark_str {
    my ($set) = @_;
    my @tests = @$set;

    my $count = -2;
    $count = -5 if ( scalar @{ $tests[0] } >= 100_000 );

    cmpthese(
        timethese(
            $count,
            {

                '[str] XS merge' => sub {
                    foreach my $t (@tests) {
                        my $sorted = Sort::XS::merge_sort_str($t);
                    }
                },

                '[str] XS quick' => sub {
                    foreach my $t (@tests) {
                        my $sorted = Sort::XS::quick_sort_str($t);
                    }
                },

                '[str] API sxsort' => sub {
                    foreach my $t (@tests) {
                        my $sorted = sxsort($t);
                    }
                },
                '[str] XS heap' => sub {
                    foreach my $t (@tests) {
                        my $sorted = Sort::XS::heap_sort_str($t);
                    }
                },

                '[str] Perl' => sub {
                    foreach my $t (@tests) {
                        my $sorted = [sort @$t];
                    }
                },

            }
        )
    );
    say "\n";
}

__END__

# Sort::Fast
sort one dimension arrays faster using XS

# 1000 arrays * 10 rows ( integers )
merge -> 557/s req/sec
perl -> 565/s req/sec
heap -> 625/s req/sec
quick -> 637/s req/sec

# 100 arrays * 100 rows ( integers ) 
perl -> 645/s req/sec
merge -> 729/s req/sec
** heap -> 866/s req/sec
*** quick -> 946/s req/sec

# 100 arrays * 1_000 ( integers )
perl -> 50.7/s req/sec
merge -> 69.8/s req/sec
*** heap -> 83.9/s req/sec
*** quick -> 92.7/s req/sec

# 100 arrays * 10_000 ( integer )
perl -> 3.95/s req/sec
merge -> 5.97/s req/sec
** heap -> 7.20/s req/sec
*** quick -> 8.37/s req/sec

# 10 arrays * 100_000 rows ( integers )
perl -> 3.03/s req/sec
merge -> 5.26/s req/sec
** heap -> 6.08/s req/sec
*** quick -> 7.35/s req/sec


# 1 array * 1_000_000 rows ( integers )

perl -> 1.89/s req/sec
** merge -> 4.50/s req/sec
** heap -> 4.74/s req/sec
*** quick -> 6.43/s req/sec
