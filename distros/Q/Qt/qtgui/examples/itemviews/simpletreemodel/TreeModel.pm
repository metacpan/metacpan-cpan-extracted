package TreeModel;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use TreeItem;

# [0]
use QtCore4::isa qw( Qt::AbstractItemModel );

#
    #treemodel.cpp

    #Provides a simple tree model to show how to create and use hierarchical
    #models.
#

# [0]
sub NEW
{
    my ($class, $data, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{rootData} = [
        Qt::Variant('Title'),
        Qt::Variant('Summary')
    ];
    this->{rootItem} = TreeItem->new(this->{rootData});
    this->setupModelData([split("\n", $data->constData())], this->{rootItem});
}
# [0]

# [2]
sub columnCount
{
    my ($parent) = @_;
    if ($parent->isValid()) {
        return $parent->internalPointer()->columnCount();
    }
    else {
        return this->{rootItem}->columnCount();
    }
}
# [2]

# [3]
sub data
{
    my ($index, $role) = @_;
    if (!$index->isValid()) {
        return Qt::Variant();
    }

    if ($role != Qt::DisplayRole()) {
        return Qt::Variant();
    }

    my $item = $index->internalPointer();

    return Qt::Variant($item->data($index->column()));
}
# [3]

# [4]
sub flags
{
    my ($index) = @_;
    if (!$index->isValid()) {
        return 0;
    }

    return Qt::ItemIsEnabled() | Qt::ItemIsSelectable();
}
# [4]

# [5]
sub headerData
{
    my ($section, $orientation, $role) = @_;
    if ($orientation == Qt::Horizontal() && $role == Qt::DisplayRole()) {
        return this->{rootItem}->data($section);
    }

    return Qt::Variant();
}
# [5]

# [6]
sub index
{
    my ($row, $column, $parent) = @_;
    if (!this->hasIndex($row, $column, $parent)) {
        return Qt::ModelIndex();
    }

    my $parentItem;

    if (!$parent->isValid()) {
        $parentItem = this->{rootItem};
    }
    else {
        $parentItem = $parent->internalPointer();
    }

    my $childItem = $parentItem->child($row);
    if ($childItem) {
        return this->createIndex($row, $column, $childItem);
    }
    else {
        return Qt::ModelIndex();
    }
}
# [6]

# [7]
sub parent
{
    my ($index) = @_;
    return unless $index;
    if (!$index->isValid()) {
        return Qt::ModelIndex();
    }

    my $childItem = $index->internalPointer();
    my $parentItem = $childItem->parent();

    if ($parentItem == this->{rootItem}) {
        return Qt::ModelIndex();
    }

    return this->createIndex($parentItem->row(), 0, $parentItem);
}
# [7]

# [8]
sub rowCount
{
    my ($parent) = @_;
    my $parentItem;
    if ($parent->column() > 0) {
        return 0;
    }

    if (!$parent->isValid()) {
        $parentItem = this->{rootItem};
    }
    else {
        $parentItem = $parent->internalPointer();
    }

    return $parentItem->childCount();
}
# [8]

sub setupModelData
{
    my ($lines, $parent) = @_;
    my @parents = ($parent);
    my @indentations = (0);

    my $number = 0;

    while ($number < scalar @{$lines}) {
        my $position = 0;
        while ($position < length $lines->[$number]) {
            if (substr($lines->[$number], $position, 1) ne ' ') {
                last;
            }
            $position++;
        }

        my $lineData = substr $lines->[$number], $position;

        if ($lineData) {
            # Read the column data from the rest of the line.
            my @columnStrings = grep{ m/./ } split "\t", $lineData;
            my @columnData;
            for (my $column = 0; $column < @columnStrings; ++$column) {
                push @columnData, Qt::Variant($columnStrings[$column]);
            }

            if ($position > $indentations[-1]) {
                # The last child of the current parent is now the new parent
                # unless the current parent has no children.

                if ($parents[-1]->childCount() > 0) {
                    push @parents, $parents[-1]->child($parents[-1]->childCount()-1);
                    push @indentations, $position;
                }
            } else {
                while ($position < $indentations[-1] && scalar @parents > 0) {
                    pop @parents;
                    pop @indentations;
                }
            }

            # Append a new item to the current parent's list of children.
            $parents[-1]->appendChild(TreeItem->new(\@columnData, $parents[-1]));
        }

        $number++;
    }
}

1;
