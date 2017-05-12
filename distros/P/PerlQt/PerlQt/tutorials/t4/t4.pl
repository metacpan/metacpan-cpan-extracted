#!/usr/bin/perl -w
use strict;
use blib;

package MyWidget;
use Qt;
use Qt::isa qw(Qt::Widget);

sub NEW {
    shift->SUPER::NEW(@_);

    setMinimumSize(200, 120);
    setMaximumSize(200, 120);

    my $quit = Qt::PushButton("Quit", this, "quit");
    $quit->setGeometry(62, 40, 75, 30);
    $quit->setFont(Qt::Font("Times", 18, &Qt::Font::Bold));

    Qt::app->connect($quit, SIGNAL('clicked()'), SLOT('quit()'));
}

package main;
use MyWidget;

my $a = Qt::Application(\@ARGV);

my $w = MyWidget;
$w->setGeometry(100, 100, 200, 120);
$a->setMainWidget($w);
$w->show;
exit $a->exec;
