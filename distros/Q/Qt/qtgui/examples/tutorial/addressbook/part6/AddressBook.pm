package AddressBook;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use FindDialog;

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
    editContact => [],
    removeContact => [],
    next => [],
    previous => [],
    findContact => [],
#!  [save and load functions declaration]
    saveToFile => [],
    loadFromFile => [];

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
    this->{editButton} = Qt::PushButton(this->tr('&Edit'));
    this->{editButton}->setEnabled(0);
    this->{removeButton} = Qt::PushButton(this->tr('&Remove'));
    this->{removeButton}->setEnabled(0);
    this->{findButton} = Qt::PushButton(this->tr("&Find"));
    this->{findButton}->setEnabled(0);
    this->{submitButton} = Qt::PushButton(this->tr('&Submit'));
    this->{submitButton}->hide();
    this->{cancelButton} = Qt::PushButton(this->tr('&Cancel'));
    this->{cancelButton}->hide();
    
    this->{nextButton} = Qt::PushButton(this->tr('&Next'));
    this->{nextButton}->setEnabled(0);
    this->{previousButton} = Qt::PushButton(this->tr('&Previous'));
    this->{previousButton}->setEnabled(0);

    this->{loadButton} = Qt::PushButton(this->tr("&Load..."));
#!  [tooltip 1]    
    this->{loadButton}->setToolTip(this->tr("Load contacts from a file"));
#!  [tooltip 1]        
    this->{saveButton} = Qt::PushButton(this->tr("Sa&ve..."));
#!  [tooltip 2]
    this->{saveButton}->setToolTip(this->tr("Save contacts to a file"));
#!  [tooltip 2]
    this->{saveButton}->setEnabled(0);

    this->{dialog} = FindDialog(this);

    this->{order} = 0;

    this->connect(this->{addButton}, SIGNAL 'clicked()', this, SLOT 'addContact()');
    this->connect(this->{submitButton}, SIGNAL 'clicked()', this, SLOT 'submitContact()');
    this->connect(this->{editButton}, SIGNAL 'clicked()', this, SLOT 'editContact()');
    this->connect(this->{removeButton}, SIGNAL 'clicked()', this, SLOT 'removeContact()');
    this->connect(this->{cancelButton}, SIGNAL 'clicked()', this, SLOT 'cancel()');
    this->connect(this->{nextButton}, SIGNAL 'clicked()', this, SLOT 'next()');
    this->connect(this->{previousButton}, SIGNAL 'clicked()', this, SLOT 'previous()');
    this->connect(this->{findButton}, SIGNAL 'clicked()', this, SLOT 'findContact()');
    this->connect(this->{loadButton}, SIGNAL 'clicked()', this, SLOT 'loadFromFile()');
    this->connect(this->{saveButton}, SIGNAL 'clicked()', this, SLOT 'saveToFile()');


    my $buttonLayout1 = Qt::VBoxLayout();
    $buttonLayout1->addWidget(this->{addButton});
    $buttonLayout1->addWidget(this->{editButton});
    $buttonLayout1->addWidget(this->{removeButton});
    $buttonLayout1->addWidget(this->{findButton});
    $buttonLayout1->addWidget(this->{submitButton});
    $buttonLayout1->addWidget(this->{cancelButton});
    $buttonLayout1->addWidget(this->{loadButton});
    $buttonLayout1->addWidget(this->{saveButton});
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
sub editContact
{
    this->{oldName} = this->{nameLine}->text();
    this->{oldAddress} = this->{addressText}->toPlainText();

    this->updateInterface(EditingMode);
}

sub submitContact
{
    my $name = this->{nameLine}->text();
    my $address = this->{addressText}->toPlainText();

    if ($name eq '' || $address eq '') {
        Qt::MessageBox::information(this, this->tr('Empty Field'),
            this->tr('Please enter a name and address.'));
    }
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

sub cancel
{
    this->{nameLine}->setText(this->{oldName});
    this->{addressText}->setText(this->{oldAddress});
    this->updateInterface(NavigationMode);
}
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
            }

            Qt::MessageBox::information(this, this->tr('Remove Successful'),
                sprintf this->tr('\'%s\' has been removed from your address book.'), $name);
        }
    }

    this->updateInterface(NavigationMode);
}

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

