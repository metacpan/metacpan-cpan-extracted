package ColorListEditor;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::ComboBox );
#Q_PROPERTY(Qt::Color color READ color WRITE setColor USER true)
# [0]

sub NEW
{
    my ( $class, $widget ) = @_;
    $class->SUPER::NEW( $widget );
    this->populateList();
}

# [0]
sub color
{
    return qVariantValue( this->itemData(this->currentIndex(), Qt::DecorationRole()), 'Qt::Color' );
}
# [0]

# [1]
sub setColor
{
    my ($color) = @_;
    this->setCurrentIndex(this->findData($color, ${Qt::DecorationRole()}));
}
# [1]

# [2]
sub populateList
{
    my $colorNames = Qt::Color::colorNames();

    foreach my $i (0..$#{$colorNames}) {
        my $color = Qt::Color($colorNames->[$i]);

        this->insertItem($i, $colorNames->[$i]);
        this->setItemData($i, $color, Qt::DecorationRole());
    }
}
# [2]

1;
