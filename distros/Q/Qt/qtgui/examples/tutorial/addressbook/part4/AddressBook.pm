package AddressBook;

use strict;
use warnings;
use QtCore4;
use QtGui4;

use QtCore4::isa qw( Qt::Widget );

# [Mode enum]
use constant {
    NavigationMode => 0,
    AddingMode => 1,
    EditingMode => 2 };
# [Mode enum]

use QtCore4::slots
    addContact => [],
    submitContact => [],
    cancel => [],
# [edit and remove slots]
    editContact => [],
    removeContact => [],
# [edit and remove slots]
    next => [],
    previous => [];

sub NEW
{
    my ($class, $package) = @_;
    $class->SUPER::NEW($package);
    my $nameLabel = Qt::Label(this->tr('Name:'));
    this->{nameLine} = Qt::LineEdit();
    this->{nameLine}->setReadOnly(1);

    my $addressLabel = Qt::Label(this->tr('Address:'));
    this->{addressText} = Qt::TextEdit();
    this->{addressText}->setReadOnly(1);

    this->{addButton} = Qt::PushButton(this->tr('&Add'));
# [edit and remove buttons] 
    this->{editButton} = Qt::PushButton(this->tr('&Edit'));
    this->{editButton}->setEnabled(0);
    this->{removeButton} = Qt::PushButton(this->tr('&Remove'));
    this->{removeButton}->setEnabled(0);
# [edit and remove buttons] 
    this->{submitButton} = Qt::PushButton(this->tr('&Submit'));
    this->{submitButton}->hide();
    this->{cancelButton} = Qt::PushButton(this->tr('&Cancel'));
    this->{cancelButton}->hide();
    
    this->{nextButton} = Qt::PushButton(this->tr('&Next'));
    this->{nextButton}->setEnabled(0);
    this->{previousButton} = Qt::PushButton(this->tr('&Previous'));
    this->{previousButton}->setEnabled(0);

    this->{order} = 0;

    this->connect(this->{addButton}, SIGNAL 'clicked()', this, SLOT 'addContact()');
    this->connect(this->{submitButton}, SIGNAL 'clicked()', this, SLOT 'submitContact()');
# [connecting edit and remove] 
    this->connect(this->{editButton}, SIGNAL 'clicked()', this, SLOT 'editContact()');
    this->connect(this->{removeButton}, SIGNAL 'clicked()', this, SLOT 'removeContact()');
# [connecting edit and remove] 
    this->connect(this->{cancelButton}, SIGNAL 'clicked()', this, SLOT 'cancel()');
    this->connect(this->{nextButton}, SIGNAL 'clicked()', this, SLOT 'next()');
    this->connect(this->{previousButton}, SIGNAL 'clicked()', this, SLOT 'previous()');

    my $buttonLayout1 = Qt::VBoxLayout();
    $buttonLayout1->addWidget(this->{addButton});
# [adding edit and remove to the layout]     
    $buttonLayout1->addWidget(this->{editButton});
    $buttonLayout1->addWidget(this->{removeButton});
# [adding edit and remove to the layout]         
    $buttonLayout1->addWidget(this->{submitButton});
    $buttonLayout1->addWidget(this->{cancelButton});
    $buttonLayout1->addStretch();

    my $buttonLayout2 = Qt::HBoxLayout();
    $buttonLayout2->addWidget(this->{previousButton});
    $buttonLayout2->addWidget(this->{nextButton});

    my $mainLayout = Qt::GridLayout();
    $mainLayout->addWidget($nameLabel, 0, 0);
    $mainLayout->addWidget(this->{nameLine}, 0, 1);
    $mainLayout->addWidget($addressLabel, 1, 0, Qt::AlignTop());
    $mainLayout->addWidget(this->{addressText}, 1, 1);
    $mainLayout->addLayout($buttonLayout1, 1, 2);
    $mainLayout->addLayout($buttonLayout2, 3, 1);

    this->setLayout($mainLayout);
    this->setWindowTitle(this->tr('Simple Address Book'));
}

