#!/usr/bin/perl

use strict;
use warnings;

use QtCore4;
use QtGui4;
use TreeModel;

sub main {
    my $app = Qt::Application(\@ARGV);

    my $file = Qt::File('default.txt');
    $file->open(Qt::IODevice::ReadOnly());
    my $model = TreeModel($file->readAll());
    $file->close();

    my $view = Qt::TreeView();
    $view->setModel($model);
    $view->setWindowTitle(Qt::Object::tr('Simple Tree Model'));
    $view->show();
    return $app->exec();
}

exit main();
