package ArrowPad;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );

sub upButton() {
    return this->{upButton};
}

sub downButton() {
    return this->{downButton};
}

sub leftButton() {
    return this->{leftButton};
}

sub rightButton() {
    return this->{rightButton};
}

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW( $parent );
# [0]
    this->{upButton} = Qt::PushButton(ArrowPad::tr("&Up"));
# [0] //! [1]
    this->{downButton} = Qt::PushButton(ArrowPad::tr("&Down"));
# [1] //! [2]
    this->{leftButton} = Qt::PushButton(ArrowPad::tr("&Left"));
# [2] //! [3]
    this->{rightButton} = Qt::PushButton(ArrowPad::tr("&Right"));
# [3]

    my $mainLayout = Qt::GridLayout();
    $mainLayout->addWidget(this->upButton, 0, 1);
    $mainLayout->addWidget(this->leftButton, 1, 0);
    $mainLayout->addWidget(this->rightButton, 1, 2);
    $mainLayout->addWidget(this->downButton, 2, 1);
    this->setLayout($mainLayout);
}

1;
