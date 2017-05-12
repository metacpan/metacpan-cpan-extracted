#!/usr/bin/perl -w
use strict;
use blib;
use Qt;

my $a = Qt::Application(\@ARGV);

my $box = Qt::VBox;
$box->resize(200, 120);

my $quit = Qt::PushButton("Quit", $box);
$quit->setFont(Qt::Font("Times", 18, &Qt::Font::Bold));

$a->connect($quit, SIGNAL('clicked()'), SLOT('quit()'));

$a->setMainWidget($box);
$box->show;

exit $a->exec;
