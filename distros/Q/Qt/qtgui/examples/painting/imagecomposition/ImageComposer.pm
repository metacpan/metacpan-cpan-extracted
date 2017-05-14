package ImageComposer;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    chooseSource => [],
    chooseDestination => [],
    recalculateResult => [];
# [0]

# [1]
sub sourceButton() {
    return this->{sourceButton};
}

sub destinationButton() {
    return this->{destinationButton};
}

sub operatorComboBox() {
    return this->{operatorComboBox};
}

sub equalLabel() {
    return this->{equalLabel};
}

sub resultLabel() {
    return this->{resultLabel};
}

sub sourceImage() {
    return this->{sourceImage};
}

sub destinationImage() {
    return this->{destinationImage};
}

sub resultImage() {
    return this->{resultImage};
}
# [1]

# [0]
my $resultSize = Qt::Size(200, 200);
# [0]

# [1]
sub NEW
{
    my ($class) = @_;
    $class->SUPER::NEW();
    this->{sourceImage} = Qt::Image();
    this->{destinationImage} = Qt::Image();
    this->{sourceButton} = Qt::ToolButton();
    this->sourceButton->setIconSize($resultSize);

    this->{operatorComboBox} = Qt::ComboBox();
    this->addOp(Qt::Painter::CompositionMode_SourceOver(), this->tr('SourceOver'));
    this->addOp(Qt::Painter::CompositionMode_DestinationOver(), this->tr('DestinationOver'));
    this->addOp(Qt::Painter::CompositionMode_Clear(), this->tr('Clear'));
    this->addOp(Qt::Painter::CompositionMode_Source(), this->tr('Source'));
    this->addOp(Qt::Painter::CompositionMode_Destination(), this->tr('Destination'));
    this->addOp(Qt::Painter::CompositionMode_SourceIn(), this->tr('SourceIn'));
    this->addOp(Qt::Painter::CompositionMode_DestinationIn(), this->tr('DestinationIn'));
    this->addOp(Qt::Painter::CompositionMode_SourceOut(), this->tr('SourceOut'));
    this->addOp(Qt::Painter::CompositionMode_DestinationOut(), this->tr('DestinationOut'));
    this->addOp(Qt::Painter::CompositionMode_SourceAtop(), this->tr('SourceAtop'));
    this->addOp(Qt::Painter::CompositionMode_DestinationAtop(), this->tr('DestinationAtop'));
    this->addOp(Qt::Painter::CompositionMode_Xor(), this->tr('Xor'));
    this->addOp(Qt::Painter::CompositionMode_Plus(), this->tr('Plus'));
    this->addOp(Qt::Painter::CompositionMode_Multiply(), this->tr('Multiply'));
    this->addOp(Qt::Painter::CompositionMode_Screen(), this->tr('Screen'));
    this->addOp(Qt::Painter::CompositionMode_Overlay(), this->tr('Overlay'));
    this->addOp(Qt::Painter::CompositionMode_Darken(), this->tr('Darken'));
    this->addOp(Qt::Painter::CompositionMode_Lighten(), this->tr('Lighten'));
    this->addOp(Qt::Painter::CompositionMode_ColorDodge(), this->tr('ColorDodge'));
    this->addOp(Qt::Painter::CompositionMode_ColorBurn(), this->tr('ColorBurn'));
    this->addOp(Qt::Painter::CompositionMode_HardLight(), this->tr('HardLight'));
    this->addOp(Qt::Painter::CompositionMode_SoftLight(), this->tr('SoftLight'));
    this->addOp(Qt::Painter::CompositionMode_Difference(), this->tr('Difference'));
    this->addOp(Qt::Painter::CompositionMode_Exclusion(), this->tr('Exclusion'));
# [1]

# [2]
    this->{destinationButton} = Qt::ToolButton();
    this->destinationButton->setIconSize($resultSize);

    this->{equalLabel} = Qt::Label(this->tr('='));

    this->{resultLabel} = Qt::Label();
    this->resultLabel->setMinimumWidth($resultSize->width());
# [2]

# [3]
    this->connect(this->sourceButton, SIGNAL 'clicked()', this, SLOT 'chooseSource()');
    this->connect(this->operatorComboBox, SIGNAL 'activated(int)',
            this, SLOT 'recalculateResult()');
    this->connect(this->destinationButton, SIGNAL 'clicked()',
            this, SLOT 'chooseDestination()');
# [3]

# [4]
    my $mainLayout = Qt::GridLayout();
    $mainLayout->addWidget(this->sourceButton, 0, 0, 3, 1);
    $mainLayout->addWidget(this->operatorComboBox, 1, 1);
    $mainLayout->addWidget(this->destinationButton, 0, 2, 3, 1);
    $mainLayout->addWidget(this->equalLabel, 1, 3);
    $mainLayout->addWidget(this->resultLabel, 0, 4, 3, 1);
    $mainLayout->setSizeConstraint(Qt::Layout::SetFixedSize());
    this->setLayout($mainLayout);
# [4]

# [5]
    this->{resultImage} = Qt::Image($resultSize, Qt::Image::Format_ARGB32_Premultiplied());

    this->loadImage('images/butterfly.png', \this->{sourceImage}, this->sourceButton);
    this->loadImage('images/checker.png', \this->{destinationImage}, this->destinationButton);

    this->setWindowTitle(this->tr('Image Composition'));
}
# [5]

