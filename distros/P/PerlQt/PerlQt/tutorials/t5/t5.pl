#!/usr/bin/perl -w
use strict;
use blib;

package MyWidget;
use Qt;
use Qt::isa qw(Qt::VBox);

sub NEW {
    shift->SUPER::NEW(@_);

    my $quit = Qt::PushButton("Quit", this, "quit");
    $quit->setFont(Qt::Font("Times", 18, &Qt::Font::Bold));

    Qt::app->connect($quit, SIGNAL('clicked()'), SLOT('quit()'));

    my $lcd = Qt::LCDNumber(2, this, "lcd");

    my $slider = Qt::Slider(&Horizontal, this, "slider");
    $slider->setRange(0, 99);
    $slider->setValue(0);

    $lcd->connect($slider, SIGNAL('valueChanged(int)'), SLOT('display(int)'));
}

package main;
use MyWidget;

my $a = Qt::Application(\@ARGV);

my $w = MyWidget;
$a->setMainWidget($w);
$w->show;
exit $a->exec;
