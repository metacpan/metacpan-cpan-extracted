#!/usr/bin/perl

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::debug qw(ambiguous);

use Test::More tests => 32;

my $polygon = Qt::Polygon( [
    Qt::Point(5,7),
    Qt::Point(0,1),
    Qt::Point(1,1),
    Qt::Point(1,0)
] );

ok( exists $polygon->[0], 'Qt::Polygon::EXISTS' );
ok( !exists $polygon->[4], 'Qt::Polygon::EXISTS' );
ok( $polygon->[0] == Qt::Point(5,7), 'Qt::Polygon::FETCH' );
is( scalar @{$polygon}, 4, 'Qt::Polygon::FETCHSIZE' );

$polygon->[6] = Qt::Point(2,0);
ok( exists $polygon->[6], 'Qt::Polygon::EXISTS' );
ok( $polygon->[6] == Qt::Point(2,0), 'Qt::Polygon::FETCH' );
ok( $polygon->[-1] == Qt::Point(2,0), 'Qt::Polygon::FETCH' );
is( scalar @{$polygon}, 7, 'Qt::Polygon::FETCHSIZE' );

$#{$polygon} = 9;
is( scalar @{$polygon}, 10, 'Qt::Polygon::STORESIZE' );
$#{$polygon} = 2;
is( $#{$polygon}, 2, 'Qt::Polygon::STORESIZE' );

ok( delete( $polygon->[1] ) == Qt::Point(0,1), 'Qt::Polygon::DELETE' );
is( $polygon->[1]->y, 0, 'Qt::Polygon::DELETE' );

is_deeply( [push( @{$polygon}, Qt::Point(50,50), Qt::Point(60,60), Qt::Point(70,70) )],
    [6],
    'Qt::Polygon::PUSH' );
ok( $polygon->[3] == Qt::Point(50,50), 'Qt::Polygon::PUSH' );
ok( $polygon->[4] == Qt::Point(60,60), 'Qt::Polygon::PUSH' );
ok( $polygon->[5] == Qt::Point(70,70), 'Qt::Polygon::PUSH' );

ok( pop( @{$polygon} ) == Qt::Point(70,70), 'Qt::Polygon::POP' );
is( scalar @{$polygon}, 5, 'Qt::Polygon::POP' );

ok( shift( @{$polygon} ) == Qt::Point(5,7), 'Qt::Polygon::SHIFT' );
is( scalar @{$polygon}, 4, 'Qt::Polygon::SHIFT' );

is( unshift( @{$polygon}, Qt::Point(50,50), Qt::Point(60,60), Qt::Point(70,70) ),
    7,
    'Qt::Polygon::UNSHIFT' );
ok( $polygon->[0] == Qt::Point(50,50), 'Qt::Polygon::UNSHIFT' );
ok( $polygon->[1] == Qt::Point(60,60), 'Qt::Polygon::UNSHIFT' );
ok( $polygon->[2] == Qt::Point(70,70), 'Qt::Polygon::UNSHIFT' );

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

map { push @{$polygon}, Qt::Point( $_->[0], $_->[1] ) } @points;
my @gotPoints = splice @{$polygon};
is_deeply( [map{ [$_->x, $_->y] } @gotPoints], \@points, 'Qt::Polygon::SPLICE all' );

map { push @{$polygon}, Qt::Point( $_->[0], $_->[1] ) } @points;
@gotPoints = splice @{$polygon}, 3;
is_deeply( [map{ [$_->x, $_->y] } @gotPoints], [@points[3..6]], 'Qt::Polygon::SPLICE half' );

@{$polygon} = ();
is( scalar @{$polygon}, 0, 'Qt::Polygon::CLEAR' );

map { push @{$polygon}, Qt::Point( $_->[0], $_->[1] ) } @points;
@gotPoints = splice @{$polygon}, 10;
is( scalar @gotPoints, 0, 'Qt::Polygon::SPLICE off end' );

@gotPoints = splice @{$polygon}, 3, 1;
is_deeply( [map{ [$_->x, $_->y] } @gotPoints], [$points[3]], 'Qt::Polygon::SPLICE half' );
is_deeply( [map{ [$_->x, $_->y] } @{$polygon}], [@points[0..2],@points[4..6]], 'Qt::Polygon::SPLICE half' );

@{$polygon} = ();
map { push @{$polygon}, Qt::Point( $_->[0], $_->[1] ) } @points;
@gotPoints = splice @{$polygon}, 3, 1, Qt::Point(7,7), Qt::Point(8,8), Qt::Point(9,9);
is_deeply( [map{ [$_->x, $_->y] } @{$polygon}], [@points[0..2],([7,7],[8,8],[9,9]),@points[4..6]], 'Qt::Polygon::SPLICE replace' );

@{$polygon} = ();
map { push @{$polygon}, Qt::Point( $_->[0], $_->[1] ) } @points;
my $poly2 = Qt::Polygon([map { Qt::Point( $_->[0], $_->[1] ) } @points]);

ok( $polygon == $poly2, 'Qt::Polygon::operator==' );
