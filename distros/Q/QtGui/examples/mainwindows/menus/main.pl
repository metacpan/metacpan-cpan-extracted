#!/usr/bin/perl -w

use Qt;
#use blib;
use Qt::QApplication;

use MainWindow;

unshift @ARGV, 'menus';

my $app = QApplication(\@ARGV);
my $window = MainWindow();
$window->show();
$app->exec();

