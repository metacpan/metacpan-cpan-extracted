package AddDialog;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Dialog );

sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );

    my $nameLabel = Qt::Label("Name");
    my $addressLabel = Qt::Label("Address");
    my $okButton = Qt::PushButton("OK");
    my $cancelButton = Qt::PushButton("Cancel");
    
    my $nameText = Qt::LineEdit();
    my $addressText = Qt::TextEdit();

    this->{nameLabel}    = $nameLabel;
    this->{addressLabel} = $addressLabel;
    this->{okButton}     = $okButton;
    this->{cancelButton} = $cancelButton;
    this->{nameText}     = $nameText;
    this->{addressText}  = $addressText;
    
    my $gLayout = Qt::GridLayout();
    $gLayout->setColumnStretch(1, 2);
    $gLayout->addWidget($nameLabel, 0, 0);
    $gLayout->addWidget($nameText, 0, 1);
    
    $gLayout->addWidget($addressLabel, 1, 0, Qt::AlignLeft()|Qt::AlignTop());
    $gLayout->addWidget($addressText, 1, 1, Qt::AlignLeft());
    
    my $buttonLayout = Qt::HBoxLayout();
    $buttonLayout->addWidget($okButton);
    $buttonLayout->addWidget($cancelButton);
    
    $gLayout->addLayout($buttonLayout, 2, 1, Qt::AlignRight());
    
    my $mainLayout = Qt::VBoxLayout();
    $mainLayout->addLayout($gLayout);
    this->setLayout($mainLayout);
    
    this->connect($okButton, SIGNAL 'clicked()',
            this, SLOT 'accept()');
            
    this->connect($cancelButton, SIGNAL 'clicked()',
            this, SLOT 'reject()');
            
    this->setWindowTitle(this->tr('Add a Contact'));
}

sub nameText {
    return this->{nameText};
}

sub addressText {
    return this->{addressText};
}

1;
