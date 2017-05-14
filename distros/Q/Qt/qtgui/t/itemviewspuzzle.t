#!/usr/bin/perl

package ItemViewsPuzzleTest;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtTest4 qw( QVERIFY );
use MainWindow;
use QtCore4::isa qw(Qt::Object);
use QtCore4::slots
    private => 1,
    initTestCase => [],
    solve => [];
use Test::More;

sub NEW {
    my ($class, $parent) = @_;
    $class->SUPER::NEW();
}

sub solve {
    my $window = this->{window};
    my $model = $window->{model};
    my $view = $window->{piecesList};
    my $puzzle = $window->{puzzleWidget};
    foreach my $row ( 0..$model->rowCount(Qt::ModelIndex())-1 ) {
        foreach my $column ( 0..$model->columnCount(Qt::ModelIndex())-1 ) {
            my $index = $model->index( $row, $column, Qt::ModelIndex() );
            $view->scrollTo($index);
            my $destRowCol = $model->data( $index, Qt::UserRole() + 1 )->value;
            my $srcPos = $view->rectForIndex( $index )->center();
            my $destPos = Qt::Rect( $destRowCol->x*80, $destRowCol->y*80, 80, 80)->center();

            # If QTest allowed us to make drag events, we could actually solve the puzzle.
            Qt::Test::mousePress( $view->viewport(), Qt::LeftButton(), Qt::NoModifier(), $srcPos, 10 );
            Qt::Test::mouseRelease( $puzzle, Qt::LeftButton(), Qt::NoModifier(), $destPos, 10 );
        }
    }
}

sub initTestCase {
    my $window = MainWindow();
    $window->openImage('images/example.jpg');
    $window->show();
    Qt::Test::qWaitForWindowShown( $window );
    this->{window} = $window;
    pass( 'Window shown' );
}

package main;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtTest4 qw(QTEST_MAIN);
use ItemViewsPuzzleTest;
use Test::More tests => 1;

exit QTEST_MAIN('ItemViewsPuzzleTest');
