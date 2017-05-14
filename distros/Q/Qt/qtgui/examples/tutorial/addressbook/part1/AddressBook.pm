package AddressBook;

use strict;
use warnings;
use QtCore4;
use QtGui4;

# [class definition]
use QtCore4::isa qw( Qt::Widget );
# [class definition]

# [constructor and input fields]
sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    my $nameLabel = Qt::Label(this->tr('Name:'));
    this->{nameLine} = Qt::LineEdit();

    my $addressLabel = Qt::Label(this->tr('Address:'));
    this->{addressText} = Qt::TextEdit();
# [constructor and input fields]

# [layout]
    my $mainLayout = Qt::GridLayout();
    $mainLayout->addWidget($nameLabel, 0, 0);
    $mainLayout->addWidget(this->{nameLine}, 0, 1);
    $mainLayout->addWidget($addressLabel, 1, 0, Qt::AlignTop());
    $mainLayout->addWidget(this->{addressText}, 1, 1);
# [layout]

#[setting the layout]    
    this->setLayout($mainLayout);
    this->setWindowTitle(this->tr('Simple Address Book'));
}
# [setting the layout]

1;
