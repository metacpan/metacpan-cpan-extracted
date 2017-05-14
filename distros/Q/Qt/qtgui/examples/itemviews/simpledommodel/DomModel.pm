package DomModel;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtXml4;
# [0]
use QtCore4::isa qw( Qt::AbstractItemModel );
use DomItem;

sub domDocument() {
    return this->{domDocument};
}

sub setDomDocument($) {
    return this->{domDocument} = shift;
}

sub rootItem() {
    return this->{rootItem};
}

sub setRootItem($) {
    return this->{rootItem} = shift;
}

# [0]

# [0]
sub NEW {
    my ( $class, $document, $parent ) = @_;
    $class->SUPER::NEW( $parent );
    this->setDomDocument( $document );
    this->setRootItem( DomItem->new(this->domDocument, 0) );
}
# [0]

# [2]
sub columnCount
{
    return 3;
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

    my $node = $item->node();
# [3] //! [4]
    my $attributes = [];
    my $attributeMap = $node->attributes();

    if ($index->column() == 0) {
        return Qt::Variant(Qt::String($node->nodeName()));
    }
    elsif ($index->column() == 1) {
        for (my $i = 0; $i < $attributeMap->count(); ++$i) {
            my $attribute = $attributeMap->item($i);
            my $nodeName = $attribute->nodeName();
            my $nodeValue = $attribute->nodeValue();
            $nodeName = $nodeName ? $nodeName : '';
            $nodeValue = $nodeValue ? $nodeValue : '';
            push @{$attributes}, $nodeName . '="'
                          .$nodeValue . '"';
        }
        return Qt::Variant(Qt::String(join ' ', @{$attributes}));
    }
    elsif ($index->column() == 2) {
        return Qt::Variant() unless $node->nodeValue();
        return Qt::Variant(Qt::String(join ' ', split "\n", $node->nodeValue() ));
    }
    else {
        return Qt::Variant();
    }
}
# [4]

# [5]
sub flags
{
    my ($index) = @_;
    if (!$index->isValid()) {
        return 0;
    }

    return Qt::ItemIsEnabled() | Qt::ItemIsSelectable();
}
# [5]

# [6]
sub headerData
{
    my ($section, $orientation, $role) = @_;
    if ($orientation == Qt::Horizontal() && $role == Qt::DisplayRole()) {
        if ($section == 0) {
            return Qt::Variant(Qt::String(this->tr('Name')));
        }
        elsif ($section == 1) {
            return Qt::Variant(Qt::String(this->tr('Attributes')));
        }
        elsif ($section == 2) {
            return Qt::Variant(Qt::String(this->tr('Value')));
        }
        else {
            return Qt::Variant();
        }
    }

    return Qt::Variant();
}
# [6]

# [7]
sub index
{
    my ($row, $column, $parent) = @_;
    if (!this->hasIndex($row, $column, $parent)) {
        return Qt::ModelIndex();
    }

    my $parentItem = DomItem->new();

    if (!$parent->isValid()) {
        $parentItem = this->rootItem;
    }
    else {
        $parentItem = $parent->internalPointer();
    }
# [7]

# [8]
    my $childItem = $parentItem->child($row);
    if ($childItem) {
        my $ret = this->createIndex($row, $column, $childItem);
        return $ret;
    }
    else {
        return Qt::ModelIndex();
    }
}
# [8]

# [9]
sub parent
{
    my ($child) = @_;
    return unless $child;
    if (!$child->isValid()) {
        return Qt::ModelIndex();
    }

    my $childItem = $child->internalPointer();
    my $parentItem = $childItem->parent();

    if (!$parentItem || $parentItem == this->rootItem) {
        return Qt::ModelIndex();
    }

    return this->createIndex($parentItem->row(), 0, $parentItem);
}
# [9]

# [10]
sub rowCount
{
    my ($parent) = @_;
    if ($parent->column() > 0) {
        return 0;
    }

    my $parentItem = DomItem->new();

    if (!$parent->isValid()) {
        $parentItem = this->rootItem;
    }
    else {
        $parentItem = $parent->internalPointer();
    }

    return scalar $parentItem->node()->childNodes()->count();
}
# [10]

1;
