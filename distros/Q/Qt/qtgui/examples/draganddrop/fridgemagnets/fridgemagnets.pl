#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;
use DragWidget;

sub main
{
    my $app = Qt::Application(\@ARGV);
    my $window = DragWidget();
    $window->show();
    return $app->exec();
}

exit main();
