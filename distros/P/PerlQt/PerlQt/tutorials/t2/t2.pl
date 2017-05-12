#!/usr/bin/perl -w
use strict;
use blib;
use Qt;

my $a = Qt::Application(\@ARGV);

my $quit = Qt::PushButton("Quit", undef);
$quit->resize(75, 30);
$quit->setFont(Qt::Font("Times", 18, &Qt::Font::Bold));

$a->connect($quit, SIGNAL('clicked()'), SLOT('quit()'));

$a->setMainWidget($quit);
$quit->show;
exit $a->exec;
