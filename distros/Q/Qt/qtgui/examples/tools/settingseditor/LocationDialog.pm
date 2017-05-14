package LocationDialog;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Dialog );
use QtCore4::slots
    updateLocationsTable => [];

sub formatLabel() {
    return this->{formatLabel};
}

sub scopeLabel() {
    return this->{scopeLabel};
}

sub organizationLabel() {
    return this->{organizationLabel};
}

sub applicationLabel() {
    return this->{applicationLabel};
}

sub formatComboBox() {
    return this->{formatComboBox};
}

sub scopeComboBox() {
    return this->{scopeComboBox};
}

sub organizationComboBox() {
    return this->{organizationComboBox};
}

sub applicationComboBox() {
    return this->{applicationComboBox};
}

sub locationsGroupBox() {
    return this->{locationsGroupBox};
}

sub locationsTable() {
    return this->{locationsTable};
}

sub buttonBox() {
    return this->{buttonBox};
}

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{formatComboBox} = Qt::ComboBox();
    formatComboBox->addItem(this->tr('Native'));
    formatComboBox->addItem(this->tr('INI'));

    this->{scopeComboBox} = Qt::ComboBox();
    scopeComboBox->addItem(this->tr('User'));
    scopeComboBox->addItem(this->tr('System'));

    this->{organizationComboBox} = Qt::ComboBox();
    organizationComboBox->addItem(this->tr('Trolltech'));
    organizationComboBox->setEditable(1);

    this->{applicationComboBox} = Qt::ComboBox();
    applicationComboBox->addItem(this->tr('Any'));
    applicationComboBox->addItem(this->tr('Application Example'));
    applicationComboBox->addItem(this->tr('Assistant'));
    applicationComboBox->addItem(this->tr('Designer'));
    applicationComboBox->addItem(this->tr('Linguist'));
    applicationComboBox->setEditable(1);
    applicationComboBox->setCurrentIndex(3);

    this->{formatLabel} = Qt::Label(this->tr('&Format:'));
    formatLabel->setBuddy(formatComboBox);

    this->{scopeLabel} = Qt::Label(this->tr('&Scope:'));
    scopeLabel->setBuddy(scopeComboBox);

    this->{organizationLabel} = Qt::Label(this->tr('&Organization:'));
    organizationLabel->setBuddy(organizationComboBox);

    this->{applicationLabel} = Qt::Label(this->tr('&Application:'));
    applicationLabel->setBuddy(applicationComboBox);

    this->{locationsGroupBox} = Qt::GroupBox(this->tr('Setting Locations'));

    my @labels = (this->tr('Location'), this->tr('Access'));

    this->{locationsTable} = Qt::TableWidget();
    locationsTable->setSelectionMode(Qt::AbstractItemView::SingleSelection());
    locationsTable->setSelectionBehavior(Qt::AbstractItemView::SelectRows());
    locationsTable->setEditTriggers(Qt::AbstractItemView::NoEditTriggers());
    locationsTable->setColumnCount(2);
    locationsTable->setHorizontalHeaderLabels(\@labels);
    locationsTable->horizontalHeader()->setResizeMode(0, Qt::HeaderView::Stretch());
    locationsTable->horizontalHeader()->resizeSection(1, 180);

    this->{buttonBox} = Qt::DialogButtonBox(Qt::DialogButtonBox::Ok()
                                     | Qt::DialogButtonBox::Cancel());

    this->connect(formatComboBox, SIGNAL 'activated(int)',
            this, SLOT 'updateLocationsTable()');
    this->connect(scopeComboBox, SIGNAL 'activated(int)',
            this, SLOT 'updateLocationsTable()');
    this->connect(organizationComboBox->lineEdit(),
            SIGNAL 'editingFinished()',
            this, SLOT 'updateLocationsTable()');
    this->connect(applicationComboBox->lineEdit(),
            SIGNAL 'editingFinished()',
            this, SLOT 'updateLocationsTable()');
    this->connect(buttonBox, SIGNAL 'accepted()', this, SLOT 'accept()');
    this->connect(buttonBox, SIGNAL 'rejected()', this, SLOT 'reject()');

    my $locationsLayout = Qt::VBoxLayout();
    $locationsLayout->addWidget(locationsTable);
    locationsGroupBox->setLayout($locationsLayout);

    my $mainLayout = Qt::GridLayout();
    $mainLayout->addWidget(formatLabel, 0, 0);
    $mainLayout->addWidget(formatComboBox, 0, 1);
    $mainLayout->addWidget(scopeLabel, 1, 0);
    $mainLayout->addWidget(scopeComboBox, 1, 1);
    $mainLayout->addWidget(organizationLabel, 2, 0);
    $mainLayout->addWidget(organizationComboBox, 2, 1);
    $mainLayout->addWidget(applicationLabel, 3, 0);
    $mainLayout->addWidget(applicationComboBox, 3, 1);
    $mainLayout->addWidget(locationsGroupBox, 4, 0, 1, 2);
    $mainLayout->addWidget(buttonBox, 5, 0, 1, 2);
    this->setLayout($mainLayout);

    updateLocationsTable();

    setWindowTitle(this->tr('Open Application Settings'));
    resize(650, 400);
}

sub format
{
    if (formatComboBox->currentIndex() == 0) {
        return Qt::Settings::NativeFormat();
    }
    else {
        return Qt::Settings::IniFormat();
    }
}

sub scope
{
    if (scopeComboBox->currentIndex() == 0) {
        return Qt::Settings::UserScope();
    }
    else {
        return Qt::Settings::SystemScope();
    }
}

sub organization
{
    return organizationComboBox->currentText();
}

sub application
{
    if (applicationComboBox->currentText() eq this->tr('Any')) {
        return '';
    }
    else {
        return applicationComboBox->currentText();
    }
}

sub updateLocationsTable
{
    locationsTable->setUpdatesEnabled(0);
    locationsTable->setRowCount(0);

    for (my $i = 0; $i < 2; ++$i) {
        if ($i == 0 && scope() == Qt::Settings::SystemScope()) {
            next;
        }

        my $actualScope = ($i == 0) ? Qt::Settings::UserScope()
                                                : Qt::Settings::SystemScope();
        for (my $j = 0; $j < 2; ++$j) {
            if ($j == 0 && !application()) {
                next;
            }

            my $actualApplication;
            if ($j == 0) {
                $actualApplication = application();
            }
            my $settings = Qt::Settings(this->format(), $actualScope, organization(),
                               $actualApplication);

            my $row = locationsTable->rowCount();
            locationsTable->setRowCount($row + 1);

            my $item0 = Qt::TableWidgetItem();
            $item0->setText($settings->fileName());

            my $item1 = Qt::TableWidgetItem();
            my $disable = (scalar @{$settings->childKeys()} == 0
                            && scalar @{$settings->childGroups()} == 0);

            if ($row == 0) {
                if ($settings->isWritable()) {
                    $item1->setText(this->tr('Read-write'));
                    $disable = 0;
                } else {
                    $item1->setText(this->tr('Read-only'));
                }
                buttonBox->button(Qt::DialogButtonBox::Ok())->setDisabled($disable);
            } else {
                $item1->setText(this->tr('Read-only fallback'));
            }

            if ($disable) {
                $item0->setFlags($item0->flags() & ~Qt::ItemIsEnabled());
                $item1->setFlags($item1->flags() & ~Qt::ItemIsEnabled());
            }

            locationsTable->setItem($row, 0, $item0);
            locationsTable->setItem($row, 1, $item1);
        }
    }

    locationsTable->setUpdatesEnabled(1);
}

1;
