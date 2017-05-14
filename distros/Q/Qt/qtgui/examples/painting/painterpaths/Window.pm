package Window;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    fillRuleChanged => [],
    fillGradientChanged => [],
    penColorChanged => [];
# [0]
use RenderArea;

# [1]
# [1]

# [2]
use constant NumRenderAreas => 9;
use constant Pi => 3.14159;

sub renderAreas() {
    return this->{renderAreas};
}

sub fillRuleLabel() {
    return this->{fillRuleLabel};
}

sub fillGradientLabel() {
    return this->{fillGradientLabel};
}

sub fillToLabel() {
    return this->{fillToLabel};
}

sub penWidthLabel() {
    return this->{penWidthLabel};
}

sub penColorLabel() {
    return this->{penColorLabel};
}

sub rotationAngleLabel() {
    return this->{rotationAngleLabel};
}

sub fillRuleComboBox() {
    return this->{fillRuleComboBox};
}

sub fillColor1ComboBox() {
    return this->{fillColor1ComboBox};
}

sub fillColor2ComboBox() {
    return this->{fillColor2ComboBox};
}

sub penWidthSpinBox() {
    return this->{penWidthSpinBox};
}

sub penColorComboBox() {
    return this->{penColorComboBox};
}

sub rotationAngleSpinBox() {
    return this->{rotationAngleSpinBox};
}
# [2]

# [0]
# [0]

