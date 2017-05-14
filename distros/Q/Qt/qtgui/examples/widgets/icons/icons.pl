#!/usr/bin/perl

use strict;
use warnings;

use QtCore4;
use QtGui4;
use MainWindow;

use utf8;

sub main {
    my $app = Qt::Application( \@ARGV );
    my $mainWin = MainWindow();
    $mainWin->show();
    exit $app->exec();
}

main();
