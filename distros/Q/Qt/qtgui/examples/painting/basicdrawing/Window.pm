package Window;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    shapeChanged => [],
    penChanged => [],
    brushChanged => [];

use RenderArea;

sub renderArea() {
    return this->{renderArea};
}

sub shapeLabel() {
    return this->{shapeLabel};
}

sub penWidthLabel() {
    return this->{penWidthLabel};
}

sub penStyleLabel() {
    return this->{penStyleLabel};
}

sub penCapLabel() {
    return this->{penCapLabel};
}

sub penJoinLabel() {
    return this->{penJoinLabel};
}

sub brushStyleLabel() {
    return this->{brushStyleLabel};
}

sub otherOptionsLabel() {
    return this->{otherOptionsLabel};
}

sub shapeComboBox() {
    return this->{shapeComboBox};
}

sub penWidthSpinBox() {
    return this->{penWidthSpinBox};
}

sub penStyleComboBox() {
    return this->{penStyleComboBox};
}

sub penCapComboBox() {
    return this->{penCapComboBox};
}

sub penJoinComboBox() {
    return this->{penJoinComboBox};
}

sub brushStyleComboBox() {
    return this->{brushStyleComboBox};
}

sub antialiasingCheckBox() {
    return this->{antialiasingCheckBox};
}

sub transformationsCheckBox() {
    return this->{transformationsCheckBox};
}

# [0]
use constant IdRole => Qt::UserRole();
# [0]

