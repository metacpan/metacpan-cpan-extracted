#!/usr/bin/perl

package WidgetsCalculator;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtTest4;
use Calculator;
use QtCore4::isa qw(Qt::Object);
use QtCore4::slots
    private => 1,
    initTestCase => [],
    cleanup => [],
    testAdd => [],
    testSubtract => [],
    testMemory => [];

use Test::More;

sub NEW {
    my ($class, $parent) = @_;
    $class->SUPER::NEW();
}

sub testAdd {
    my $widget = this->{widget};
    my $button5 = $widget->digitButtons->[5];
    my $plusButton = $widget->{plusButton};
    my $button4 = $widget->digitButtons->[4];
    my $equalButton = $widget->{equalButton};
    foreach my $widget ( $button4, $plusButton, $button5, $equalButton ) {
        Qt::Test::mouseClick( $widget, Qt::LeftButton() );
    }

    is($widget->display->text(), 5+4, 'Addition');
}

sub testSubtract {
    my $widget = this->{widget};
    my $button5 = $widget->digitButtons->[5];
    my $minusButton = $widget->{minusButton};
    my $button4 = $widget->digitButtons->[4];
    my $equalButton = $widget->{equalButton};
    foreach my $widget ( $button5, $minusButton, $button4, $equalButton ) {
        Qt::Test::mouseClick( $widget, Qt::LeftButton() );
    }

    is($widget->display->text(), 5-4, 'Subtraction');
}

sub testMemory {
    my $widget = this->{widget};
    my $button5 = $widget->digitButtons->[5];
    my $plusButton = $widget->{plusButton};
    my $button3 = $widget->digitButtons->[3];
    my $equalButton = $widget->{equalButton};
    my $setMemoryButton = $widget->{setMemoryButton};
    my $readMemoryButton = $widget->{readMemoryButton};
    foreach my $widget ( $button5, $plusButton, $button3, $equalButton, $setMemoryButton, $button3, $plusButton, $readMemoryButton, $equalButton ) {
        Qt::Test::mouseClick( $widget, Qt::LeftButton() );
    }

    is($widget->display->text(), 5+3+3, 'Memory');
}

sub initTestCase {
    my $widget = Calculator();
    $widget->show();
    this->{widget} = $widget;
    Qt::Test::qWaitForWindowShown($widget);
}

sub cleanup {
    this->{widget}->clear();
}

package main;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtTest4;
use WidgetsCalculator;
use Test::More tests=>3;

sub main {
    my $app = Qt::Application(\@ARGV);
    my $test = WidgetsCalculator();
    unshift @ARGV, $0;
    return Qt::Test::qExec($test, scalar @ARGV, \@ARGV);
}

exit main();
