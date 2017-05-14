#!/usr/bin/perl

package MainWindowsMDITest;

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
    testSave => [],
    testFocus => [];
use Test::More;

sub NEW {
    my ($class, $parent) = @_;
    $class->SUPER::NEW();
}

sub testSave {
    my $mainWin = this->{mainWin};
    $mainWin->newFile();
    my $activeWindow = $mainWin->activeMdiChild();
    my $text = 'Hello, World!';
    Qt::Test::keyClicks($activeWindow, $text, Qt::NoModifier());

    my $filename = 'MdiTestFile';
    $activeWindow->saveFile($filename);

    open my $fh, '<', $filename;
    my $result = <$fh>;
    close $fh;

    #QVERIFY( $text eq $result, 'File write contents' );
    is( $text, $result, 'File write contents' );

    unlink $filename;
    $activeWindow->parent->close();
}

sub testFocus {
    my $mainWin = this->{mainWin};
    $mainWin->newFile();
    my $child1 = $mainWin->activeMdiChild();
    $mainWin->newFile();
    my $child2 = $mainWin->activeMdiChild();

    my ($windowMenu) = grep{ $_->title && $_->title eq '&Window' }
        @{ $mainWin->menuBar->findChildren('Qt::Menu') };

    Qt::Test::qWaitForWindowShown($child2);

    foreach my $winId ( 2, 1, 2, 1 ) {
        Qt::Test::keyClicks($mainWin, 'w', Qt::ALT());
        Qt::Test::qWaitForWindowShown($windowMenu);
        Qt::Test::keyClicks($windowMenu, $winId);
        Qt::Test::qWait(200);

        my $child;
        if ( $winId == 1 ) {
            $child = $child1;
        }
        else {
            $child = $child2;
        }

        #QVERIFY( $mainWin->activeMdiChild() eq $child, 'Widget focus' );
        is( $mainWin->activeMdiChild(), $child, 'Widget focus' );
    }
    $child1->parent()->close();
    $child2->parent()->close();
}

sub initTestCase {
    my $mainWin = MainWindow();
    $mainWin->show();
    this->{mainWin} = $mainWin;
}

package main;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtTest4 qw(QTEST_MAIN);
use MainWindowsMDITest;
use Test::More tests => 5;

exit QTEST_MAIN('MainWindowsMDITest');
