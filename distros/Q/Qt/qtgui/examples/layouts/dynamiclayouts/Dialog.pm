package Dialog;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Dialog );
use QtCore4::slots
    buttonsOrientationChanged => ['int'],
    rotateWidgets => [],
    help => [];

sub rotableGroupBox() {
    return this->{rotableGroupBox};
}

sub rotableWidgets() {
    return this->{rotableWidgets};
}

sub optionsGroupBox() {
    return this->{optionsGroupBox};
}

sub buttonsOrientationLabel() {
    return this->{buttonsOrientationLabel};
}

sub buttonsOrientationComboBox() {
    return this->{buttonsOrientationComboBox};
}

sub buttonBox() {
    return this->{buttonBox};
}

sub closeButton() {
    return this->{closeButton};
}

sub helpButton() {
    return this->{helpButton};
}

sub rotateWidgetsButton() {
    return this->{rotateWidgetsButton};
}

sub mainLayout() {
    return this->{mainLayout};
}

sub rotableLayout() {
    return this->{rotableLayout};
}

sub optionsLayout() {
    return this->{optionsLayout};
}


sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->createRotableGroupBox();
    this->createOptionsGroupBox();
    this->createButtonBox();

    this->{mainLayout} = Qt::GridLayout();
    this->mainLayout->addWidget(this->rotableGroupBox, 0, 0);
    this->mainLayout->addWidget(this->optionsGroupBox, 1, 0);
    this->mainLayout->addWidget(this->buttonBox, 2, 0);
    this->setLayout(this->mainLayout);

    this->mainLayout->setSizeConstraint(Qt::Layout::SetMinimumSize());

    this->setWindowTitle(this->tr('Dynamic Layouts'));
}

sub buttonsOrientationChanged
{
    my ($index) = @_;
    this->mainLayout->setSizeConstraint(Qt::Layout::SetNoConstraint());
    this->setMinimumSize(0, 0);

    my $orientation = this->buttonsOrientationComboBox->itemData($index)->toInt();

    if ($orientation == this->buttonBox->orientation()) {
        return;
    }

    this->mainLayout->removeWidget(this->buttonBox);

    my $spacing = this->mainLayout->spacing();

    my $oldSizeHint = this->buttonBox->sizeHint() + Qt::Size($spacing, $spacing);
    this->buttonBox->setOrientation($orientation);
    my $newSizeHint = this->buttonBox->sizeHint() + Qt::Size($spacing, $spacing);

    if ($orientation == Qt::Horizontal()) {
        this->mainLayout->addWidget(this->buttonBox, 2, 0);
        this->resize(this->size() + Qt::Size(-($oldSizeHint->width()), $newSizeHint->height()));
    } else {
        this->mainLayout->addWidget(this->buttonBox, 0, 3, 2, 1);
        this->resize(this->size() + Qt::Size($newSizeHint->width(), -($oldSizeHint->height())));
    }

    this->mainLayout->setSizeConstraint(Qt::Layout::SetDefaultConstraint());
}

sub rotateWidgets
{
    die 'ASSERT: $rotableWidgets->count() % 2 == 0' if !(scalar @{this->rotableWidgets} % 2 == 0);

    foreach my $widget ( @{this->rotableWidgets} ) {
        this->rotableLayout->removeWidget($widget);
    }

    push @{this->rotableWidgets}, shift @{this->rotableWidgets};

    my $n = scalar @{this->rotableWidgets};
    for (my $i = 0; $i < $n / 2; ++$i) {
        this->rotableLayout->addWidget(this->rotableWidgets->[$n - $i - 1], 0, $i);
        this->rotableLayout->addWidget(this->rotableWidgets->[$i], 1, $i);
    }
}

sub help
{
    Qt::MessageBox::information(this, this->tr('Dynamic Layouts Help'),
                               this->tr('This example shows how to change layouts ' .
                                  'dynamically.'));
}

sub createRotableGroupBox
{
    this->{rotableGroupBox} = Qt::GroupBox(this->tr('Rotable Widgets'));

    this->{rotableWidgets} = [];
    push @{this->rotableWidgets}, Qt::SpinBox();
    push @{this->rotableWidgets}, Qt::Slider();
    push @{this->rotableWidgets}, Qt::Dial();
    push @{this->rotableWidgets}, Qt::ProgressBar();

    my $n = scalar @{this->rotableWidgets};
    for (my $i = 0; $i < $n; ++$i) {
        this->connect(this->rotableWidgets->[$i], SIGNAL 'valueChanged(int)',
                this->rotableWidgets->[($i + 1) % $n], SLOT 'setValue(int)');
    }

    this->{rotableLayout} = Qt::GridLayout();
    this->rotableGroupBox->setLayout(this->rotableLayout);

    this->rotateWidgets();
}

sub createOptionsGroupBox
{
    this->{optionsGroupBox} = Qt::GroupBox(this->tr('Options'));

    this->{buttonsOrientationLabel} = Qt::Label(this->tr('Orientation of buttons:'));

    this->{buttonsOrientationComboBox} = Qt::ComboBox();
    this->buttonsOrientationComboBox->addItem(this->tr('Horizontal'), Qt::Variant(Qt::Int(${Qt::Horizontal()})));
    this->buttonsOrientationComboBox->addItem(this->tr('Vertical'), Qt::Variant(Qt::Int(${Qt::Vertical()})));

    this->connect(this->buttonsOrientationComboBox, SIGNAL 'currentIndexChanged(int)',
            this, SLOT 'buttonsOrientationChanged(int)');

    this->{optionsLayout} = Qt::GridLayout();
    this->optionsLayout->addWidget(this->buttonsOrientationLabel, 0, 0);
    this->optionsLayout->addWidget(this->buttonsOrientationComboBox, 0, 1);
    this->optionsLayout->setColumnStretch(2, 1);
    this->optionsGroupBox->setLayout(this->optionsLayout);
}

sub createButtonBox
{
    this->{buttonBox} = Qt::DialogButtonBox();

    this->{closeButton} = this->buttonBox->addButton(Qt::DialogButtonBox::Close());
    this->{helpButton} = this->buttonBox->addButton(Qt::DialogButtonBox::Help());
    this->{rotateWidgetsButton} = this->buttonBox->addButton(this->tr('Rotate &Widgets'),
                                               Qt::DialogButtonBox::ActionRole());

    this->connect(this->rotateWidgetsButton, SIGNAL 'clicked()', this, SLOT 'rotateWidgets()');
    this->connect(this->closeButton, SIGNAL 'clicked()', this, SLOT 'close()');
    this->connect(this->helpButton, SIGNAL 'clicked()', this, SLOT 'help()');
}

1;
