#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;
use Car;
use CarAdaptor;

sub main
{
    my $app = Qt::Application(\@ARGV);

    my $scene = Qt::GraphicsScene();
    $scene->setSceneRect(-500, -500, 1000, 1000);
    $scene->setItemIndexMethod(Qt::GraphicsScene::NoIndex());

    my $car = Car();
    $scene->addItem($car);

    my $view = Qt::GraphicsView($scene);
    $view->setRenderHint(Qt::Painter::Antialiasing());
    $view->setBackgroundBrush(Qt::Brush(Qt::darkGray()));
    $view->setWindowTitle(qApp->translate('Qt::GraphicsView', 'Qt DBus Controlled Car'));
    $view->resize(400, 300);
    $view->show();

    my $adaptorParent = Qt::Object();
    my $adaptor = CarAdaptor($adaptorParent, $car);
    my $connection = Qt::DBusConnection::sessionBus();
    $connection->registerObject('/Car', $adaptorParent);
    $connection->registerService('com.trolltech.CarExample');

    return $app->exec();
}

exit main();
