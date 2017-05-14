package TreeItem;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use List::MoreUtils qw( first_index );

    #Qt4::List<TreeItem*> childItems;
    #Qt4::List<Qt4::Variant> itemData;
    #TreeItem *parentItem;

# [0]
sub new
{
    my ($class, $data, $parent) = @_;
    my $self = bless {}, $class;
    $self->{parentItem} = $parent;
    $self->{itemData} = $data;
    $self->{childItems} = [];
    return $self;
}
# [0]

# [2]
sub appendChild
{
    my ($self, $item) = @_;
    push @{$self->{childItems}}, $item;
}
# [2]

# [3]
sub child
{
    my ($self, $row) = @_;
    return $self->{childItems}->[$row];
}
# [3]

# [4]
sub childCount
{
    my ($self) = @_;
    return scalar @{$self->{childItems}};
}
# [4]

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
    return $self->{itemData}->[$column];
}
# [6]

# [7]
sub parent
{
    my ($self) = @_;
    return $self->{parentItem};
}
# [7]

# [8]
sub row
{
    my ($self) = @_;
    if ($self->{parentItem}) {
        return $self->{parentItem}->indexOf($self);
    }

    return 0;
}
# [8]

sub indexOf {
    my ($self, $child) = @_;
    return first_index{ $_ == $child } @{$self->{childItems}};
}

1;
