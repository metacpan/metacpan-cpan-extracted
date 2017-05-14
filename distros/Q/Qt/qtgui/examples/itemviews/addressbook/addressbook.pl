#!/usr/bin/perl

use strict;
use warnings;

use QtCore4;
use QtGui4;
use MainWindow;

sub main {
    my $app = Qt::Application( \@ARGV );
    my $mw = MainWindow();
    $mw->show();
    exit $app->exec();
}

main();