# [1]
sub NEW
{
    my ($class) = @_;
    $class->SUPER::NEW();
    this->{renderArea} = RenderArea();

    this->{shapeComboBox} = Qt::ComboBox();
    this->shapeComboBox->addItem(this->tr('Polygon'), Qt::Variant(Qt::Int(RenderArea::Polygon())));
    this->shapeComboBox->addItem(this->tr('Rectangle'), Qt::Variant(Qt::Int(RenderArea::Rect())));
    this->shapeComboBox->addItem(this->tr('Rounded Rectangle'), Qt::Variant(Qt::Int(RenderArea::RoundedRect())));
    this->shapeComboBox->addItem(this->tr('Ellipse'), Qt::Variant(Qt::Int(RenderArea::Ellipse())));
    this->shapeComboBox->addItem(this->tr('Pie'), Qt::Variant(Qt::Int(RenderArea::Pie())));
    this->shapeComboBox->addItem(this->tr('Chord'), Qt::Variant(Qt::Int(RenderArea::Chord())));
    this->shapeComboBox->addItem(this->tr('Path'), Qt::Variant(Qt::Int(RenderArea::Path())));
    this->shapeComboBox->addItem(this->tr('Line'), Qt::Variant(Qt::Int(RenderArea::Line())));
    this->shapeComboBox->addItem(this->tr('Polyline'), Qt::Variant(Qt::Int(RenderArea::Polyline())));
    this->shapeComboBox->addItem(this->tr('Arc'), Qt::Variant(Qt::Int(RenderArea::Arc())));
    this->shapeComboBox->addItem(this->tr('Points'), Qt::Variant(Qt::Int(RenderArea::Points())));
    this->shapeComboBox->addItem(this->tr('Text'), Qt::Variant(Qt::Int(RenderArea::Text())));
    this->shapeComboBox->addItem(this->tr('Pixmap'), Qt::Variant(Qt::Int(RenderArea::Pixmap())));

    this->{shapeLabel} = Qt::Label(this->tr('&Shape:'));
    this->shapeLabel->setBuddy(this->shapeComboBox);
# [1]

# [2]
    this->{penWidthSpinBox} = Qt::SpinBox();
    this->penWidthSpinBox->setRange(0, 20);
    this->penWidthSpinBox->setSpecialValueText(this->tr('0 (cosmetic pen)'));

    this->{penWidthLabel} = Qt::Label(this->tr('Pen &Width:'));
    this->penWidthLabel->setBuddy(this->penWidthSpinBox);
# [2]

# [3]
    this->{penStyleComboBox} = Qt::ComboBox();
    this->penStyleComboBox->addItem(this->tr('Solid'), Qt::Variant(Qt::Int(${Qt::SolidLine()})));
    this->penStyleComboBox->addItem(this->tr('Dash'), Qt::Variant(Qt::Int(${Qt::DashLine()})));
    this->penStyleComboBox->addItem(this->tr('Dot'), Qt::Variant(Qt::Int(${Qt::DotLine()})));
    this->penStyleComboBox->addItem(this->tr('Dash Dot'), Qt::Variant(Qt::Int(${Qt::DashDotLine()})));
    this->penStyleComboBox->addItem(this->tr('Dash Dot Dot'), Qt::Variant(Qt::Int(${Qt::DashDotDotLine()})));
    this->penStyleComboBox->addItem(this->tr('None'), Qt::Variant(Qt::Int(${Qt::NoPen()})));

    this->{penStyleLabel} = Qt::Label(this->tr('&Pen Style:'));
    this->penStyleLabel->setBuddy(this->penStyleComboBox);

    this->{penCapComboBox} = Qt::ComboBox();
    this->penCapComboBox->addItem(this->tr('Flat'), Qt::Variant(Qt::Int(${Qt::FlatCap()})));
    this->penCapComboBox->addItem(this->tr('Square'), Qt::Variant(Qt::Int(${Qt::SquareCap()})));
    this->penCapComboBox->addItem(this->tr('Round'), Qt::Variant(Qt::Int(${Qt::RoundCap()})));

    this->{penCapLabel} = Qt::Label(this->tr('Pen &Cap:'));
    this->penCapLabel->setBuddy(this->penCapComboBox);

    this->{penJoinComboBox} = Qt::ComboBox();
    this->penJoinComboBox->addItem(this->tr('Miter'), Qt::Variant(Qt::Int(${Qt::MiterJoin()})));
    this->penJoinComboBox->addItem(this->tr('Bevel'), Qt::Variant(Qt::Int(${Qt::BevelJoin()})));
    this->penJoinComboBox->addItem(this->tr('Round'), Qt::Variant(Qt::Int(${Qt::RoundJoin()})));

    this->{penJoinLabel} = Qt::Label(this->tr('Pen &Join:'));
    this->penJoinLabel->setBuddy(this->penJoinComboBox);
# [3]

# [4]
    this->{brushStyleComboBox} = Qt::ComboBox();
    this->brushStyleComboBox->addItem(this->tr('Linear Gradient'),
            Qt::Variant(Qt::Int(${Qt::LinearGradientPattern()})));
    this->brushStyleComboBox->addItem(this->tr('Radial Gradient'),
            Qt::Variant(Qt::Int(${Qt::RadialGradientPattern()})));
    this->brushStyleComboBox->addItem(this->tr('Conical Gradient'),
            Qt::Variant(Qt::Int(${Qt::ConicalGradientPattern()})));
    this->brushStyleComboBox->addItem(this->tr('Texture'), Qt::Variant(Qt::Int(${Qt::TexturePattern()})));
    this->brushStyleComboBox->addItem(this->tr('Solid'), Qt::Variant(Qt::Int(${Qt::SolidPattern()})));
    this->brushStyleComboBox->addItem(this->tr('Horizontal'), Qt::Variant(Qt::Int(${Qt::HorPattern()})));
    this->brushStyleComboBox->addItem(this->tr('Vertical'), Qt::Variant(Qt::Int(${Qt::VerPattern()})));
    this->brushStyleComboBox->addItem(this->tr('Cross'), Qt::Variant(Qt::Int(${Qt::CrossPattern()})));
    this->brushStyleComboBox->addItem(this->tr('Backward Diagonal'), Qt::Variant(Qt::Int(${Qt::BDiagPattern()})));
    this->brushStyleComboBox->addItem(this->tr('Forward Diagonal'), Qt::Variant(Qt::Int(${Qt::FDiagPattern()})));
    this->brushStyleComboBox->addItem(this->tr('Diagonal Cross'), Qt::Variant(Qt::Int(${Qt::DiagCrossPattern()})));
    this->brushStyleComboBox->addItem(this->tr('Dense 1'), Qt::Variant(Qt::Int(${Qt::Dense1Pattern()})));
    this->brushStyleComboBox->addItem(this->tr('Dense 2'), Qt::Variant(Qt::Int(${Qt::Dense2Pattern()})));
    this->brushStyleComboBox->addItem(this->tr('Dense 3'), Qt::Variant(Qt::Int(${Qt::Dense3Pattern()})));
    this->brushStyleComboBox->addItem(this->tr('Dense 4'), Qt::Variant(Qt::Int(${Qt::Dense4Pattern()})));
    this->brushStyleComboBox->addItem(this->tr('Dense 5'), Qt::Variant(Qt::Int(${Qt::Dense5Pattern()})));
    this->brushStyleComboBox->addItem(this->tr('Dense 6'), Qt::Variant(Qt::Int(${Qt::Dense6Pattern()})));
    this->brushStyleComboBox->addItem(this->tr('Dense 7'), Qt::Variant(Qt::Int(${Qt::Dense7Pattern()})));
    this->brushStyleComboBox->addItem(this->tr('None'), Qt::Variant(Qt::Int(${Qt::NoBrush()})));

    this->{brushStyleLabel} = Qt::Label(this->tr('&Brush Style:'));
    this->brushStyleLabel->setBuddy(this->brushStyleComboBox);
# [4]

# [5]
    this->{otherOptionsLabel} = Qt::Label(this->tr('Other Options:'));
# [5] //! [6]
    this->{antialiasingCheckBox} = Qt::CheckBox(this->tr('&Antialiasing'));
# [6] //! [7]
    this->{transformationsCheckBox} = Qt::CheckBox(this->tr('&Transformations'));
# [7]

# [8]
    this->connect(this->shapeComboBox, SIGNAL 'activated(int)',
            this, SLOT 'shapeChanged()');
    this->connect(this->penWidthSpinBox, SIGNAL 'valueChanged(int)',
            this, SLOT 'penChanged()');
    this->connect(this->penStyleComboBox, SIGNAL 'activated(int)',
            this, SLOT 'penChanged()');
    this->connect(this->penCapComboBox, SIGNAL 'activated(int)',
            this, SLOT 'penChanged()');
    this->connect(this->penJoinComboBox, SIGNAL 'activated(int)',
            this, SLOT 'penChanged()');
    this->connect(this->brushStyleComboBox, SIGNAL 'activated(int)',
            this, SLOT 'brushChanged()');
    this->connect(this->antialiasingCheckBox, SIGNAL 'toggled(bool)',
            this->renderArea, SLOT 'setAntialiased(bool)');
    this->connect(this->transformationsCheckBox, SIGNAL 'toggled(bool)',
            this->renderArea, SLOT 'setTransformed(bool)');
# [8]

# [9]
    my $mainLayout = Qt::GridLayout();
# [9] //! [10]
    $mainLayout->setColumnStretch(0, 1);
    $mainLayout->setColumnStretch(3, 1);
    $mainLayout->addWidget(renderArea, 0, 0, 1, 4);
    $mainLayout->setRowMinimumHeight(1, 6);
    $mainLayout->addWidget(this->shapeLabel, 2, 1, Qt::AlignRight());
    $mainLayout->addWidget(this->shapeComboBox, 2, 2);
    $mainLayout->addWidget(this->penWidthLabel, 3, 1, Qt::AlignRight());
    $mainLayout->addWidget(this->penWidthSpinBox, 3, 2);
    $mainLayout->addWidget(this->penStyleLabel, 4, 1, Qt::AlignRight());
    $mainLayout->addWidget(this->penStyleComboBox, 4, 2);
    $mainLayout->addWidget(this->penCapLabel, 5, 1, Qt::AlignRight());
    $mainLayout->addWidget(this->penCapComboBox, 5, 2);
    $mainLayout->addWidget(this->penJoinLabel, 6, 1, Qt::AlignRight());
    $mainLayout->addWidget(this->penJoinComboBox, 6, 2);
    $mainLayout->addWidget(this->brushStyleLabel, 7, 1, Qt::AlignRight());
    $mainLayout->addWidget(this->brushStyleComboBox, 7, 2);
    $mainLayout->setRowMinimumHeight(8, 6);
    $mainLayout->addWidget(this->otherOptionsLabel, 9, 1, Qt::AlignRight());
    $mainLayout->addWidget(this->antialiasingCheckBox, 9, 2);
    $mainLayout->addWidget(this->transformationsCheckBox, 10, 2);
    this->setLayout($mainLayout);

    this->shapeChanged();
    this->penChanged();
    this->brushChanged();
    this->antialiasingCheckBox->setChecked(1);

    setWindowTitle(this->tr('Basic Drawing'));
}
# [10]

