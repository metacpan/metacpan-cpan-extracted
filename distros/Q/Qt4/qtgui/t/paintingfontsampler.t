#!/usr/bin/perl

package PaintingFontsamplerTest;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtTest4;
use MainWindow;
use QtCore4::isa qw(Qt::Object);
use QtCore4::slots
    private => 1,
    initTestCase => [],
    testMark => [];
use Test::More;

sub NEW {
    my ($class, $parent) = @_;
    $class->SUPER::NEW();
}

sub initTestCase {
    my $window = MainWindow();
    $window->show();
    this->{window} = $window;
}

sub testMark {
    SKIP: {
        my $database = Qt::FontDatabase();
        skip 'No fonts detected', 1 unless scalar @{$database->families()};

        my $window = this->{window};
        my $item1 = $window->{ui}->fontTree->topLevelItem(0);
        ok( $item1->checkState(0) == Qt::Unchecked() );
        Qt::Test::qWaitForWindowShown( $window );
        Qt::Test::keyClicks( $window, 'M', Qt::ControlModifier(), 10 );
        ok( $item1->checkState(0) == Qt::Checked() );
        Qt::Test::keyClicks( $window, 'U', Qt::ControlModifier(), 10 );
        ok( $item1->checkState(0) == Qt::Unchecked() );
    }
}

package main;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtTest4;
use PaintingFontsamplerTest;
use Test::More tests=>3;

# [0]
sub main
{
    my $app = Qt::Application(\@ARGV);
    my $test = PaintingFontsamplerTest;
    unshift @ARGV, $0;
    return Qt::Test::qExec($test, scalar @ARGV, \@ARGV);
}
# [0]

exit main();
