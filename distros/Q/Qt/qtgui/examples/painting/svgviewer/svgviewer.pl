#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;
use MainWindow;

sub main
{
    my $app = Qt::Application(\@ARGV);

    my $window = MainWindow();
    if (scalar @ARGV == 1) {
        $window->openFile($ARGV[1]);
    }
    else {
        $window->openFile('files/bubbles.svg');
    }
    $window->show();
    return $app->exec();
}

exit main();
