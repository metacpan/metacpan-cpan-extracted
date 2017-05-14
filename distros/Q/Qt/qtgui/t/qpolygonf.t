#!/usr/bin/perl

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::debug qw(ambiguous);

use Test::More tests => 32;

my $polygon = Qt::PolygonF( [
    Qt::PointF(5,7),
    Qt::PointF(0,1),
    Qt::PointF(1,1),
    Qt::PointF(1,0)
] );

ok( exists $polygon->[0], 'Qt::PolygonF::EXISTS' );
ok( !exists $polygon->[4], 'Qt::PolygonF::EXISTS' );
ok( $polygon->[0] == Qt::PointF(5,7), 'Qt::PolygonF::FETCH' );
is( scalar @{$polygon}, 4, 'Qt::PolygonF::FETCHSIZE' );

$polygon->[6] = Qt::PointF(2,0);
ok( exists $polygon->[6], 'Qt::PolygonF::EXISTS' );
ok( $polygon->[6] == Qt::PointF(2,0), 'Qt::PolygonF::FETCH' );
ok( $polygon->[-1] == Qt::PointF(2,0), 'Qt::PolygonF::FETCH' );
is( scalar @{$polygon}, 7, 'Qt::PolygonF::FETCHSIZE' );

$#{$polygon} = 9;
is( scalar @{$polygon}, 10, 'Qt::PolygonF::STORESIZE' );
$#{$polygon} = 2;
is( $#{$polygon}, 2, 'Qt::PolygonF::STORESIZE' );

ok( delete( $polygon->[1] ) == Qt::PointF(0,1), 'Qt::PolygonF::DELETE' );
is( $polygon->[1]->y, 0, 'Qt::PolygonF::DELETE' );

is( push( @{$polygon}, Qt::PointF(50,50), Qt::PointF(60,60), Qt::PointF(70,70) ),
    6,
    'Qt::PolygonF::PUSH' );
ok( $polygon->[3] == Qt::PointF(50,50), 'Qt::PolygonF::PUSH' );
ok( $polygon->[4] == Qt::PointF(60,60), 'Qt::PolygonF::PUSH' );
ok( $polygon->[5] == Qt::PointF(70,70), 'Qt::PolygonF::PUSH' );

ok( pop( @{$polygon} ) == Qt::PointF(70,70), 'Qt::PolygonF::POP' );
is( scalar @{$polygon}, 5, 'Qt::PolygonF::POP' );

ok( shift( @{$polygon} ) == Qt::PointF(5,7), 'Qt::PolygonF::SHIFT' );
is( scalar @{$polygon}, 4, 'Qt::PolygonF::SHIFT' );

is( unshift( @{$polygon}, Qt::PointF(50,50), Qt::PointF(60,60), Qt::PointF(70,70) ),
    7,
    'Qt::PolygonF::UNSHIFT' );
ok( $polygon->[0] == Qt::PointF(50,50), 'Qt::PolygonF::UNSHIFT' );
ok( $polygon->[1] == Qt::PointF(60,60), 'Qt::PolygonF::UNSHIFT' );
ok( $polygon->[2] == Qt::PointF(70,70), 'Qt::PolygonF::UNSHIFT' );

@{$polygon} = ();
my @points = (
    [0,0],
    [1,1],
    [2,2],
    [3,3],
    [4,4],
    [5,5],
    [6,6]
);

map { push @{$polygon}, Qt::PointF( $_->[0], $_->[1] ) } @points;
my @gotPoints = splice @{$polygon};
is_deeply( [map{ [$_->x, $_->y] } @gotPoints], \@points, 'Qt::PolygonF::SPLICE all' );

map { push @{$polygon}, Qt::PointF( $_->[0], $_->[1] ) } @points;
@gotPoints = splice @{$polygon}, 3;
is_deeply( [map{ [$_->x, $_->y] } @gotPoints], [@points[3..6]], 'Qt::PolygonF::SPLICE half' );

@{$polygon} = ();
is( scalar @{$polygon}, 0, 'Qt::PolygonF::CLEAR' );

map { push @{$polygon}, Qt::PointF( $_->[0], $_->[1] ) } @points;
@gotPoints = splice @{$polygon}, 10;
is( scalar @gotPoints, 0, 'Qt::PolygonF::SPLICE off end' );

@gotPoints = splice @{$polygon}, 3, 1;
is_deeply( [map{ [$_->x, $_->y] } @gotPoints], [$points[3]], 'Qt::PolygonF::SPLICE half' );
is_deeply( [map{ [$_->x, $_->y] } @{$polygon}], [@points[0..2],@points[4..6]], 'Qt::PolygonF::SPLICE half' );

@{$polygon} = ();
map { push @{$polygon}, Qt::PointF( $_->[0], $_->[1] ) } @points;
@gotPoints = splice @{$polygon}, 3, 1, Qt::PointF(7,7), Qt::PointF(8,8), Qt::PointF(9,9);
is_deeply( [map{ [$_->x, $_->y] } @{$polygon}], [@points[0..2],([7,7],[8,8],[9,9]),@points[4..6]], 'Qt::PolygonF::SPLICE replace' );

@{$polygon} = ();
map { push @{$polygon}, Qt::PointF( $_->[0], $_->[1] ) } @points;
my $poly2 = Qt::PolygonF([map { Qt::PointF( $_->[0], $_->[1] ) } @points]);

ok( $polygon == $poly2, 'Qt::PolygonF::operator==' );
