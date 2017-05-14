#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;

use ColorItem;
use Robot;

#include <math.h>

sub main
{
    my $app = Qt::Application(\@ARGV);

    srand(Qt::Time(0,0,0)->secsTo(Qt::Time::currentTime()));

    my $scene = Qt::GraphicsScene(-200, -200, 400, 400);

    for (my $i = 0; $i < 10; ++$i) {
        my $item = ColorItem();
        $item->setPos(sin(($i * 6.28) / 10.0) * 150,
                     cos(($i * 6.28) / 10.0) * 150);

        $scene->addItem($item);
    }

    my $robot = Robot();
    $robot->scale(1.2, 1.2);
    $robot->setPos(0, -20);
    $scene->addItem($robot);

    my $view = Qt::GraphicsView($scene);
    $view->setRenderHint(Qt::Painter::Antialiasing());
    $view->setViewportUpdateMode(Qt::GraphicsView::BoundingRectViewportUpdate());
    $view->setBackgroundBrush(Qt::Brush(Qt::Color(230, 200, 167)));
    $view->setWindowTitle('Drag and Drop Robot');
    $view->show();

    return $app->exec();
}

exit main();
