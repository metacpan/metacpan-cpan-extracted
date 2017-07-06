# Before 'make install' is performed this script should be runnable with
use strict;
use warnings;

use Carp qw/confess/;
use IO::File;
use Set::SegmentTree;
use Data::UUID;

sub rand_over_range {
    my ( $min, $max ) = @_;
    int( rand( $max - $min ) ) + $min;
}

sub intervaldata {
    my ( $count, $min, $max ) = @_;
    my $ug = Data::UUID->new;
    die "max is less than min" if $min > $max;
    map {
        [   $ug->to_string( $ug->create() ),
            (   sort { $a <=> $b } rand_over_range( $min, $max ),
                rand_over_range( $min, $max )
            ),
            $ug->to_string( $ug->create() ),
        ]
    } ( 0 .. $count );
}

sub buildRandomTree {
    my ( $base, $count, $range ) = @_;
    my $ap = {};
    my @rawintervals = intervaldata( $count, $base - $range, $base + $range );
    my $b = Set::SegmentTree::Builder->new(@rawintervals);
    return $b, $b->build;
}

do {
    use Time::HiRes;
    use Benchmark qw(:hireswallclock :all);

    my ($builder, $tree);
    do {
        warn "300 seconds counting build random tree 200, 100\n";
        my $mt = countit( 300,
            sub { ($builder, $tree) = buildRandomTree( time, 200, 100 ) } );
        warn "build interval trees - " . timestr($mt) . "\n";
    };
    do {
        warn "300 seconds find in tree\n";
        my $mt = countit(
            300,
            sub {
                $tree->find( rand_over_range( time - 100, time + 100 ) );
            }
        );
        warn $mt->iters . " memory read took - " . timestr($mt) . "\n";
    };
    do {
        warn "300 seconds serialize tree\n";
        my $mt = countit( 300, sub { $builder->to_file('tree.bin') } );
        warn "serialize 10 intervals - "
            . timestr($mt) . "\n";
    };
    my $readtree;
    do {
        warn "300 seconds deserialize tree\n";
        my $mt = countit( 300,
            sub { $readtree = Set::SegmentTree->from_file('tree.bin') } );
        warn "deserialize 50 intervals - "
            . timestr($mt) . "\n";
    };
    do {
        warn "300 read tree read\n";
        my $mt = countit(
            300,
            sub {
                $readtree->find(
                    rand_over_range( time - 100, time + 100 ) );
            }
        );
        warn "map read took - " . timestr($mt) . "\n";
    };
};
