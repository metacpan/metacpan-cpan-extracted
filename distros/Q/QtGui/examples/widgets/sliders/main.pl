#!/usr/bin/perl -w

#use blib;
use Qt;
use Qt::QApplication;

use Window;

unshift @ARGV, 'sliders';

my $app = QApplication(\@ARGV);
my $window = Window();
$window->show();
$app->exec();
