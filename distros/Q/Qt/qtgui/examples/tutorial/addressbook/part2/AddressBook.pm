package AddressBook;

use strict;
use warnings;
use QtCore4;
use QtGui4;

use QtCore4::isa qw( Qt::Widget );
# [slots]
use QtCore4::slots
    addContact => [],
    submitContact => [],
    cancel => [];
# [slots]

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    my $nameLabel = Qt::Label(this->tr('Name:'));
    this->{nameLine} = Qt::LineEdit();
# [setting readonly 1]
    this->{nameLine}->setReadOnly(1);
# [setting readonly 1]
    my $addressLabel = Qt::Label(this->tr('Address:'));
    this->{addressText} = Qt::TextEdit();
# [setting readonly 2]    
    this->{addressText}->setReadOnly(1);
# [setting readonly 2]
   
# [pushbutton declaration]
    this->{addButton} = Qt::PushButton(this->tr('&Add'));
    this->{addButton}->show();
    this->{submitButton} = Qt::PushButton(this->tr('&Submit'));
    this->{submitButton}->hide();
    this->{cancelButton} = Qt::PushButton(this->tr('&Cancel'));
    this->{cancelButton}->hide();
# [pushbutton declaration]
# [connecting signals and slots]
    this->connect(this->{addButton}, SIGNAL 'clicked()', this, SLOT 'addContact()');
    this->connect(this->{submitButton}, SIGNAL 'clicked()', this, SLOT 'submitContact()');
    this->connect(this->{cancelButton}, SIGNAL 'clicked()', this, SLOT 'cancel()');
# [connecting signals and slots]
# [vertical layout]
    my $buttonLayout1 = Qt::VBoxLayout();
    $buttonLayout1->addWidget(this->{addButton}, Qt::AlignTop());
    $buttonLayout1->addWidget(this->{submitButton});
    $buttonLayout1->addWidget(this->{cancelButton});
    $buttonLayout1->addStretch();
# [vertical layout]
# [grid layout]
    my $mainLayout = Qt::GridLayout();
    $mainLayout->addWidget($nameLabel, 0, 0);
    $mainLayout->addWidget(this->{nameLine}, 0, 1);
    $mainLayout->addWidget($addressLabel, 1, 0, Qt::AlignTop());
    $mainLayout->addWidget(this->{addressText}, 1, 1);
    $mainLayout->addLayout($buttonLayout1, 1, 2);
# [grid layout]
    this->setLayout($mainLayout);
    this->setWindowTitle(this->tr('Simple Address Book'));
}
# [addContact]
sub addContact
{
    this->{oldName} = this->{nameLine}->text();
    this->{oldAddress} = this->{addressText}->toPlainText();

    this->{nameLine}->clear();
    this->{addressText}->clear();
    
    this->{nameLine}->setReadOnly(0);
    this->{nameLine}->setFocus(Qt::OtherFocusReason());
    this->{addressText}->setReadOnly(0);

    this->{addButton}->setEnabled(0);
    this->{submitButton}->show();
    this->{cancelButton}->show();
}
# [addContact]

# [submitContact part1]
sub submitContact
{
    my $name = this->{nameLine}->text();
    my $address = this->{addressText}->toPlainText();
    
    if ($name eq '' || $address eq '') {
        Qt::MessageBox::information(this, this->tr('Empty Field'),
            this->tr('Please enter a name and address.'));
        return;
    }
# [submitContact part1]
# [submitContact part2]
    if (!exists this->{contacts}->{$name}) {
        this->{contacts}->{$name} = $address;
        Qt::MessageBox::information(this, this->tr('Add Successful'),
            sprintf this->tr('\'%s\' has been added to your address book.'), $name);
    } else {
        Qt::MessageBox::information(this, this->tr('Add Unsuccessful'),
            sprintf this->tr('Sorry, \'%s\' is already in your address book.'), $name);
        return;
    }
# [submitContact part2]
# [submitContact part3]
    if (scalar keys %{this->{contacts}} == 0) {
        this->{nameLine}->clear();
        this->{addressText}->clear();
    }

    this->{nameLine}->setReadOnly(1);
    this->{addressText}->setReadOnly(1);
    this->{addButton}->setEnabled(1);
    this->{submitButton}->hide();
    this->{cancelButton}->hide();
}
# [submitContact part3]
# [cancel]
sub cancel
{
    this->{nameLine}->setText(this->{oldName});
    this->{nameLine}->setReadOnly(1);

    this->{addressText}->setText(this->{oldAddress});
    this->{addressText}->setReadOnly(1);

    this->{addButton}->setEnabled(1);
    this->{submitButton}->hide();
    this->{cancelButton}->hide();    
}
# [cancel]

1;
