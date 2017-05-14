package ImageModel;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::AbstractTableModel );

sub modelImage() {
    return this->{modelImage};
}

# [0]
sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    setImage(Qt::Image());
}
# [0]

# [1]
sub setImage
{
    my ($image) = @_;
    this->{modelImage} = $image;
    this->reset();
}
# [1]

# [2]
sub rowCount
{
    return modelImage->height();
}

sub columnCount
# [2] //! [3]
{
    return modelImage->width();
}
# [3]

# [4]
sub data
{
    my ($index, $role) = @_;
    if (!$index->isValid() || $role != Qt::DisplayRole()) {
        return Qt::Variant();
    }
    return Qt::Variant(Qt::Int(Qt::GlobalSpace::qGray(modelImage->pixel($index->column(), $index->row()))));
}
# [4]

# [5]
sub headerData
{
    my ($section, $orientation, $role) = @_;
    if ($role == Qt::SizeHintRole()) {
        return Qt::Variant( Qt::Size(1, 1) );
    }
    return Qt::Variant();
}
# [5]

1;