sub findContact {
    this->{dialog}->show();

    if (this->{dialog}->exec() == 1) {
        my $contactName = this->{dialog}->getFindText();

        if (exists this->{contacts}->{$contactName}) {
            this->{nameLine}->setText($contactName);
            this->{addressText}->setText(this->{contacts}->{$contactName}->{address});
        } else {
            Qt::MessageBox::information(this, this->tr("Contact Not Found"),
                sprintf this->tr("Sorry, \"%s\" is not in your address book."), $contactName);
            return;
        }
    }

    this->updateInterface(NavigationMode);
}

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

        this->{loadButton}->setEnabled(0);
        this->{saveButton}->setEnabled(0);
    }
    elsif ($mode == NavigationMode) {
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
        this->{findButton}->setEnabled($number > 2);
        this->{nextButton}->setEnabled($number > 1);
        this->{previousButton}->setEnabled($number >1 );

        this->{submitButton}->hide();
        this->{cancelButton}->hide();

        this->{loadButton}->setEnabled(1);
        this->{saveButton}->setEnabled($number >= 1);
    }
}

# [saveToFile() function part1]
sub saveToFile
{
    my $fileName = Qt::FileDialog::getSaveFileName(this,
        this->tr('Save Address Book'), '',
        this->tr('Address Book (*.abk);;All Files (*)'));

# [saveToFile() function part1]
# [saveToFile() function part2]
    if (!$fileName) {
        return;
    }
    else {
        my $file = Qt::File($fileName);
        if (!$file->open(Qt::IODevice::WriteOnly())) {
            Qt::MessageBox::information(this, this->tr('Unable to open file'),
                $file->errorString());
            return;
        }

# [saveToFile() function part2]        
# [saveToFile() function part3]
        my $out = Qt::DataStream($file);
        $out->setVersion(Qt::DataStream::Qt_4_5());
        no warnings qw(void);
        $out << [keys %{this->{contacts}}];
        $out << [map{ keys %{$_} } values %{this->{contacts}}];
        $out << [map{ values %{$_} } values %{this->{contacts}}];
        use warnings;
        $file->close();
    }       
}
# [saveToFile() function part3]

# [loadFromFile() function part1]
sub loadFromFile
{
    my $fileName = Qt::FileDialog::getOpenFileName(this,
        this->tr('Open Address Book'), '',
        this->tr('Address Book (*.abk);;All Files (*)'));
# [loadFromFile() function part1]

# [loadFromFile() function part2]
    if (!$fileName) {
        return;
    }
    else {
        
        my $file = Qt::File($fileName);
        
        if (!$file->open(Qt::IODevice::ReadOnly())) {
            Qt::MessageBox::information(this, this->tr('Unable to open file'),
                $file->errorString());
            return;
        }
        
        my $in = Qt::DataStream($file);
        $in->setVersion(Qt::DataStream::Qt_4_5());
        my @keys;
        my @valuekeys;
        my @valuevalues;
        no warnings qw(void);
        $in >> \@keys;
        $in >> \@valuekeys;
        $in >> \@valuevalues;
        use warnings;
        @{this->{contacts}}{@keys} = map{ {$valuekeys[$_*2] => $valuevalues[$_*2], $valuekeys[$_*2+1] => $valuevalues[$_*2+1]} } 0..((@valuevalues-1)/2);
# [loadFromFile() function part2]

# [loadFromFile() function part3]
        if (scalar keys %{this->{contacts}} == 0) {
            Qt::MessageBox::information(this, this->tr('No contacts in file'),
                this->tr('The file you are attempting to open contains no contacts.'));
        } else {
            this->{nameLine}->setText((keys %{this->{contacts}})[0]);
            this->{addressText}->setText((values %{this->{contacts}})[0]->{address});
        }
        $file->close();
    }

    this->updateInterface(NavigationMode);
}
# [loadFromFile() function part3]

1;
