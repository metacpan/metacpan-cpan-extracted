package ShapeItem;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Object );
# [0]
sub myPath() {
    return this->{myPath};
}

sub myPosition() {
    return this->{myPosition};
}

sub myColor() {
    return this->{myColor};
}

sub myToolTip() {
    return this->{myToolTip};
}
# [0]

sub NEW {
    shift->SUPER::NEW();
}

# [0]
sub path() {
    return this->myPath;
}
# [0]

# [1]
sub position() {
    return this->myPosition;
}
# [1]

# [2]
sub color() {
    return this->myColor;
}
# [2]

# [3]
sub toolTip() {
    return this->myToolTip;
}
# [3]

# [4]
sub setPath {
    this->{myPath} = shift;
}
# [4]

# [5]
sub setToolTip {
    this->{myToolTip} = shift;
}
# [5]

# [6]
sub setPosition {
    this->{myPosition} = shift;
}
# [6]

# [7]
sub setColor {
    this->{myColor} = shift;
}
# [7]

1;
