#!/usr/bin/perl -w
use strict;
use blib;

package MyWidget;
use strict;
use Qt;
use Qt::isa qw(Qt::Widget);

use LCDRange;
use CannonField;

sub NEW {
    shift->SUPER::NEW(@_);

    my $quit = Qt::PushButton("Quit", this, "quit");
    $quit->setFont(Qt::Font("Times", 18, &Qt::Font::Bold));

    Qt::app->connect($quit, SIGNAL('clicked()'), SLOT('quit()'));

    my $angle = LCDRange(this, "angle");
    $angle->setRange(5, 70);

    my $cannonField = CannonField(this, "cannonField");

    $cannonField->connect($angle, SIGNAL('valueChanged(int)'), SLOT('setAngle(int)'));
    $angle->connect($cannonField, SIGNAL('angleChanged(int)'), SLOT('setValue(int)'));

    my $grid = Qt::GridLayout(this, 2, 2, 10);
    $grid->addWidget($quit, 0, 0);
    $grid->addWidget($angle, 1, 0, &AlignTop);
    $grid->addWidget($cannonField, 1, 1);
    $grid->setColStretch(1, 10);

    $angle->setValue(60);
    $angle->setFocus();
}

package main;
use Qt;
use MyWidget;

my $a = Qt::Application(\@ARGV);

my $w = MyWidget;
$w->setGeometry(100, 100, 500, 355);
$a->setMainWidget($w);
$w->show;
exit $a->exec;
