#!/usr/bin/perl -w
use strict;
package Forever;
use Qt;
use Qt::isa qw(Qt::Widget);
use Qt::slots
	updateCaption => [];
use Qt::attributes qw(
	rectangles
	colors
);
use constant numColors => 120;

sub NEW {
    shift->SUPER::NEW(@_);
    colors = \my @colors;
    for(my $a = 0; $a < numColors; $a++) {
	push @colors, Qt::Color(rand(255), rand(255), rand(255));
    }
    rectangles = 0;
    startTimer(0);
    my $counter = Qt::Timer(this);
    this->connect($counter, SIGNAL('timeout()'), SLOT('updateCaption()'));
    $counter->start(1000);
}

sub updateCaption {
    my $s = sprintf "PerlQt Example - Forever - %d rectangles/second", rectangles;
    rectangles = 0;
    setCaption($s);
}

sub paintEvent {
    my $paint = Qt::Painter(this);
    my $w = width();
    my $h = height();
    return if $w <= 0 || $h <= 0;
    $paint->setPen(&NoPen);
    $paint->setBrush(colors->[rand(numColors)]);
    $paint->drawRect(rand($w), rand($h), rand($w), rand($h));
}

sub timerEvent {
    for(my $i = 0; $i < 100; $i++) {
	repaint(0);
	rectangles++;
    }
}

package main;
use Qt;
use Forever;

my $a = Qt::Application(\@ARGV);
my $always = Forever;
$a->setMainWidget($always);
$always->setCaption("PerlQt Example - Forever");
$always->show;
exit $a->exec;
