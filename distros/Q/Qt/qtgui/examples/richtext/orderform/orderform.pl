#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;
use MainWindow;

# [0]
sub main
{
    my $app = Qt::Application(\@ARGV);
    my $window = MainWindow();
    $window->resize(640, 480);
    $window->show();
    $window->createSample();
    return $app->exec();
}
# [0]

exit main();
