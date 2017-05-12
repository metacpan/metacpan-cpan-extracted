#!/usr/bin/perl -w
use strict;
use blib;
use Qt;
use GameBoard;

Qt::Application::setColorSpec(&Qt::Application::CustomColor);
my $a = Qt::Application(\@ARGV);

my $gb = GameBoard;
$gb->setGeometry(100, 100, 500, 355);
$a->setMainWidget($gb);
$gb->show;
exit $a->exec;
