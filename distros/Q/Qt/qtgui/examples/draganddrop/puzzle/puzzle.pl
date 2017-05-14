#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;
use MainWindow;
use PuzzleResources;

sub main
{
    my $app = Qt::Application( \@ARGV );
    my $window = MainWindow();
    $window->openImage(':/images/example.jpg');
    $window->show();
    return $app->exec();
}

exit main();
