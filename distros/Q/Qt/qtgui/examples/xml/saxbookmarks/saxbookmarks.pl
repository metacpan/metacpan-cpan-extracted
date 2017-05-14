#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;
use MainWindow;

sub main
{
    my $app = Qt::Application(\@ARGV);
    my $mainWin = MainWindow();
#if defined(Q_OS_SYMBIAN)
    #mainWin->showFullScreen();
#else
    $mainWin->show();
#endif
    $mainWin->open();
    return $app->exec();
}

exit main();
