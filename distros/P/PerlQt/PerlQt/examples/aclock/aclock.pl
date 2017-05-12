#!/usr/bin/perl -w
use strict;
use Qt;
use AnalogClock;

my $a = Qt::Application(\@ARGV);
my $clock = AnalogClock;
$clock->setAutoMask(1) if @ARGV and $ARGV[0] eq '-transparent';
$clock->resize(100, 100);
$a->setMainWidget($clock);
$clock->setCaption("PerlQt example - Analog Clock");
$clock->show;
exit $a->exec;
