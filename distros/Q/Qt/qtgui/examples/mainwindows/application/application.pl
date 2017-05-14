#!/usr/bin/perl -w

use strict;

use QtCore4;
use QtGui4;
use MainWindow;

sub main {
    my $app = Qt::Application( \@ARGV );
    my $mainWin = MainWindow();
    $mainWin->show();
    exit $app->exec();
}

main();
