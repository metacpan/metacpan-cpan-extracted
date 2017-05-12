#!/usr/bin/perl -w
use strict;
use blib;

package MyWidget;
use Qt;
use Qt::isa qw(Qt::VBox);

use LCDRange;

sub NEW {
    shift->SUPER::NEW(@_);

    my $quit = Qt::PushButton("Quit", this, "quit");
    $quit->setFont(Qt::Font("Times", 18, &Qt::Font::Bold));

    Qt::app->connect($quit, SIGNAL('clicked()'), SLOT('quit()'));

    my $grid = Qt::Grid(4, this);

    my $previous;
    for my $r (0..3) {
	for my $c (0..3) {
	    my $lr = LCDRange($grid);
	    $previous->connect(
		$lr, SIGNAL('valueChanged(int)'),
		SLOT('setValue(int)')) if $previous;
	    $previous = $lr;
	}
    }
}

package main;
use MyWidget;

my $a = Qt::Application(\@ARGV);
my $w = MyWidget;
$a->setMainWidget($w);
$w->show;
exit $a->exec;
