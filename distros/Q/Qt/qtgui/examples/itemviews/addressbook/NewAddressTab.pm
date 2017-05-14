package NewAddressTab;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    addEntry => [];

use QtCore4::signals
    sendDetails => ['QString', 'QString'];

use AddDialog;

sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );

    my $descriptionLabel = Qt::Label(this->tr('There are currently no contacts in your address book. ' .
                                      "\nClick Add to add new contacts."));
    
    my $addButton = Qt::PushButton(this->tr('Add'));
    
    this->connect($addButton, SIGNAL 'clicked()', this, SLOT 'addEntry()');
    
    my $mainLayout = Qt::VBoxLayout();
    $mainLayout->addWidget($descriptionLabel);
    $mainLayout->addWidget($addButton, 0, Qt::AlignCenter());
    
    this->setLayout($mainLayout);
}

sub addEntry {
    my $aDialog = AddDialog();
    
    if ($aDialog->exec()) {
        my $name = $aDialog->nameText()->text();
        my $address = $aDialog->addressText()->toPlainText();
        
        emit sendDetails($name, $address);
    }
}

1;
