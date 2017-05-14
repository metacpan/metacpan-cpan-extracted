package MainWindow;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::MainWindow );
use Ui_MainWindow;
use MainWindow;
use TreeModel;

use QtCore4::slots
    updateActions => [],
    insertChild => [],
    insertColumn => ['const QModelIndex &'],
    insertColumn => [],
    insertRow => [],
    removeColumn => ['const QModelIndex &'],
    removeColumn => [],
    removeRow => [];

sub NEW
{
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );

    this->{ui} = Ui_MainWindow->setupUi(this);

    my @headers = ( this->tr('Title'), this->tr('Description') );

    my $file = Qt::File('default.txt');
    $file->open(Qt::IODevice::ReadOnly());
    my $model = TreeModel(\@headers, $file->readAll(), this);
    $file->close();

    my $view = this->{ui}->view();
    $view->setModel($model);
    for (my $column = 0; $column < $model->columnCount(); ++$column) {
        $view->resizeColumnToContents($column);
    }

    my $exitAction = this->{ui}->exitAction();
    this->connect($exitAction, SIGNAL 'triggered()', qApp, SLOT 'quit()');

    this->connect($view->selectionModel(),
            SIGNAL 'selectionChanged(const QItemSelection &,' .
                                    'const QItemSelection &)',
            this, SLOT 'updateActions()');

    my $actionsMenu = this->{ui}->actionsMenu();
    my $insertRowAction = this->{ui}->insertRowAction();
    my $insertColumnAction = this->{ui}->insertColumnAction();
    my $removeRowAction = this->{ui}->removeRowAction();
    my $removeColumnAction = this->{ui}->removeColumnAction();
    my $insertChildAction = this->{ui}->insertChildAction();
    this->connect($actionsMenu, SIGNAL 'aboutToShow()', this, SLOT 'updateActions()');
    this->connect($insertRowAction, SIGNAL 'triggered()', this, SLOT 'insertRow()');
    this->connect($insertColumnAction, SIGNAL 'triggered()', this, SLOT 'insertColumn()');
    this->connect($removeRowAction, SIGNAL 'triggered()', this, SLOT 'removeRow()');
    this->connect($removeColumnAction, SIGNAL 'triggered()', this, SLOT 'removeColumn()');
    this->connect($insertChildAction, SIGNAL 'triggered()', this, SLOT 'insertChild()');

    this->updateActions();
}

sub insertChild
{
    my $view = this->{ui}->view();
    my $index = $view->selectionModel()->currentIndex();
    my $model = $view->model();

    if ($model->columnCount($index) == 0) {
        if (!$model->insertColumn(0, $index)) {
            return;
        }
    }

    if (!$model->insertRow(0, $index)) {
        return;
    }

    for (my $column = 0; $column < $model->columnCount($index); ++$column) {
        my $child = $model->index(0, $column, $index);
        $model->setData($child, Qt::Variant('[No data]'), Qt::EditRole());
        if (!$model->headerData($column, Qt::Horizontal())->isValid()) {
            $model->setHeaderData($column, Qt::Horizontal(), Qt::Variant('[No header]'),
                                 Qt::EditRole());
        }
    }

    $view->selectionModel()->setCurrentIndex($model->index(0, 0, $index),
                                            Qt::ItemSelectionModel::ClearAndSelect());
    this->updateActions();
}

sub insertColumn
{
    my ($parent) = @_;
    $parent = $parent ? $parent : Qt::ModelIndex();
    my $view = this->{ui}->view();
    my $model = $view->model();
    my $column = $view->selectionModel()->currentIndex()->column();

    # Insert a column in the parent item.
    my $changed = $model->insertColumn($column + 1, $parent);
    if ($changed) {
        $model->setHeaderData($column + 1, Qt::Horizontal(), Qt::Variant('[No header]'),
                             Qt::EditRole());
    }

    this->updateActions();

    return $changed;
}

sub insertRow
{
    my $view = this->{ui}->view();
    my $index = $view->selectionModel()->currentIndex();
    my $model = $view->model();

    if (!$model->insertRow($index->row()+1, $index->parent())) {
        return;
    }

    this->updateActions();

    for (my $column = 0; $column < $model->columnCount($index->parent()); ++$column) {
        my $child = $model->index($index->row()+1, $column, $index->parent());
        $model->setData($child, Qt::Variant('[No data]'), Qt::EditRole());
    }
}

sub removeColumn
{
    my ($parent) = @_;
    $parent = $parent ? $parent : Qt::ModelIndex();
    my $view = this->{ui}->view();
    my $model = $view->model();
    my $column = $view->selectionModel()->currentIndex()->column();

    # Insert columns in each child of the parent item.
    my $changed = $model->removeColumn($column, $parent);

    if (!$parent->isValid() && $changed) {
        this->updateActions();
    }

    return $changed;
}

sub removeRow
{
    my $view = this->{ui}->view();
    my $index = $view->selectionModel()->currentIndex();
    my $model = $view->model();
    if ($model->removeRow($index->row(), $index->parent())) {
        this->updateActions();
    }
}

sub updateActions
{
    my $view = this->{ui}->view();
    my $selection = $view->selectionModel()->selection()->indexes();
    my $hasSelection = $selection ? scalar @{$selection} : 0;
    this->{ui}->removeRowAction->setEnabled($hasSelection);
    this->{ui}->removeColumnAction->setEnabled($hasSelection);

    my $hasCurrent = $view->selectionModel()->currentIndex()->isValid();
    this->{ui}->insertRowAction->setEnabled($hasCurrent);
    this->{ui}->insertColumnAction->setEnabled($hasCurrent);

    if ($hasCurrent) {
        $view->closePersistentEditor($view->selectionModel()->currentIndex());

        my $row = $view->selectionModel()->currentIndex()->row();
        my $column = $view->selectionModel()->currentIndex()->column();
        if ($view->selectionModel()->currentIndex()->parent()->isValid()) {
            this->statusBar()->showMessage(sprintf this->tr('Position: (%d,%d)'), $row, $column);
        }
        else {
            this->statusBar()->showMessage(sprintf this->tr('Position: (%d,%d) in top level'), $row, $column);
        }
    }
}

1;
