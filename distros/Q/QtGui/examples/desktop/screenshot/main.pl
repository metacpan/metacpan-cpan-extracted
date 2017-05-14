#!/usr/bin/perl -w

use Qt;
use Qt::QApplication;

use Screenshot;

unshift @ARGV, 'screenshot';

my $app = QApplication(\@ARGV);
my $screenshot = Screenshot();
$screenshot->show();
$app->exec();