# [1]
sub NEW
{
    my ($class) = @_;
    $class->SUPER::NEW();
    my $rectPath = Qt::PainterPath();
    $rectPath->moveTo(20.0, 30.0);
    $rectPath->lineTo(80.0, 30.0);
    $rectPath->lineTo(80.0, 70.0);
    $rectPath->lineTo(20.0, 70.0);
    $rectPath->closeSubpath();
# [1]

# [2]
    my $roundRectPath = Qt::PainterPath();
    $roundRectPath->moveTo(80.0, 35.0);
    $roundRectPath->arcTo(70.0, 30.0, 10.0, 10.0, 0.0, 90.0);
    $roundRectPath->lineTo(25.0, 30.0);
    $roundRectPath->arcTo(20.0, 30.0, 10.0, 10.0, 90.0, 90.0);
    $roundRectPath->lineTo(20.0, 65.0);
    $roundRectPath->arcTo(20.0, 60.0, 10.0, 10.0, 180.0, 90.0);
    $roundRectPath->lineTo(75.0, 70.0);
    $roundRectPath->arcTo(70.0, 60.0, 10.0, 10.0, 270.0, 90.0);
    $roundRectPath->closeSubpath();
# [2]

# [3]
    my $ellipsePath = Qt::PainterPath();
    $ellipsePath->moveTo(80.0, 50.0);
    $ellipsePath->arcTo(20.0, 30.0, 60.0, 40.0, 0.0, 360.0);
# [3]

# [4]
    my $piePath = Qt::PainterPath();
    $piePath->moveTo(50.0, 50.0);
    $piePath->arcTo(20.0, 30.0, 60.0, 40.0, 60.0, 240.0);
    $piePath->closeSubpath();
# [4]

# [5]
    my $polygonPath = Qt::PainterPath();
    $polygonPath->moveTo(10.0, 80.0);
    $polygonPath->lineTo(20.0, 10.0);
    $polygonPath->lineTo(80.0, 30.0);
    $polygonPath->lineTo(90.0, 70.0);
    $polygonPath->closeSubpath();
# [5]

# [6]
    my $groupPath = Qt::PainterPath();
    $groupPath->moveTo(60.0, 40.0);
    $groupPath->arcTo(20.0, 20.0, 40.0, 40.0, 0.0, 360.0);
    $groupPath->moveTo(40.0, 40.0);
    $groupPath->lineTo(40.0, 80.0);
    $groupPath->lineTo(80.0, 80.0);
    $groupPath->lineTo(80.0, 40.0);
    $groupPath->closeSubpath();
# [6]

# [7]
    my $textPath = Qt::PainterPath();
    my $timesFont = Qt::Font('Times', 50);
    $timesFont->setStyleStrategy(Qt::Font::ForceOutline());
    $textPath->addText(10, 70, $timesFont, this->tr('Qt'));
# [7]

# [8]
    my $bezierPath = Qt::PainterPath();
    $bezierPath->moveTo(20, 30);
    $bezierPath->cubicTo(80, 0, 50, 50, 80, 80);
# [8]

# [9]
    my $starPath = Qt::PainterPath();
    $starPath->moveTo(90, 50);
    for (my $i = 1; $i < 5; ++$i) {
        $starPath->lineTo(50 + 40 * cos(0.8 * $i * Pi),
                        50 + 40 * sin(0.8 * $i * Pi));
    }
    $starPath->closeSubpath();
# [9]

# [10]
    this->{renderAreas} = [];
    this->renderAreas->[0] = RenderArea($rectPath);
    this->renderAreas->[1] = RenderArea($roundRectPath);
    this->renderAreas->[2] = RenderArea($ellipsePath);
    this->renderAreas->[3] = RenderArea($piePath);
    this->renderAreas->[4] = RenderArea($polygonPath);
    this->renderAreas->[5] = RenderArea($groupPath);
    this->renderAreas->[6] = RenderArea($textPath);
    this->renderAreas->[7] = RenderArea($bezierPath);
    this->renderAreas->[8] = RenderArea($starPath);
# [10]

# [11]
    this->{fillRuleComboBox} = Qt::ComboBox();
    this->fillRuleComboBox->addItem(this->tr('Odd Even'), Qt::Variant(Qt::Int(${Qt::OddEvenFill()})));
    this->fillRuleComboBox->addItem(this->tr('Winding'), Qt::Variant(Qt::Int(${Qt::WindingFill()})));

    this->{fillRuleLabel} = Qt::Label(this->tr('Fill &Rule:'));
    this->fillRuleLabel->setBuddy(this->fillRuleComboBox);
# [11]

# [12]
    this->{fillColor1ComboBox} = Qt::ComboBox();
    this->populateWithColors(this->fillColor1ComboBox);
    this->fillColor1ComboBox->setCurrentIndex(
            this->fillColor1ComboBox->findText('mediumslateblue'));

    this->{fillColor2ComboBox} = Qt::ComboBox();
    this->populateWithColors(this->fillColor2ComboBox);
    this->fillColor2ComboBox->setCurrentIndex(
            this->fillColor2ComboBox->findText('cornsilk'));

    this->{fillGradientLabel} = Qt::Label(this->tr('&Fill Gradient:'));
    this->fillGradientLabel->setBuddy(this->fillColor1ComboBox);

    this->{fillToLabel} = Qt::Label(this->tr('to'));
    this->fillToLabel->setSizePolicy(Qt::SizePolicy::Fixed(), Qt::SizePolicy::Fixed());

    this->{penWidthSpinBox} = Qt::SpinBox();
    this->penWidthSpinBox->setRange(0, 20);

    this->{penWidthLabel} = Qt::Label(this->tr('&Pen Width:'));
    this->penWidthLabel->setBuddy(this->penWidthSpinBox);

    this->{penColorComboBox} = Qt::ComboBox();
    this->populateWithColors(this->penColorComboBox);
    this->penColorComboBox->setCurrentIndex(
            this->penColorComboBox->findText('darkslateblue'));

    this->{penColorLabel} = Qt::Label(this->tr('Pen &Color:'));
    this->penColorLabel->setBuddy(this->penColorComboBox);

    this->{rotationAngleSpinBox} = Qt::SpinBox();
    this->rotationAngleSpinBox->setRange(0, 359);
    this->rotationAngleSpinBox->setWrapping(1);
    this->rotationAngleSpinBox->setSuffix("\xB0");

    this->{rotationAngleLabel} = Qt::Label(this->tr('&Rotation Angle:'));
    this->rotationAngleLabel->setBuddy(this->rotationAngleSpinBox);
# [12]

# [16]
    this->connect(this->fillRuleComboBox, SIGNAL 'activated(int)',
            this, SLOT 'fillRuleChanged()');
    this->connect(this->fillColor1ComboBox, SIGNAL 'activated(int)',
            this, SLOT 'fillGradientChanged()');
    this->connect(this->fillColor2ComboBox, SIGNAL 'activated(int)',
            this, SLOT 'fillGradientChanged()');
    this->connect(this->penColorComboBox, SIGNAL 'activated(int)',
            this, SLOT 'penColorChanged()');

    for (my $i = 0; $i < NumRenderAreas; ++$i) {
        this->connect(this->penWidthSpinBox, SIGNAL 'valueChanged(int)',
                this->renderAreas->[$i], SLOT 'setPenWidth(int)');
        this->connect(this->rotationAngleSpinBox, SIGNAL 'valueChanged(int)',
                this->renderAreas->[$i], SLOT 'setRotationAngle(int)');
    }

# [16] //! [17]
    my $topLayout = Qt::GridLayout();
    for (my $i = 0; $i < NumRenderAreas; ++$i) {
        $topLayout->addWidget(this->renderAreas->[$i], $i / 3, $i % 3);
    }

    my $mainLayout = Qt::GridLayout();
    $mainLayout->addLayout($topLayout, 0, 0, 1, 4);
    $mainLayout->addWidget(this->fillRuleLabel, 1, 0);
    $mainLayout->addWidget(this->fillRuleComboBox, 1, 1, 1, 3);
    $mainLayout->addWidget(this->fillGradientLabel, 2, 0);
    $mainLayout->addWidget(this->fillColor1ComboBox, 2, 1);
    $mainLayout->addWidget(this->fillToLabel, 2, 2);
    $mainLayout->addWidget(this->fillColor2ComboBox, 2, 3);
    $mainLayout->addWidget(this->penWidthLabel, 3, 0);
    $mainLayout->addWidget(this->penWidthSpinBox, 3, 1, 1, 3);
    $mainLayout->addWidget(this->penColorLabel, 4, 0);
    $mainLayout->addWidget(this->penColorComboBox, 4, 1, 1, 3);
    $mainLayout->addWidget(this->rotationAngleLabel, 5, 0);
    $mainLayout->addWidget(this->rotationAngleSpinBox, 5, 1, 1, 3);
    this->setLayout($mainLayout);
# [17]

# [18]
    this->fillRuleChanged();
    this->fillGradientChanged();
    this->penColorChanged();
    this->penWidthSpinBox->setValue(2);

    this->setWindowTitle(this->tr('Painter Paths'));
}
# [18]

