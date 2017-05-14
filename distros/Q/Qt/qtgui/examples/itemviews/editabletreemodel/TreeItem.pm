package TreeItem;

=begin

    TreeItem.pm

    A container for items of data supplied by the simple tree model.

=cut

use strict;
use warnings;
use QtCore4;
use QtGui4;
use List::MoreUtils qw( first_index );

# [0]
    #Qt::List<TreeItem*> childItems;
    #Qt::Vector<Qt::Variant> itemData;
    #TreeItem *parentItem;
# [0]

# [0]
sub new
{
    my ($class, $data, $parent) = @_;
 
    $data = $data ? $data : [];

    return bless {
        parentItem => $parent,
        itemData => $data,
        childItems => [],
    }, $class;
}
# [0]

# [2]
sub child
{
    my ( $self, $number ) = @_;
    return $self->{childItems}->[$number];
}
# [2]

# [3]
sub childCount
{
    my ($self) = @_;
    return scalar @{$self->{childItems}};
}
# [3]

# [4]
sub childNumber
{
    my ($self) = @_;
    if (defined $self->{parentItem}) {
        return $self->{parentItem}->indexOf($self);
    }

    return 0;
}
# [4]

sub indexOf
{
    my ($self, $child) = @_;
    return first_index{ $_ == $child } @{$self->{childItems}};
}

# [5]
sub columnCount
{
    my ($self) = @_;
    return scalar @{$self->{itemData}};
}
# [5]

# [6]
sub data
{
    my ($self, $column) = @_;
    if(!$self->{itemData}->[$column]) {
    }
    return Qt::Variant($self->{itemData}->[$column]);
}
# [6]

# [7]
sub insertChildren
{
    my ($self, $position, $count, $columns) = @_;
    if ($position < 0 || $position > $self->childCount()) {
        return 0;
    }

    for (my $row = 0; $row < $count; ++$row) {
        my $data = [map{ Qt::Variant() } 0..$columns-1];
        my $item = TreeItem->new($data, $self);
        splice @{$self->{childItems}}, $position, 0, $item;
    }

    return 1;
}
# [7]

# [8]
sub insertColumns
{
    my ($self, $position, $columns) = @_;
    if ($position < 0 || $position > $self->columnCount()) {
        return 0;
    }

    for (my $column = 0; $column < $columns; ++$column) {
        splice @{$self->{itemData}}, $position, 0, Qt::Variant();
    }

    foreach my $child ( @{$self->{childItems}} ) {
        $child->insertColumns($position, $columns);
    }

    return 1;
}
# [8]

# [9]
sub parent
{
    my ($self) = @_;
    return $self->{parentItem};
}
# [9]

# [10]
sub removeChildren
{
    my ($self, $position, $count) = @_;
    if ($position < 0 || $position + $count > $self->childCount()) {
        return 0;
    }

    for (my $row = 0; $row < $count; ++$row) {
        splice @{$self->{childItems}}, $position, 1;
    }

    return 1;
}
# [10]

sub removeColumns
{
    my ($self, $position, $columns) = @_;
    if ($position < 0 || $position + $columns > $self->columnCount) {
        return 0;
    }

    for (my $column = 0; $column < $columns; ++$column) {
        splice @{$self->{itemData}}, $position, 1;
    }

    foreach my $child ( @{$self->{childItems}} ) {
        $child->removeColumns($position, $columns);
    }

    return 1;
}

# [11]
sub setData
{
    my ($self, $column, $value) = @_;
    if ($column < 0 || $column >= $self->columnCount()) {
        return 0;
    }

    $self->{itemData}->[$column] = $value;
    return 1;
}
# [11]

1;