# [6]
sub chooseSource
{
    this->chooseImage(this->tr('Choose Source Image'), \this->sourceImage, this->sourceButton);
}
# [6]

# [7]
sub chooseDestination
{
    this->chooseImage(this->tr('Choose Destination Image'), \this->destinationImage,
                this->destinationButton);
}
# [7]

# [8]
sub recalculateResult
{
    my $mode = this->currentMode();

    my $painter = Qt::Painter(this->resultImage);
    $painter->setCompositionMode(Qt::Painter::CompositionMode_Source());
    $painter->fillRect(this->resultImage->rect(), Qt::Brush(Qt::transparent()));
    $painter->setCompositionMode(Qt::Painter::CompositionMode_SourceOver());
    $painter->drawImage(0, 0, this->destinationImage);
    $painter->setCompositionMode($mode);
    $painter->drawImage(0, 0, this->sourceImage);
    $painter->setCompositionMode(Qt::Painter::CompositionMode_DestinationOver());
    $painter->fillRect(this->resultImage->rect(), Qt::Brush(Qt::white()));
    $painter->end();

    this->resultLabel->setPixmap(Qt::Pixmap::fromImage(this->resultImage));
}
# [8]

# [9]
sub addOp
{
    my ($mode, $name) = @_;
    this->operatorComboBox->addItem($name, Qt::Variant(Qt::Int(${$mode})));
}
# [9]

# [10]
sub chooseImage
{
    my ($title, $image, $button) = @_;
    my $fileName = Qt::FileDialog::getOpenFileName(this, $title);
    if ($fileName) {
        this->loadImage($fileName, $image, $button);
    }
}
# [10]

# [11]
sub loadImage
{
    my ($fileName, $image, $button) = @_;
    $$image->load($fileName);

    my $fixedImage = Qt::Image($resultSize, Qt::Image::Format_ARGB32_Premultiplied());
    my $painter = Qt::Painter($fixedImage);
    $painter->setCompositionMode(Qt::Painter::CompositionMode_Source());
    $painter->fillRect($fixedImage->rect(), Qt::Brush(Qt::transparent()));
    $painter->setCompositionMode(Qt::Painter::CompositionMode_SourceOver());
    $painter->drawImage(this->imagePos($$image), $$image);
    $painter->end();
    $button->setIcon(Qt::Icon(Qt::Pixmap::fromImage($fixedImage)));

    $$image = $fixedImage;

    this->recalculateResult();
}
# [11]

# [12]
sub currentMode
{
    return this->operatorComboBox->itemData(this->operatorComboBox->currentIndex())->toInt();
}
# [12]

# [13]
sub imagePos
{
    my ($image) = @_;
    return Qt::Point(($resultSize->width() - $image->width()) / 2,
                  ($resultSize->height() - $image->height()) / 2);
}
# [13]

1;
