package DragLabel;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Label );

sub NEW
{
    my ($class, $text, $parent) = @_;
    $class->SUPER::NEW( $text, $parent );
    this->setAutoFillBackground(1);
    this->setFrameShape(Qt::Frame::Panel());
    this->setFrameShadow(Qt::Frame::Raised());
}

1;
