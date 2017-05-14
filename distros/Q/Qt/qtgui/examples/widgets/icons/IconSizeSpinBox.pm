package IconSizeSpinBox;

use strict;
use warnings;

use QtCore4;
use QtGui4;

# [0]
use QtCore4::isa qw( Qt::SpinBox );
# [0]

# [0]
sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
}
# [0]

# [1]
sub valueFromText {
    my ($text) = @_;

    my $regExp = Qt::RegExp(this->tr('(\\d+)(\\s*[xx]\\s*\\d+)?'));

    if ($regExp->exactMatch($text)) {
        return $regExp->cap(1);
    } else {
        return 0;
    }
}
# [1]

# [2]
sub textFromValue {
    my ( $value ) = @_;
    return sprintf this->tr('%d x %d'), $value, $value;
}
# [2]

1;
