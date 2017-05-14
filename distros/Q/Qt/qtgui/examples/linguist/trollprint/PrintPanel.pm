package PrintPanel;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::Widget );
# [0]
sub twoSidedGroupBox() {
    return this->{twoSidedGroupBox};
}

sub colorsGroupBox() {
    return this->{colorsGroupBox};
}

sub twoSidedEnabledRadio() {
    return this->{twoSidedEnabledRadio};
}

sub twoSidedDisabledRadio() {
    return this->{twoSidedDisabledRadio};
}

sub colorsEnabledRadio() {
    return this->{colorsEnabledRadio};
}

sub colorsDisabledRadio() {
    return this->{colorsDisabledRadio};
}

# [0]
sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);

=begin

/*
    my $label = Qt::Label(PrintPanel::tr("<b>TROLL PRINT</b>"));
    $label->setAlignment(Qt::AlignCenter());
*/

=cut

# [0]

# [1]
    this->{twoSidedGroupBox} = Qt::GroupBox(PrintPanel::tr("2-sided"));
    this->{twoSidedEnabledRadio} = Qt::RadioButton(PrintPanel::tr("Enabled"));
    this->{twoSidedDisabledRadio} = Qt::RadioButton(PrintPanel::tr("Disabled"));
# [1] //! [2]
    this->twoSidedDisabledRadio->setChecked(1);

    this->{colorsGroupBox} = Qt::GroupBox(PrintPanel::tr("Colors"));
    this->{colorsEnabledRadio} = Qt::RadioButton(PrintPanel::tr("Enabled"));
    this->{colorsDisabledRadio} = Qt::RadioButton(PrintPanel::tr("Disabled"));
# [2]
    this->colorsDisabledRadio->setChecked(1);

    my $twoSidedLayout = Qt::HBoxLayout();
    $twoSidedLayout->addWidget(this->twoSidedEnabledRadio);
    $twoSidedLayout->addWidget(this->twoSidedDisabledRadio);
    this->twoSidedGroupBox->setLayout($twoSidedLayout);

    my $colorsLayout = Qt::HBoxLayout();
    $colorsLayout->addWidget(this->colorsEnabledRadio);
    $colorsLayout->addWidget(this->colorsDisabledRadio);
    this->colorsGroupBox->setLayout($colorsLayout);

    my $mainLayout = Qt::VBoxLayout();

=begin

/*
    $mainLayout->addWidget($label);
*/

=cut

    $mainLayout->addWidget(this->twoSidedGroupBox);
    $mainLayout->addWidget(this->colorsGroupBox);
    this->setLayout($mainLayout);
}

1;
