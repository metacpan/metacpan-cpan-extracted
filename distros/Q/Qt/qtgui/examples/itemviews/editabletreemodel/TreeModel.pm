package TreeModel;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::AbstractItemModel );
use TreeItem;

# [0]
sub NEW
{
    my ($class, $headers, $data, $parent) = @_;
    $class->SUPER::NEW( $parent );
    foreach my $header ( @{$headers} ) {
        push @{this->{rootData}}, Qt::Variant( $header );
    }

    this->{rootItem} = TreeItem->new(this->{rootData});
    this->setupModelData([split( m/\n/, $data->constData() )], this->{rootItem});
}
# [0]

# [2]
sub columnCount
{
    return this->{rootItem}->columnCount();
}
# [2]

sub data
{
    my ($index, $role) = @_;
    if (!$index->isValid()) {
        return Qt::Variant();
    }

    if ($role != Qt::DisplayRole() && $role != Qt::EditRole()) {
        return Qt::Variant();
    }

    my $item = this->getItem($index);

    return $item->data($index->column());
}

# [3]
sub flags
{
    my ($index) = @_;
    if (!$index->isValid()) {
        return 0;
    }

    return Qt::ItemIsEditable() | Qt::ItemIsEnabled() | Qt::ItemIsSelectable();
}
# [3]

# [4]
sub getItem
{
    my ($index) = @_;
    if ($index && $index->isValid()) {
        my $item = $index->internalPointer();
        return $item;
    }
    return this->{rootItem};
}
# [4]

sub headerData
{
    my ($section, $orientation, $role) = @_;
    $role = $role ? $role : Qt::DisplayRole();
    if ($orientation == Qt::Horizontal() && $role == Qt::DisplayRole()) {
        return this->{rootItem}->data($section);
    }

    return Qt::Variant();
}

# [5]
sub index
{
    my ($row, $column, $parent) = @_;
    if ($parent->isValid() && $parent->column() != 0) {
        return Qt::ModelIndex();
    }
# [5]

# [6]
    my $parentItem = this->getItem($parent);

    my $childItem = $parentItem->child($row);
    if ($childItem) {
        return this->createIndex($row, $column, $childItem);
    }
    else {
        return Qt::ModelIndex();
    }
}
# [6]

sub insertColumns
{
    my ($position, $columns, $parent) = @_;

    this->beginInsertColumns($parent, $position, $position + $columns - 1);
    my $success = this->{rootItem}->insertColumns($position, $columns);
    this->endInsertColumns();

    return $success;
}

sub insertRows
{
    my ($position, $rows, $parent) = @_;
    my $parentItem = this->getItem($parent);

    this->beginInsertRows($parent, $position, $position + $rows - 1);
    my $success = $parentItem->insertChildren($position, $rows, this->{rootItem}->columnCount());
    this->endInsertRows();

    return $success;
}

# [7]
sub parent
{
    my ($index) = @_;
    if ( !defined $index ) {
        return Qt::Object::parent();
    }

    if (!$index->isValid()) {
        return Qt::ModelIndex();
    }

    my $childItem = this->getItem($index);
    my $parentItem = $childItem->parent();

    if ($parentItem == this->{rootItem}) {
        return Qt::ModelIndex();
    }

    return this->createIndex($parentItem->childNumber(), 0, $parentItem);
}
# [7]

sub removeColumns
{
    my ($position, $columns, $parent) = @_;

    this->beginRemoveColumns($parent, $position, $position + $columns - 1);
    my $success = this->{rootItem}->removeColumns($position, $columns);
    this->endRemoveColumns();

    if (this->{rootItem}->columnCount() == 0) {
        this->removeRows(0, this->rowCount());
    }

    return $success;
}

sub removeRows
{
    my ($position, $rows, $parent) = @_;
    $parent = $parent ? $parent : Qt::ModelIndex();
    my $parentItem = this->getItem($parent);
    my $success = 1;

    this->beginRemoveRows($parent, $position, $position + $rows - 1);
    $success = $parentItem->removeChildren($position, $rows);
    this->endRemoveRows();

    return $success;
}

# [8]
sub rowCount
{
    my ($parent) = @_;
    my $parentItem = this->getItem($parent);

    return $parentItem->childCount();
}
# [8]

sub setData
{
    my ($index, $value, $role) = @_;
    if ($role != Qt::EditRole()) {
        return 0;
    }

    my $item = this->getItem($index);
    my $result = $item->setData($index->column(), $value);

    if ($result) {
        emit this->dataChanged($index, $index);
    }

    return $result;
}

sub setHeaderData
{
    my ($section, $orientation, $value, $role) = @_;
    if ($role != Qt::EditRole() || $orientation != Qt::Horizontal()) {
        return 0;
    }

    my $result = this->{rootItem}->setData($section, $value);

    if ($result) {
        emit this->headerDataChanged($orientation, $section, $section);
    }

    return $result;
}

sub setupModelData
{
    my ($lines, $parent) = @_;
    my @parents = ( $parent );
    my @indentations = ( 0 );

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
            my $parent = $parents[-1];
            $parent->insertChildren($parent->childCount(), 1, this->{rootItem}->columnCount());
            for (my $column = 0; $column < scalar @columnData; ++$column) {
                $parent->child($parent->childCount() - 1)->setData($column, $columnData[$column]);
            }
        }

        $number++;
    }
}

1;