# [11]
sub shapeChanged
{
    my $shape = this->shapeComboBox->itemData(
            this->shapeComboBox->currentIndex(), IdRole)->toInt();
    this->renderArea->setShape($shape);
}
# [11]

# [12]
sub penChanged
{
    my $width = this->penWidthSpinBox->value();
    my $style = this->penStyleComboBox->itemData(
            this->penStyleComboBox->currentIndex(), IdRole)->toInt();
    my $cap = this->penCapComboBox->itemData(
            this->penCapComboBox->currentIndex(), IdRole)->toInt();
    my $join = this->penJoinComboBox->itemData(
            this->penJoinComboBox->currentIndex(), IdRole)->toInt();

    this->renderArea->setPen(Qt::Pen(Qt::Brush(Qt::Color(Qt::blue())), $width, $style, $cap, $join));
}
# [12]

# [13]
sub brushChanged
{
    my $style = this->brushStyleComboBox->itemData(
# [13]
            this->brushStyleComboBox->currentIndex(), IdRole)->toInt();

# [14]
    if ($style == Qt::LinearGradientPattern()) {
        my $linearGradient = Qt::LinearGradient(0, 0, 100, 100);
        $linearGradient->setColorAt(0.0, Qt::Color(Qt::white()));
        $linearGradient->setColorAt(0.2, Qt::Color(Qt::green()));
        $linearGradient->setColorAt(1.0, Qt::Color(Qt::black()));
        this->renderArea->setBrush($linearGradient);
# [14] //! [15]
    } elsif ($style == Qt::RadialGradientPattern()) {
        my $radialGradient = Qt::RadialGradient(50, 50, 50, 70, 70);
        $radialGradient->setColorAt(0.0, Qt::Color(Qt::white()));
        $radialGradient->setColorAt(0.2, Qt::Color(Qt::green()));
        $radialGradient->setColorAt(1.0, Qt::Color(Qt::black()));
        this->renderArea->setBrush($radialGradient);
    } elsif ($style == Qt::ConicalGradientPattern()) {
        my $conicalGradient = Qt::ConicalGradient(50, 50, 150);
        $conicalGradient->setColorAt(0.0, Qt::Color(Qt::white()));
        $conicalGradient->setColorAt(0.2, Qt::Color(Qt::green()));
        $conicalGradient->setColorAt(1.0, Qt::Color(Qt::black()));
        this->renderArea->setBrush($conicalGradient);
# [15] //! [16]
    } elsif ($style == Qt::TexturePattern()) {
        this->renderArea->setBrush(Qt::Brush(Qt::Pixmap('images/brick.png')));
# [16] //! [17]
    } else {
        this->renderArea->setBrush(Qt::Brush(Qt::green(), $style));
    }
}
# [17]

1;
