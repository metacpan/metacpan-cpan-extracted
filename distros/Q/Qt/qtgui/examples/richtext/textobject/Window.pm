package Window;

use strict;
use warnings;
use QtCore4;
use QtGui4;

#[0]
use QtCore4::isa qw( Qt::Widget );
use constant SvgTextFormat => Qt::TextFormat::UserObject() + 1;
use constant SvgData => 1;

use QtCore4::slots
    insertTextObject => [];
#[0]

use SvgTextObject;

sub NEW
{
    my ($class) = @_;
    $class->SUPER::NEW();
    this->setupGui();
    this->setupTextObject();

    this->setWindowTitle('Text Object Example');
}

#[1]
sub insertTextObject
{
    my $fileName = this->{fileNameLineEdit}->text();
    my $file = Qt::File($fileName);
    if (!$file->open(Qt::IODevice::ReadOnly())) {
        Qt::MessageBox::warning(this, this->tr('Error Opening File'),
                             sprintf this->tr('Could not open \'%s\''), $fileName);
    }

    my $svgData = $file->readAll();
#[1]

#[2]
    my $svgCharFormat = Qt::TextCharFormat();
    $svgCharFormat->setObjectType(SvgTextFormat);
    my $renderer = Qt::SvgRenderer($svgData);

    my $svgBufferImage = Qt::Image($renderer->defaultSize(), Qt::Image::Format_ARGB32());
    my $painter = Qt::Painter($svgBufferImage);
    $renderer->render($painter, Qt::RectF($svgBufferImage->rect()));

    $svgCharFormat->setProperty(SvgData, Qt::qVariantFromValue($svgBufferImage));

    my $cursor = this->{textEdit}->textCursor();
    $cursor->insertText(Qt::Char::ObjectReplacementCharacter(), $svgCharFormat);
    this->{textEdit}->setTextCursor($cursor);
}
#[2]

#[3]
sub setupTextObject
{
    my $svgInterface = SvgTextObject();
    this->{textEdit}->document()->documentLayout()->registerHandler(SvgTextFormat, $svgInterface);
}
#[3]

sub setupGui
{
    this->{fileNameLabel} = Qt::Label(this->tr('Svg File Name:'));
    this->{fileNameLineEdit} = Qt::LineEdit();
    this->{insertTextObjectButton} = Qt::PushButton(this->tr('Insert Image'));

    this->{fileNameLineEdit}->setText('./files/heart.svg');
    this->connect(this->{insertTextObjectButton}, SIGNAL 'clicked()',
            this, SLOT 'insertTextObject()');

    my $bottomLayout = Qt::HBoxLayout();
    $bottomLayout->addWidget(this->{fileNameLabel});
    $bottomLayout->addWidget(this->{fileNameLineEdit});
    $bottomLayout->addWidget(this->{insertTextObjectButton});

    this->{textEdit} = Qt::TextEdit();

    my $mainLayout = Qt::VBoxLayout();
    $mainLayout->addWidget(this->{textEdit});
    $mainLayout->addLayout($bottomLayout);

    this->setLayout($mainLayout);
}

1;
