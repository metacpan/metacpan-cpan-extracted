#!/usr/bin/perl

use strict;
use warnings;
use QtCore4;
use QtGui4;

use lib '../';
use Connection;
use CustomSqlModel;
use EditableSqlModel;

sub initializeModel
{
    my ($model) = @_;
    $model->setQuery('select * from person');
    $model->setHeaderData(0, Qt::Horizontal(), Qt::Variant(Qt::String(Qt::Object::tr('ID'))));
    $model->setHeaderData(1, Qt::Horizontal(), Qt::Variant(Qt::String(Qt::Object::tr('First name'))));
    $model->setHeaderData(2, Qt::Horizontal(), Qt::Variant(Qt::String(Qt::Object::tr('Last name'))));
}

my $offset = 0;

sub createView
{
    my ($title, $model) = @_;

    my $view = Qt::TableView();
    $view->setModel($model);
    $view->setWindowTitle($title);
    $view->move(100 + $offset, 100 + $offset);
    $offset += 20;
    $view->show();
}

sub main
{
    my $app = Qt::Application(\@ARGV);
    if (!Connection::createConnection()){
        return 1;
    }

    my $plainModel = Qt::SqlQueryModel();
    my $editableModel = EditableSqlModel();
    my $customModel = CustomSqlModel();

    initializeModel($plainModel);
    initializeModel($editableModel);
    initializeModel($customModel);

    createView(Qt::Object::tr('Plain Query Model'), $plainModel);
    createView(Qt::Object::tr('Editable Query Model'), $editableModel);
    createView(Qt::Object::tr('Custom Query Model'), $customModel);

    return $app->exec();
}

exit main();
