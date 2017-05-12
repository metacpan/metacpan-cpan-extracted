#!/usr/bin/perl -w
use strict;
use Qt;
use DigitalClock;

my $a = Qt::Application(\@ARGV);
my $clock = DigitalClock;
$clock->resize(170, 80);
$a->setMainWidget($clock);
$clock->setCaption("PerlQt Example - Digital Clock");
$clock->show;
exit $a->exec;