# [19]
sub fillRuleChanged
{
    my $rule = this->currentItemData(this->fillRuleComboBox)->toInt();

    for (my $i = 0; $i < NumRenderAreas; ++$i) {
        this->renderAreas->[$i]->setFillRule($rule);
    }
}
# [19]

# [20]
sub fillGradientChanged
{
    #my $color1 = qvariant_cast<Qt::Color>(this->currentItemData(this->fillColor1ComboBox));
    #my $color2 = qvariant_cast<Qt::Color>(this->currentItemData(this->fillColor2ComboBox));
    my $color1 = this->currentItemData(this->fillColor1ComboBox);
    my $color2 = this->currentItemData(this->fillColor2ComboBox);

    for (my $i = 0; $i < NumRenderAreas; ++$i) {
        this->renderAreas->[$i]->setFillGradient($color1, $color2);
    }
}
# [20]

# [21]
sub penColorChanged
{
    #my $color = qvariant_cast<Qt::Color>(this->currentItemData(this->penColorComboBox));
    my $color = this->currentItemData(this->penColorComboBox);

    for (my $i = 0; $i < NumRenderAreas; ++$i) {
        this->renderAreas->[$i]->setPenColor($color);
    }
}
# [21]

# [22]
sub populateWithColors
{
    my ($comboBox) = @_;
    my $colorNames = Qt::Color::colorNames();
    foreach my $name ( @{$colorNames} ) {
        $comboBox->addItem($name, Qt::qVariantFromValue(Qt::Color(Qt::String($name))));
    }
}
# [22]

# [23]
sub currentItemData
{
    my ($comboBox) = @_;
    return $comboBox->itemData($comboBox->currentIndex());
}
# [23]

1;
