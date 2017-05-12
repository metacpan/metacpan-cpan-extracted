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
            my $delay = 10;
            my $index = $model->index( $row, $column, Qt::ModelIndex() );
            my $mimeData = $model->mimeData( [$index] );
            $view->scrollTo($index);
            qApp->processEvents();
            Qt::Test::qSleep( $delay );
            my $destRowCol = $model->data( $index, Qt::UserRole() + 1 )->value;
            my $srcPos = $view->viewport()->mapToGlobal($view->rectForIndex( $index )->center());
            my $destPos = $puzzle->mapToGlobal(Qt::Rect( $destRowCol->x*80, $destRowCol->y*80, 80, 80)->center());

            my $numSteps = 10;
            my $xstep = ($destPos->x() - $srcPos->x()) / $numSteps;
            my $ystep = ($destPos->y() - $srcPos->y()) / $numSteps;

            my $event = Qt::DragEnterEvent( $view->viewport()->mapFromGlobal($srcPos),
                Qt::MoveAction(), $mimeData, Qt::LeftButton(), Qt::NoModifier() );
            $view->viewport()->dragEnterEvent( $event );
            qApp->processEvents();
            Qt::Test::qSleep( $delay );

            my $curPos = Qt::Point($srcPos);
            my $widget = $view->viewport();
            my $inPuzzle = 0;
            foreach my $step (0..$numSteps - 1) {
                $curPos->setX( $curPos->x() + $xstep );
                $curPos->setY( $curPos->y() + $ystep );
                if ( !$inPuzzle && $widget->mapFromGlobal($curPos)->x() > $widget->geometry()->width() ) {
                    $inPuzzle = 1;
                    $widget = $puzzle;
                    $event = Qt::DragEnterEvent( $widget->mapFromGlobal($srcPos),
                        Qt::MoveAction(), $mimeData, Qt::LeftButton(), Qt::NoModifier() );
                    $widget->dragEnterEvent( $event );
                    qApp->processEvents();
                    Qt::Test::qSleep( $delay );
                }
                $event = Qt::DragMoveEvent( $widget->mapFromGlobal($curPos),
                    Qt::MoveAction(), $mimeData, Qt::LeftButton(), Qt::NoModifier() );
                $widget->dragMoveEvent( $event );
                qApp->processEvents();
                Qt::Test::qSleep( $delay );
            }
            $event = Qt::DropEvent( $puzzle->mapFromGlobal($curPos),
                Qt::MoveAction(), $mimeData, Qt::LeftButton(), Qt::NoModifier() );
            $puzzle->dropEvent($event);
            qApp->processEvents();
            Qt::Test::qSleep( $delay );
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
    $DB::single=1;
    1;
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
