package InformationWindow;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtSql4;

# [0]
use QtCore4::isa qw( Qt::Dialog );
use QtCore4::signals
    imageChanged => ['int', 'const QString &'];
# [0]

# [1]
use QtCore4::slots
    revert => [],
    submit => [],
    enableButtons2 => [],
    enableButtons => ['bool'];
# [1]

# [0]
sub NEW {
    my ($class, $id, $offices, $parent) = @_;
    $class->SUPER::NEW($parent);
# [0] //! [1]
    my $locationLabel = Qt::Label(this->tr('Location: '));
    my $countryLabel = Qt::Label(this->tr('Country: '));
    my $descriptionLabel = Qt::Label(this->tr('Description: '));
    my $imageFileLabel = Qt::Label(this->tr('Image file: '));

    this->createButtons();

    this->{locationText} = Qt::Label();
    this->{countryText} = Qt::Label();
    this->{descriptionEditor} = Qt::TextEdit();
# [1]

# [2]
    this->{imageFileEditor} = Qt::ComboBox();
    this->{imageFileEditor}->setModel($offices->relationModel(1));
    this->{imageFileEditor}->setModelColumn($offices->relationModel(1)->fieldIndex('file'));
# [2]

# [3]
    this->{mapper} = Qt::DataWidgetMapper(this);
    this->{mapper}->setModel($offices);
    this->{mapper}->setSubmitPolicy(Qt::DataWidgetMapper::ManualSubmit());
    this->{mapper}->setItemDelegate(Qt::SqlRelationalDelegate(this->{mapper}));
    this->{mapper}->addMapping(this->{imageFileEditor}, 1);
    this->{mapper}->addMapping(this->{locationText}, 2, Qt::ByteArray('text'));
    this->{mapper}->addMapping(this->{countryText}, 3, Qt::ByteArray('text'));
    this->{mapper}->addMapping(this->{descriptionEditor}, 4);
    this->{mapper}->setCurrentIndex($id);
# [3]

# [4]
    this->connect(this->{descriptionEditor}, SIGNAL 'textChanged()',
            this, SLOT 'enableButtons2()');
    this->connect(this->{imageFileEditor}, SIGNAL 'currentIndexChanged(int)',
            this, SLOT 'enableButtons2()');

    my $layout = Qt::GridLayout();
    $layout->addWidget($locationLabel, 0, 0, Qt::AlignLeft() | Qt::AlignTop());
    $layout->addWidget($countryLabel, 1, 0, Qt::AlignLeft() | Qt::AlignTop());
    $layout->addWidget($imageFileLabel, 2, 0, Qt::AlignLeft() | Qt::AlignTop());
    $layout->addWidget($descriptionLabel, 3, 0, Qt::AlignLeft() | Qt::AlignTop());
    $layout->addWidget(this->{locationText}, 0, 1);
    $layout->addWidget(this->{countryText}, 1, 1);
    $layout->addWidget(this->{imageFileEditor}, 2, 1);
    $layout->addWidget(this->{descriptionEditor}, 3, 1);
    $layout->addWidget(this->{buttonBox}, 4, 0, 1, 2);
    this->setLayout($layout);

    this->{locationId} = $id;
    this->{displayedImage} = this->{imageFileEditor}->currentText();

    this->setWindowFlags(Qt::Window());
    this->enableButtons($0);
    this->setWindowTitle(sprintf this->tr('Office: %s'), this->{locationText}->text());
    this->resize(320, this->sizeHint()->height());
}
# [4]

# [5]
sub id
{
    return this->{locationId};
}
# [5]

# [6]
sub revert
{
    this->{mapper}->revert();
    this->enableButtons(0);
}
# [6]

# [7]
sub submit
{
    my $newImage = this->{imageFileEditor}->currentText();

    if (this->{displayedImage} ne $newImage) {
        this->{displayedImage} = $newImage;
        emit imageChanged(this->{locationId}, $newImage);
    }

    this->{mapper}->submit();
    this->{mapper}->setCurrentIndex(this->{locationId});

    this->enableButtons(0);
}
# [7]

# [8]
sub createButtons
{
    this->{closeButton} = Qt::PushButton(this->tr('&Close'));
    this->{revertButton} = Qt::PushButton(this->tr('&Revert'));
    this->{submitButton} = Qt::PushButton(this->tr('&Submit'));

    this->{closeButton}->setDefault(1);

    this->connect(this->{closeButton}, SIGNAL 'clicked()', this, SLOT 'close()');
    this->connect(this->{revertButton}, SIGNAL 'clicked()', this, SLOT 'revert()');
    this->connect(this->{submitButton}, SIGNAL 'clicked()', this, SLOT 'submit()');
# [8]

# [9]
    this->{buttonBox} = Qt::DialogButtonBox();
    this->{buttonBox}->addButton(this->{submitButton}, Qt::DialogButtonBox::ResetRole());
    this->{buttonBox}->addButton(this->{revertButton}, Qt::DialogButtonBox::ResetRole());
    this->{buttonBox}->addButton(this->{closeButton}, Qt::DialogButtonBox::RejectRole());
}
# [9]

sub enableButtons2 {
    this->enableButtons(1);
}

# [10]
sub enableButtons
{
    my ($enable) = @_;
    this->{revertButton}->setEnabled($enable);
    this->{submitButton}->setEnabled($enable);
}
# [10]

1;
