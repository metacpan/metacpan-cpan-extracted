#!/usr/bin/perl

use strict;
use warnings;

use blib;
use QtCore4;
use QtGui4;
use MainWindow;

sub main
{
    my $app = Qt::Application(\@ARGV);
    my $window = MainWindow();
    $window->show();
    $window->openImage('images/qt.png');
    return $app->exec();
}

exit main();
