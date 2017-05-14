package ConfigurationPage;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );

sub NEW {
    shift->SUPER::NEW( @_ );
    my $configGroup = Qt::GroupBox(this->tr('Server configuration'));

    my $serverLabel = Qt::Label(this->tr('Server:'));
    my $serverCombo = Qt::ComboBox();
    $serverCombo->addItem(this->tr('Qt Software (Australia)'));
    $serverCombo->addItem(this->tr('Qt Software (Germany)'));
    $serverCombo->addItem(this->tr('Qt Software (Norway)'));
    $serverCombo->addItem(this->tr('Qt Software (People\'s Republic of China)'));
    $serverCombo->addItem(this->tr('Qt Software (USA)'));

    my $serverLayout = Qt::HBoxLayout();
    $serverLayout->addWidget($serverLabel);
    $serverLayout->addWidget($serverCombo);

    my $configLayout = Qt::VBoxLayout();
    $configLayout->addLayout($serverLayout);
    $configGroup->setLayout($configLayout);

    my $mainLayout = Qt::VBoxLayout();
    $mainLayout->addWidget($configGroup);
    $mainLayout->addStretch(1);
    this->setLayout($mainLayout);
}

package UpdatePage;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );

sub NEW {
    shift->SUPER::NEW( @_ );
    my $updateGroup = Qt::GroupBox(this->tr('Package selection'));
    my $systemCheckBox = Qt::CheckBox(this->tr('Update system'));
    my $appsCheckBox = Qt::CheckBox(this->tr('Update applications'));
    my $docsCheckBox = Qt::CheckBox(this->tr('Update documentation'));

    my $packageGroup = Qt::GroupBox(this->tr('Existing packages'));

    my $packageList = Qt::ListWidget();
    my $qtItem = Qt::ListWidgetItem($packageList);
    $qtItem->setText(this->tr('Qt'));
    my $qsaItem = Qt::ListWidgetItem($packageList);
    $qsaItem->setText(this->tr('QSA'));
    my $teamBuilderItem = Qt::ListWidgetItem($packageList);
    $teamBuilderItem->setText(this->tr('Teambuilder'));

    my $startUpdateButton = Qt::PushButton(this->tr('Start update'));

    my $updateLayout = Qt::VBoxLayout();
    $updateLayout->addWidget($systemCheckBox);
    $updateLayout->addWidget($appsCheckBox);
    $updateLayout->addWidget($docsCheckBox);
    $updateGroup->setLayout($updateLayout);

    my $packageLayout = Qt::VBoxLayout();
    $packageLayout->addWidget($packageList);
    $packageGroup->setLayout($packageLayout);

    my $mainLayout = Qt::VBoxLayout();
    $mainLayout->addWidget($updateGroup);
    $mainLayout->addWidget($packageGroup);
    $mainLayout->addSpacing(12);
    $mainLayout->addWidget($startUpdateButton);
    $mainLayout->addStretch(1);
    this->setLayout($mainLayout);
}

package QueryPage;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );

sub NEW {
    shift->SUPER::NEW( @_ );
    my $packagesGroup = Qt::GroupBox(this->tr('Look for packages'));

    my $nameLabel = Qt::Label(this->tr('Name:'));
    my $nameEdit = Qt::LineEdit();

    my $dateLabel = Qt::Label(this->tr('Released after:'));
    my $dateEdit = Qt::DateTimeEdit(Qt::Date::currentDate());

    my $releasesCheckBox = Qt::CheckBox(this->tr('Releases'));
    my $upgradesCheckBox = Qt::CheckBox(this->tr('Upgrades'));

    my $hitsSpinBox = Qt::SpinBox();
    $hitsSpinBox->setPrefix(this->tr('Return up to '));
    $hitsSpinBox->setSuffix(this->tr(' results'));
    $hitsSpinBox->setSpecialValueText(this->tr('Return only the first result'));
    $hitsSpinBox->setMinimum(1);
    $hitsSpinBox->setMaximum(100);
    $hitsSpinBox->setSingleStep(10);

    my $startQueryButton = Qt::PushButton(this->tr('Start query'));

    my $packagesLayout = Qt::GridLayout();
    $packagesLayout->addWidget($nameLabel, 0, 0);
    $packagesLayout->addWidget($nameEdit, 0, 1);
    $packagesLayout->addWidget($dateLabel, 1, 0);
    $packagesLayout->addWidget($dateEdit, 1, 1);
    $packagesLayout->addWidget($releasesCheckBox, 2, 0);
    $packagesLayout->addWidget($upgradesCheckBox, 3, 0);
    $packagesLayout->addWidget($hitsSpinBox, 4, 0, 1, 2);
    $packagesGroup->setLayout($packagesLayout);

    my $mainLayout = Qt::VBoxLayout();
    $mainLayout->addWidget($packagesGroup);
    $mainLayout->addSpacing(12);
    $mainLayout->addWidget($startQueryButton);
    $mainLayout->addStretch(1);
    this->setLayout($mainLayout);
}

1;
