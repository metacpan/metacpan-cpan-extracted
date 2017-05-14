package Window;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );
use SlidersGroup;

# [0]
sub horizontalSliders() {
    return this->{horizontalSliders};
}

sub verticalSliders() {
    return this->{verticalSliders};
}

sub stackedWidget() {
    return this->{stackedWidget};
}

sub controlsGroup() {
    return this->{controlsGroup};
}

sub minimumLabel() {
    return this->{minimumLabel};
}

sub maximumLabel() {
    return this->{maximumLabel};
}

sub valueLabel() {
    return this->{valueLabel};
}

sub invertedAppearance() {
    return this->{invertedAppearance};
}

sub invertedKeyBindings() {
    return this->{invertedKeyBindings};
}

sub minimumSpinBox() {
    return this->{minimumSpinBox};
}

sub maximumSpinBox() {
    return this->{maximumSpinBox};
}

sub valueSpinBox() {
    return this->{valueSpinBox};
}

sub orientationCombo() {
    return this->{orientationCombo};
}
# [0]

# [0]
sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );

    this->{horizontalSliders} = SlidersGroup(Qt::Horizontal(), this->tr('Horizontal'));
    this->{verticalSliders} = SlidersGroup(Qt::Vertical(), this->tr('Vertical'));

    this->{stackedWidget} = Qt::StackedWidget();
    this->stackedWidget->addWidget(this->horizontalSliders);
    this->stackedWidget->addWidget(this->verticalSliders);

    this->createControls(this->tr('Controls'));
# [0]

# [1]
    this->connect(this->horizontalSliders, SIGNAL 'valueChanged(int)',
# [1] //! [2]
            this->verticalSliders, SLOT 'setValue(int)');
    this->connect(this->verticalSliders, SIGNAL 'valueChanged(int)',
            this->valueSpinBox, SLOT 'setValue(int)');
    this->connect(this->valueSpinBox, SIGNAL 'valueChanged(int)',
            this->horizontalSliders, SLOT 'setValue(int)');

    my $layout = Qt::HBoxLayout();
    $layout->addWidget(this->controlsGroup);
    $layout->addWidget(this->stackedWidget);
    this->setLayout($layout);

    this->minimumSpinBox->setValue(0);
    this->maximumSpinBox->setValue(20);
    this->valueSpinBox->setValue(5);

    this->setWindowTitle(this->tr('Sliders'));
}
# [2]

# [3]
sub createControls {
# [3] //! [4]
    my ($title) = @_;
    this->{controlsGroup} = Qt::GroupBox($title);

    this->{minimumLabel} = Qt::Label(this->tr('Minimum value:'));
    this->{maximumLabel} = Qt::Label(this->tr('Maximum value:'));
    this->{valueLabel} = Qt::Label(this->tr('Current value:'));

    this->{invertedAppearance} = Qt::CheckBox(this->tr('Inverted appearance'));
    this->{invertedKeyBindings} = Qt::CheckBox(this->tr('Inverted key bindings'));

# [4] //! [5]
    this->{minimumSpinBox} = Qt::SpinBox();
# [5] //! [6]
    this->minimumSpinBox->setRange(-100, 100);
    this->minimumSpinBox->setSingleStep(1);

    this->{maximumSpinBox} = Qt::SpinBox();
    this->maximumSpinBox->setRange(-100, 100);
    this->maximumSpinBox->setSingleStep(1);

    this->{valueSpinBox} = Qt::SpinBox();
    this->valueSpinBox->setRange(-100, 100);
    this->valueSpinBox->setSingleStep(1);

    this->{orientationCombo} = Qt::ComboBox();
    this->orientationCombo->addItem(this->tr('Horizontal slider-like widgets'));
    this->orientationCombo->addItem(this->tr('Vertical slider-like widgets'));

# [6] //! [7]
    this->connect(this->orientationCombo, SIGNAL 'activated(int)',
# [7] //! [8]
            this->stackedWidget, SLOT 'setCurrentIndex(int)');
    this->connect(this->minimumSpinBox, SIGNAL 'valueChanged(int)',
            this->horizontalSliders, SLOT 'setMinimum(int)');
    this->connect(this->minimumSpinBox, SIGNAL 'valueChanged(int)',
            this->verticalSliders, SLOT 'setMinimum(int)');
    this->connect(this->maximumSpinBox, SIGNAL 'valueChanged(int)',
            this->horizontalSliders, SLOT 'setMaximum(int)');
    this->connect(this->maximumSpinBox, SIGNAL 'valueChanged(int)',
            this->verticalSliders, SLOT 'setMaximum(int)');
    this->connect(this->invertedAppearance, SIGNAL 'toggled(bool)',
            this->horizontalSliders, SLOT 'invertAppearance(bool)');
    this->connect(this->invertedAppearance, SIGNAL 'toggled(bool)',
            this->verticalSliders, SLOT 'invertAppearance(bool)');
    this->connect(this->invertedKeyBindings, SIGNAL 'toggled(bool)',
            this->horizontalSliders, SLOT 'invertKeyBindings(bool)');
    this->connect(this->invertedKeyBindings, SIGNAL 'toggled(bool)',
            this->verticalSliders, SLOT 'invertKeyBindings(bool)');

    my $controlsLayout = Qt::GridLayout();
    $controlsLayout->addWidget(this->minimumLabel, 0, 0);
    $controlsLayout->addWidget(this->maximumLabel, 1, 0);
    $controlsLayout->addWidget(this->valueLabel, 2, 0);
    $controlsLayout->addWidget(this->minimumSpinBox, 0, 1);
    $controlsLayout->addWidget(this->maximumSpinBox, 1, 1);
    $controlsLayout->addWidget(this->valueSpinBox, 2, 1);
    $controlsLayout->addWidget(this->invertedAppearance, 0, 2);
    $controlsLayout->addWidget(this->invertedKeyBindings, 1, 2);
    $controlsLayout->addWidget(this->orientationCombo, 3, 0, 1, 3);
    this->controlsGroup->setLayout($controlsLayout);
}
# [8]

1;
