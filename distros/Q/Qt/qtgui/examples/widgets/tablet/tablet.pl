#!/usr/bin/perl

use strict;
use warnings;

use QtCore4;
use QtGui4;

use MainWindow;
use TabletApplication;
use TabletCanvas;

# [0]
sub main {
    my $app = TabletApplication( \@ARGV );
    my $canvas = TabletCanvas();
    $app->setCanvas($canvas);

    my $mainWindow = MainWindow($canvas);
    $mainWindow->resize(500, 500);
    $mainWindow->show();

    return $app->exec();
}
# [0]

exit main();
