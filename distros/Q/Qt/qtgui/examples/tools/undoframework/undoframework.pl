#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;

use MainWindow;
use UndoFrameworkResources;

# [0]
sub main
{
    my $app = Qt::Application(\@ARGV);

    my $mainWindow = MainWindow();
    $mainWindow->show();

    return $app->exec();
}
# [0]

exit main();
