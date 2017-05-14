#!/usr/bin/perl

use strict;
use warnings;

use QtCore4;
use QtGui4;
use SpinBoxDelegate;

# [0]
sub main {
    my $app = Qt::Application( \@ARGV );

    my $model = Qt::StandardItemModel(4, 2);
    my $tableView = Qt::TableView();
    $tableView->setModel($model);

    my $delegate = SpinBoxDelegate();
    $tableView->setItemDelegate($delegate);
# [0]

# [1]
    for (my $row = 0; $row < 4; ++$row) {
        for (my $column = 0; $column < 2; ++$column) {
            my $index = $model->index($row, $column, Qt::ModelIndex());
            $model->setData($index, Qt::Variant(($row+1) * ($column+1)));
        }
# [1] //! [2]
    }
# [2]

# [3]
    $tableView->setWindowTitle(Qt::Object::tr('Spin Box Delegate'));
    $tableView->show();
    return $app->exec();
}
# [3]

exit main();
