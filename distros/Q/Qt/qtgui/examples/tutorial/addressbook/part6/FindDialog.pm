package FindDialog;

use strict;
use warnings;
use QtCore4;
use QtGui4;

use QtCore4::isa qw( Qt::Dialog );
use QtCore4::slots
    findClicked => [];

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    my $findLabel = Qt::Label(this->tr('Enter the name of a contact:'));
    this->{lineEdit} = Qt::LineEdit();

    this->{findButton} = Qt::PushButton(this->tr('&Find'));
    this->{findText} = '';

    my $layout = Qt::HBoxLayout();
    $layout->addWidget($findLabel);
    $layout->addWidget(this->{lineEdit});
    $layout->addWidget(this->{findButton});

    this->setLayout($layout);
    this->setWindowTitle(this->tr('Find a Contact'));
    this->connect(this->{findButton}, SIGNAL 'clicked()', this, SLOT 'findClicked()');
    this->connect(this->{findButton}, SIGNAL 'clicked()', this, SLOT 'accept()');
}

sub findClicked
{
    my $text = this->{lineEdit}->text();

    if (!$text) {
        Qt::MessageBox::information(this, this->tr('Empty Field'),
            this->tr('Please enter a name.'));
        return;
    } else {
        this->{findText} = $text;
        this->{lineEdit}->clear();
        this->hide();
    }
}

sub getFindText
{
    return this->{findText};
}

1;
