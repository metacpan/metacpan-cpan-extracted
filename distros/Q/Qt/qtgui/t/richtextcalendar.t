#!/usr/bin/perl

package RichTextCalendarTest;

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
    tryTyping =>[];
use Test::More;

sub NEW {
    my ($class, $parent) = @_;
    $class->SUPER::NEW();
}

sub tryTyping {
    my $window = this->{window};
    
    my $date = $window->findChildren('Qt::DateTimeEdit')->[0];
    foreach ( 0..50 ) {
        Qt::Test::keyClick( $date, Qt::Key_Up(), Qt::NoModifier(), 20 );
    }

    pass( 'Changing date' );
}

sub initTestCase {
    my $window = MainWindow();
    $window->resize(640, 256);
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
use RichTextCalendarTest;
use Test::More tests => 2;

exit QTEST_MAIN('RichTextCalendarTest');
