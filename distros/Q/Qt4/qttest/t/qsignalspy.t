#!/usr/bin/perl

package MyWidget;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );
use QtCore4::signals
    doCoolStuff => ['int'];

sub NEW {
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
}

sub doStuff {
    doCoolStuff(1);
    doCoolStuff(2);
    doCoolStuff(3);
    doCoolStuff(4);
    doCoolStuff(5);
    doCoolStuff(6);
}

package main;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtTest4;
use MyWidget;

use Test::More tests => 28;

my $app = Qt::Application(\@ARGV);
my $box = Qt::CheckBox( undef );
my $spy = Qt::SignalSpy($box, SIGNAL 'clicked(bool)');

$box->click();

is(scalar @{$spy}, 1);
my $arguments = shift @{$spy}; # take the first signal

is($arguments->[0]->toBool(), 1);

my $widget = MyWidget();
$spy = Qt::SignalSpy($widget, SIGNAL 'doCoolStuff(int)');
$widget->doStuff();
is(scalar @{$spy}, 6, 'Qt::SignalSpy::FETCHSIZE');
is_deeply( [map($_->[0]->toInt(), @{$spy})],
           [1, 2, 3, 4, 5, 6],
           'Spy Perl signals' );

ok( exists $spy->[0], 'Qt::SignalSpy::EXISTS' );
ok( !exists $spy->[7], 'Qt::SignalSpy::EXISTS' );

$#{$spy} = 9;
is( scalar @{$spy}, 10, 'Qt::SignalSpy::STORESIZE' );
$#{$spy} = 7;
is( $#{$spy}, 7, 'Qt::SignalSpy::STORESIZE' );

ok( delete( $spy->[1] )->[0] == Qt::Variant(Qt::Int(2)), 'Qt::SignalSpy::DELETE' );
is( scalar @{$spy->[1]}, 0, 'Qt::SignalSpy::DELETE' );

is_deeply( [push( @{$spy}, [Qt::Variant(Qt::Int(50)),Qt::Variant(Qt::Int(60))])],
    [9],
    'Qt::SignalSpy::PUSH' );

ok( $spy->[-1]->[0] == Qt::Variant(Qt::Int(50)), 'Qt::SignalSpy::PUSH' );
ok( $spy->[-1]->[1] == Qt::Variant(Qt::Int(60)), 'Qt::SignalSpy::PUSH' );

ok( pop( @{$spy} )->[1] == Qt::Variant(Qt::Int(60)), 'Qt::SignalSpy::POP' );
is( scalar @{$spy}, 8, 'Qt::SignalSpy::POP' );

ok( shift( @{$spy} )->[0] == Qt::Variant(Qt::Int(1)), 'Qt::SignalSpy::SHIFT' );
is( scalar @{$spy}, 7, 'Qt::SignalSpy::SHIFT' );

is( unshift( @{$spy}, [Qt::Variant(Qt::Point(50,50))], [Qt::Variant(Qt::Point(60,60))], [Qt::Variant(Qt::Point(70,70))] ),
    10,
    'Qt::SignalSpy::UNSHIFT' );
ok( $spy->[0]->[0] == Qt::Variant(Qt::Point(50,50)), 'Qt::SignalSpy::UNSHIFT' );
ok( $spy->[1]->[0] == Qt::Variant(Qt::Point(60,60)), 'Qt::SignalSpy::UNSHIFT' );
ok( $spy->[2]->[0] == Qt::Variant(Qt::Point(70,70)), 'Qt::SignalSpy::UNSHIFT' );

@{$spy} = ();
my @points = (
    [0,0],
    [1,1],
    [2,2],
    [3,3],
    [4,4],
    [5,5],
    [6,6]
);

map { push @{$spy}, [Qt::Variant(Qt::Point( $_->[0], $_->[1] ))] } @points;
my @gotPoints = splice @{$spy};
is_deeply( [map{ [$_->[0]->value()->x, $_->[0]->value()->y] } @gotPoints], \@points, 'Qt::SignalSpy::SPLICE all' );

map { push @{$spy}, [Qt::Variant(Qt::Point( $_->[0], $_->[1] ))] } @points;
@gotPoints = splice @{$spy}, 3;
is_deeply( [map{ [$_->[0]->value()->x, $_->[0]->value()->y] } @gotPoints], [@points[3..6]], 'Qt::SignalSpy::SPLICE half' );

@{$spy} = ();
is( scalar @{$spy}, 0, 'Qt::SignalSpy::CLEAR' );

map { push @{$spy}, [Qt::Variant(Qt::Point( $_->[0], $_->[1] ))] } @points;
@gotPoints = splice @{$spy}, 10;
is( scalar @gotPoints, 0, 'Qt::SignalSpy::SPLICE off end' );

@gotPoints = splice @{$spy}, 3, 1;
is_deeply( [map{ [$_->[0]->value()->x, $_->[0]->value()->y] } @gotPoints], [$points[3]], 'Qt::SignalSpy::SPLICE half' );
is_deeply( [map{ [$_->[0]->value()->x, $_->[0]->value()->y] } @{$spy}], [@points[0..2],@points[4..6]], 'Qt::SignalSpy::SPLICE half' );

@{$spy} = ();
map { push @{$spy}, [Qt::Variant(Qt::Point( $_->[0], $_->[1] ))] } @points;
@gotPoints = splice @{$spy}, 3, 1, [Qt::Variant(Qt::Point(7,7))], [Qt::Variant(Qt::Point(8,8))], [Qt::Variant(Qt::Point(9,9))];
is_deeply( [map{ [$_->[0]->value()->x, $_->[0]->value()->y] } @{$spy}], [@points[0..2],([7,7],[8,8],[9,9]),@points[4..6]], 'Qt::SignalSpy::SPLICE replace' );

=begin

@{$spy} = ();
map { push @{$spy}, Qt::Point( $_->[0], $_->[1] ) } @points;
my $poly2 = Qt::SignalSpy([map { Qt::Point( $_->[0], $_->[1] ) } @points]);

ok( $spy == $poly2, 'Qt::SignalSpy::operator==' );
