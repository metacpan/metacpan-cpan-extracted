#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;
use GraphWidget;

sub main
{
    my $app = Qt::Application(\@ARGV);
    srand(Qt::Time(0,0,0)->secsTo(Qt::Time::currentTime()));

    my $widget = GraphWidget();
    $widget->show();
    return $app->exec();
}

exit main();
