#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;

use lib '../';
use Connection;

sub initializeModel
{
    my ($model) = @_;
    $model->setTable('person');
    $model->setEditStrategy(Qt::SqlTableModel::OnManualSubmit());
    $model->select();

    $model->setHeaderData(0, Qt::Horizontal(), Qt::Variant(Qt::String(Qt::Object::tr('ID'))));
    $model->setHeaderData(1, Qt::Horizontal(), Qt::Variant(Qt::String(Qt::Object::tr('First name'))));
    $model->setHeaderData(2, Qt::Horizontal(), Qt::Variant(Qt::String(Qt::Object::tr('Last name'))));
}

sub createView
{
    my ($title, $model) = @_;
    my $view = Qt::TableView();
    $view->setModel($model);
    $view->setWindowTitle($title);
    return $view;
}

sub main
{
    my $app = Qt::Application(\@ARGV);
    if (!Connection::createConnection()) {
        return 1;
    }

    my $model = Qt::SqlTableModel();

    initializeModel($model);

    my $view1 = createView(Qt::Object::tr('Table Model (View 1)'), $model);
    my $view2 = createView(Qt::Object::tr('Table Model (View 2)'), $model);

    $view1->show();
    $view2->move($view1->x() + $view1->width() + 20, $view1->y());
    $view2->show();

    return $app->exec();
}

exit main();