sub addContact
{
    this->{oldName} = this->{nameLine}->text();
    this->{oldAddress} = this->{addressText}->toPlainText();

    this->{nameLine}->clear();
    this->{addressText}->clear();

    this->updateInterface(AddingMode);
}
# [editContact() function]
sub editContact
{
    this->{oldName} = this->{nameLine}->text();
    this->{oldAddress} = this->{addressText}->toPlainText();

    this->updateInterface(EditingMode);
}
# [editContact() function]
# [submitContact() function beginning]
sub submitContact
{
# [submitContact() function beginning]
    my $name = this->{nameLine}->text();
    my $address = this->{addressText}->toPlainText();

    if ($name eq '' || $address eq '') {
        Qt::MessageBox::information(this, this->tr('Empty Field'),
            this->tr('Please enter a name and address.'));
    }
# [submitContact() function part1]
    if (this->{currentMode} == AddingMode) {
        
        if (!exists this->{contacts}->{$name}) {
            my $order = this->{order};
            ++$order if grep { this->{contacts}->{$_}->{order} == $order } keys %{this->{contacts}};
            my @toInc = grep { this->{contacts}->{$_}->{order} >= $order } keys %{this->{contacts}};
            map{ this->{contacts}->{$_}->{order}++ } @toInc;
            this->{contacts}->{$name}->{address} = $address;
            this->{contacts}->{$name}->{order} = $order;

            this->{order} = $order + 1;

            Qt::MessageBox::information(this, this->tr('Add Successful'),
                sprintf this->tr('\'%s\' has been added to your address book.'), $name);
        } else {
            Qt::MessageBox::information(this, this->tr('Add Unsuccessful'),
                sprintf this->tr('Sorry, \'%1\' is already in your address book.'), $name);
        }
# [submitContact() function part1]
# [submitContact() function part2]
    } elsif (this->{currentMode} == EditingMode) {
        
        if (this->{oldName} ne $name) {
            if (!exists this->{contacts}->{$name}) {
                Qt::MessageBox::information(this, this->tr('Edit Successful'),
                    sprintf this->tr('\'%s\' has been edited in your address book.'), this->{oldName});
                this->{contacts}->{$name}->{address} = $address;
            } else {
                Qt::MessageBox::information(this, this->tr('Edit Unsuccessful'),
                    sprintf this->tr('Sorry, \'%s\' is already in your address book.'), $name);
            }
        } elsif (this->{oldAddress} ne $address) {
            Qt::MessageBox::information(this, this->tr('Edit Successful'),
                sprintf this->tr('\'%s\' has been edited in your address book.'), $name);
            this->{contacts}->{$name}->{address} = $address; 
        }
    }

    this->updateInterface(NavigationMode);
}
# [submitContact() function part2]

sub cancel
{
    this->{nameLine}->setText(this->{oldName});
    this->{addressText}->setText(this->{oldAddress});
    this->updateInterface(NavigationMode);
}
# [removeContact() function]
sub removeContact
{
    my $name = this->{nameLine}->text();
    my $address = this->{addressText}->toPlainText();

    if (exists this->{contacts}->{$name}) {

        my $button = Qt::MessageBox::question(this,
            this->tr('Confirm Remove'),
            sprintf( this->tr('Are you sure you want to remove \'%s\'?'), $name ),
            Qt::MessageBox::Yes() | Qt::MessageBox::No());

        if ($button == Qt::MessageBox::Yes()) {
            
            this->previous();
            my $order = this->{contacts}->{$name}->{order};
            delete this->{contacts}->{$name};
            my @toDec = grep { this->{contacts}->{$_}->{order} >= $order } keys %{this->{contacts}};
            map{ this->{contacts}->{$_}->{order}-- } @toDec;
            if ( this->{order} == 0 ) {
                this->{order} = scalar keys %{this->{contacts}} - 1;
            }
            else {
                --(this->{order});
            };

            Qt::MessageBox::information(this, this->tr('Remove Successful'),
                sprintf this->tr('\'%s\' has been removed from your address book.'), $name);
        }
    }

    this->updateInterface(NavigationMode);
}
# [removeContact() function]
sub next
{
    my $name = this->{nameLine}->text();
    my $i = this->{contacts}->{$name}->{order};

    if ($i != scalar( keys %{this->{contacts}} )-1) {
        $i++;
    }
    else {
        $i = 0;
    }

    my ($newName) = grep { this->{contacts}->{$_}->{order} == $i } keys %{this->{contacts}};
    this->{nameLine}->setText($newName);
    this->{addressText}->setText(this->{contacts}->{$newName}->{address});
}

sub previous
{
    my $name = this->{nameLine}->text();
    my $i = this->{contacts}->{$name}->{order};

    if ($i == 0) {
        $i = scalar( keys %{this->{contacts}} )-1;
    }
    else {
        $i--;
    }

    my ($newName) = grep { this->{contacts}->{$_}->{order} == $i } keys %{this->{contacts}};
    this->{nameLine}->setText($newName);
    this->{addressText}->setText(this->{contacts}->{$newName}->{address});
}

# [update interface() part 1]
sub updateInterface
{
    my ($mode) = @_;
    this->{currentMode} = $mode;

    if ($mode == AddingMode || $mode == EditingMode) {
        this->{nameLine}->setReadOnly(0);
        this->{nameLine}->setFocus(Qt::OtherFocusReason());
        this->{addressText}->setReadOnly(0);

        this->{addButton}->setEnabled(0);
        this->{editButton}->setEnabled(0);
        this->{removeButton}->setEnabled(0);

        this->{nextButton}->setEnabled(0);
        this->{previousButton}->setEnabled(0);

        this->{submitButton}->show();
        this->{cancelButton}->show();
    }
    elsif ($mode == NavigationMode) {
# [update interface() part 1]
# [update interface() part 2]
        if (scalar keys %{this->{contacts}} == 0) {
            this->{nameLine}->clear();
            this->{addressText}->clear();
        }

        this->{nameLine}->setReadOnly(1);
        this->{addressText}->setReadOnly(1);
        this->{addButton}->setEnabled(1);

        my $number = scalar( keys %{this->{contacts}} );
        this->{editButton}->setEnabled($number >= 1);
        this->{removeButton}->setEnabled($number >= 1);
        this->{nextButton}->setEnabled($number > 1);
        this->{previousButton}->setEnabled($number >1 );

        this->{submitButton}->hide();
        this->{cancelButton}->hide();
    }
}
# [update interface() part 2]

1;
