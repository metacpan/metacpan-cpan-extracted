#!/usr/bin/perl

package WidgetsWiggly;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtTest4;
use Dialog;
use QtCore4::isa qw(Qt::Object);
use QtCore4::slots
    private => 1,
    initTestCase => [],
    testWiggly => [];

use Test::More;

sub NEW {
    my ($class, $parent) = @_;
    $class->SUPER::NEW();
}

sub testWiggly {
    Qt::Test::qWait(1000);
    this->{lineEdit}->setText('PerlQt Rocks!');
    Qt::Test::qWait(1000);
    ok('Wiggly text');
}

sub initTestCase {
    my $widget = Dialog();
    $widget->show();
    this->{widget} = $widget;
    this->{lineEdit} = $widget->findChildren('Qt::LineEdit')->[0];
    Qt::Test::qWaitForWindowShown($widget);
}

package main;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtTest4;
use WidgetsWiggly;
use Test::More tests=>1;

sub main {
    my $app = Qt::Application(\@ARGV);
    my $test = WidgetsWiggly();
    unshift @ARGV, $0;
    return Qt::Test::qExec($test, scalar @ARGV, \@ARGV);
}

exit main();
