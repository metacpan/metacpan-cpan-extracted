package DomItem;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use Scalar::Util qw(reftype);
# [0]
sub domNode() {
    my ( $self ) = @_;
    return $self->{domNode};
}

sub setDomNode {
    my ( $self, $val ) = @_;
    return $self->{domNode} = $val;
}

sub childItems() {
    return shift->{childItems};
}

sub setChildItems {
    my ( $self, $val ) = @_;
    return $self->{childItems} = $val;
}

sub parentItem() {
    return shift->{parentItem};
}

sub setParentItem {
    my ( $self, $val ) = @_;
    return $self->{parentItem} = $val;
}

sub rowNumber() {
    return shift->{rowNumber};
}

sub setRowNumber {
    my ( $self, $val ) = @_;
    return $self->{rowNumber} = $val;
}
# [0]

# [0]
sub new
{
    my ($class, $node, $row, $parent) = @_;
    my $self = bless {}, $class;
    $self->setDomNode( $node );
# [0]
    # Record the item's location within its parent.
# [1]
    $self->setRowNumber( $row );
    $self->setParentItem( $parent );
    $self->setChildItems( {} );
    return $self;
}
# [1]

# [3]
sub node
{
    my ( $self ) = @_;
    return $self->domNode;
}
# [3]

# [4]
sub parent
{
    my ( $self ) = @_;
    return $self->parentItem;
}
# [4]

# [5]
sub child
{
    my ( $self, $i ) = @_;
    if (defined $self->childItems->{$i}) {
        return $self->childItems->{$i};
    }

    if ($i >= 0 && $i < $self->domNode->childNodes()->count()) {
        my $childNode = $self->domNode->childNodes()->item($i);
        my $childItem = DomItem->new($childNode, $i, $self);
        $self->childItems->{$i} = $childItem;
        return $childItem;
    }
    return 0;
}
# [5]

# [6]
sub row
{
    my ( $self ) = @_;
    return $self->rowNumber;
}
# [6]

1;
