package DirModel;
use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::DirModel );

# With a Qt::DirModel, set on a view, you will see 'Program Files' in the view
# But with this model, you will see 'C:\Program Files' in the view.
# We acheive this, by having the data() return the entire file path for
# the display role. Note that the Qt::EditRole over which the Qt::Completer
# looks for matches is left unchanged

# [0]
sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
}
# [0]

# [1]
sub data
{
    my ($index, $role) = @_;
    if ($role == Qt::DisplayRole() && $index->column() == 0) {
        my $path = Qt::Dir::toNativeSeparators(this->filePath($index));
        if ( substr( $path, -1 ) eq chr( Qt::Dir::separator()->toAscii() ) ) {
            chop $path;
        }
        return Qt::Variant(Qt::String($path));
    }

    return this->SUPER::data($index, $role);
}
# [1]

1;
