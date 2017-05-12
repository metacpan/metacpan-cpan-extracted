#!/usr/bin/perl

package ItemViewsPixelatorTest;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtTest4 qw( QVERIFY );
use MainWindow;
use QtCore4::isa qw(Qt::Object);
use QtCore4::slots
    private => 1,
    initTestCase => [];
use Test::More;

sub NEW {
    my ($class, $parent) = @_;
    $class->SUPER::NEW();
}

sub initTestCase {
    my $mainWin = MainWindow();
    $mainWin->openImage('images/qt.png');
    $mainWin->show();
    Qt::Test::qWaitForWindowShown( $mainWin );
    Qt::Test::qWait( 1000 );
    this->{mainWin} = $mainWin;
    pass( 'Window shown' );
}

package main;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtTest4 qw(QTEST_MAIN);
use ItemViewsPixelatorTest;
use Test::More tests => 1;

exit QTEST_MAIN('ItemViewsPixelatorTest');
