package Window;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use RenderArea;
# [0]
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    operationChanged => [''],
    shapeSelected => ['int'];
# [0]

# [1]
use constant { NumTransformedAreas => 3 };
sub originalRenderArea() {
    return this->{originalRenderArea};
}

sub transformedRenderAreas() {
    return this->{transformedRenderAreas};
}

sub shapeComboBox() {
    return this->{shapeComboBox};
}

sub operationComboBoxes() {
    return this->{operationComboBoxes};
}

sub shapes() {
    return this->{shapes};
}
# [1]

# [0]
sub NEW
{
    my ($class) = @_;
    $class->SUPER::NEW();
    this->{originalRenderArea} = RenderArea();

    this->{shapeComboBox} = Qt::ComboBox();
    this->shapeComboBox->addItem(this->tr('Clock'));
    this->shapeComboBox->addItem(this->tr('House'));
    this->shapeComboBox->addItem(this->tr('Text'));
    this->shapeComboBox->addItem(this->tr('Truck'));

    my $layout = Qt::GridLayout();
    $layout->addWidget(this->originalRenderArea, 0, 0);
    $layout->addWidget(this->shapeComboBox, 1, 0);
# [0]

# [1]
    this->{transformedRenderAreas} = [];
    this->{operationComboBoxes} = [];
    this->{shapes} = [];
    for (my $i = 0; $i < NumTransformedAreas; ++$i) {
        this->transformedRenderAreas->[$i] = RenderArea();

        this->operationComboBoxes->[$i] = Qt::ComboBox();
        this->operationComboBoxes->[$i]->addItem(this->tr('No transformation'));
        this->operationComboBoxes->[$i]->addItem(this->tr("Rotate by 60\xB0"));
        this->operationComboBoxes->[$i]->addItem(this->tr('Scale to 75%'));
        this->operationComboBoxes->[$i]->addItem(this->tr('Translate by (50, 50)'));

        this->connect(this->operationComboBoxes->[$i], SIGNAL 'activated(int)',
                this, SLOT 'operationChanged()');

        $layout->addWidget(this->transformedRenderAreas->[$i], 0, $i + 1);
        $layout->addWidget(this->operationComboBoxes->[$i], 1, $i + 1);
    }
# [1]

# [2]
    this->setLayout($layout);
    this->setupShapes();
    this->shapeSelected(0);

    this->setWindowTitle(this->tr('Transformations'));
}
# [2]

# [3]
sub setupShapes
{
    my $truck = Qt::PainterPath();
# [3]
    $truck->setFillRule(Qt::WindingFill());
    $truck->moveTo(0.0, 87.0);
    $truck->lineTo(0.0, 60.0);
    $truck->lineTo(10.0, 60.0);
    $truck->lineTo(35.0, 35.0);
    $truck->lineTo(100.0, 35.0);
    $truck->lineTo(100.0, 87.0);
    $truck->lineTo(0.0, 87.0);
    $truck->moveTo(17.0, 60.0);
    $truck->lineTo(55.0, 60.0);
    $truck->lineTo(55.0, 40.0);
    $truck->lineTo(37.0, 40.0);
    $truck->lineTo(17.0, 60.0);
    $truck->addEllipse(17.0, 75.0, 25.0, 25.0);
    $truck->addEllipse(63.0, 75.0, 25.0, 25.0);

# [4]
    my $clock = Qt::PainterPath();
# [4]
    $clock->addEllipse(-50.0, -50.0, 100.0, 100.0);
    $clock->addEllipse(-48.0, -48.0, 96.0, 96.0);
    $clock->moveTo(0.0, 0.0);
    $clock->lineTo(-2.0, -2.0);
    $clock->lineTo(0.0, -42.0);
    $clock->lineTo(2.0, -2.0);
    $clock->lineTo(0.0, 0.0);
    $clock->moveTo(0.0, 0.0);
    $clock->lineTo(2.732, -0.732);
    $clock->lineTo(24.495, 14.142);
    $clock->lineTo(0.732, 2.732);
    $clock->lineTo(0.0, 0.0);

# [5]
    my $house = Qt::PainterPath();
# [5]
    $house->moveTo(-45.0, -20.0);
    $house->lineTo(0.0, -45.0);
    $house->lineTo(45.0, -20.0);
    $house->lineTo(45.0, 45.0);
    $house->lineTo(-45.0, 45.0);
    $house->lineTo(-45.0, -20.0);
    $house->addRect(15.0, 5.0, 20.0, 35.0);
    $house->addRect(-35.0, -15.0, 25.0, 25.0);

# [6]
    my $text = Qt::PainterPath();
# [6]
    my $font = Qt::Font();
    $font->setPixelSize(50);
    my $fontBoundingRect = Qt::FontMetrics($font)->boundingRect(this->tr('Qt4'));
    $text->addText(-Qt::PointF($fontBoundingRect->center()), $font, this->tr('Qt4'));

# [7]
    push @{this->shapes}, $clock;
    push @{this->shapes}, $house;
    push @{this->shapes}, $text;
    push @{this->shapes}, $truck;

    this->connect(this->shapeComboBox, SIGNAL 'activated(int)',
            this, SLOT 'shapeSelected(int)');
}
# [7]

my @operationTable = (
    RenderArea::NoTransformation,
    RenderArea::Rotate,
    RenderArea::Scale,
    RenderArea::Translate
);
# [8]
sub operationChanged
{
    my @operations;
    for (my $i = 0; $i < NumTransformedAreas; ++$i) {
        my $index = this->operationComboBoxes->[$i]->currentIndex();
        push @operations, $operationTable[$index];
        this->transformedRenderAreas->[$i]->setOperations(\@operations);
    }
}
# [8]

# [9]
sub shapeSelected
{
    my ($index) = @_;
    my $shape = this->shapes->[$index];
    this->originalRenderArea->setShape($shape);
    for (my $i = 0; $i < NumTransformedAreas; ++$i) {
        this->transformedRenderAreas->[$i]->setShape($shape);
    }
}
# [9]

1;
