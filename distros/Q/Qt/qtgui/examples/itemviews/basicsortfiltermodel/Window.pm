package Window;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    filterRegExpChanged => [],
    filterColumnChanged => [],
    sortChanged => [];

sub NEW {
    shift->SUPER::NEW();
    my $proxyModel = Qt::SortFilterProxyModel();
    this->{proxyModel} = $proxyModel;
    $proxyModel->setDynamicSortFilter(1);

    my $sourceGroupBox = Qt::GroupBox(this->tr('Original Model'));
    my $proxyGroupBox = Qt::GroupBox(this->tr('Sorted/Filtered Model'));

    my $sourceView = Qt::TreeView();
    this->{sourceView} = $sourceView;
    $sourceView->setRootIsDecorated(0);
    $sourceView->setAlternatingRowColors(1);

    my $proxyView = Qt::TreeView();
    $proxyView->setRootIsDecorated(0);
    $proxyView->setAlternatingRowColors(1);
    $proxyView->setModel($proxyModel);
    $proxyView->setSortingEnabled(1);

    my $sortCaseSensitivityCheckBox = Qt::CheckBox(this->tr('Case sensitive sorting'));
    this->{sortCaseSensitivityCheckBox} = $sortCaseSensitivityCheckBox;
    my $filterCaseSensitivityCheckBox = Qt::CheckBox(this->tr('Case sensitive filter'));
    this->{filterCaseSensitivityCheckBox} = $filterCaseSensitivityCheckBox;

    my $filterPatternLineEdit = Qt::LineEdit();
    this->{filterPatternLineEdit} = $filterPatternLineEdit;
    my $filterPatternLabel = Qt::Label(this->tr('&Filter pattern:'));
    $filterPatternLabel->setBuddy($filterPatternLineEdit);

    my $filterSyntaxComboBox = Qt::ComboBox();
    this->{filterSyntaxComboBox} = $filterSyntaxComboBox;
    $filterSyntaxComboBox->addItem(this->tr('Regular expression'), Qt::Variant(Qt::RegExp::RegExp()));
    $filterSyntaxComboBox->addItem(this->tr('Wildcard'), Qt::Variant(Qt::RegExp::Wildcard()));
    $filterSyntaxComboBox->addItem(this->tr('Fixed string'), Qt::Variant(Qt::RegExp::FixedString()));
    my $filterSyntaxLabel = Qt::Label(this->tr('Filter &syntax:'));
    $filterSyntaxLabel->setBuddy($filterSyntaxComboBox);

    my $filterColumnComboBox = Qt::ComboBox();
    this->{filterColumnComboBox} = $filterColumnComboBox;
    $filterColumnComboBox->addItem(this->tr('Subject'));
    $filterColumnComboBox->addItem(this->tr('Sender'));
    $filterColumnComboBox->addItem(this->tr('Date'));
    my $filterColumnLabel = Qt::Label(this->tr('Filter &column:'));
    $filterColumnLabel->setBuddy($filterColumnComboBox);

    this->connect($filterPatternLineEdit, SIGNAL 'textChanged(const QString &)',
            this, SLOT 'filterRegExpChanged()');
    this->connect($filterSyntaxComboBox, SIGNAL 'currentIndexChanged(int)',
            this, SLOT 'filterRegExpChanged()');
    this->connect($filterColumnComboBox, SIGNAL 'currentIndexChanged(int)',
            this, SLOT 'filterColumnChanged()');
    this->connect($filterCaseSensitivityCheckBox, SIGNAL 'toggled(bool)',
            this, SLOT 'filterRegExpChanged()');
    this->connect($sortCaseSensitivityCheckBox, SIGNAL 'toggled(bool)',
            this, SLOT 'sortChanged()');

    my $sourceLayout = Qt::HBoxLayout();
    $sourceLayout->addWidget($sourceView);
    $sourceGroupBox->setLayout($sourceLayout);

    my $proxyLayout = Qt::GridLayout();
    $proxyLayout->addWidget($proxyView, 0, 0, 1, 3);
    $proxyLayout->addWidget($filterPatternLabel, 1, 0);
    $proxyLayout->addWidget($filterPatternLineEdit, 1, 1, 1, 2);
    $proxyLayout->addWidget($filterSyntaxLabel, 2, 0);
    $proxyLayout->addWidget($filterSyntaxComboBox, 2, 1, 1, 2);
    $proxyLayout->addWidget($filterColumnLabel, 3, 0);
    $proxyLayout->addWidget($filterColumnComboBox, 3, 1, 1, 2);
    $proxyLayout->addWidget($filterCaseSensitivityCheckBox, 4, 0, 1, 2);
    $proxyLayout->addWidget($sortCaseSensitivityCheckBox, 4, 2);
    $proxyGroupBox->setLayout($proxyLayout);

    my $mainLayout = Qt::VBoxLayout();
    $mainLayout->addWidget($sourceGroupBox);
    $mainLayout->addWidget($proxyGroupBox);
    this->setLayout($mainLayout);

    this->setWindowTitle(this->tr('Basic Sort/Filter Model'));
    this->resize(500, 450);

    $proxyView->sortByColumn(1, Qt::AscendingOrder());
    $filterColumnComboBox->setCurrentIndex(1);

    $filterPatternLineEdit->setText('Andy|Grace');
    $filterCaseSensitivityCheckBox->setChecked(1);
    $sortCaseSensitivityCheckBox->setChecked(1);
}

sub setSourceModel {
    my ( $model ) = @_;
    my $proxyModel = this->{proxyModel};
    my $sourceView = this->{sourceView};
    $proxyModel->setSourceModel($model);
    $sourceView->setModel($model);
}

sub filterRegExpChanged {
    my $filterSyntaxComboBox = this->{filterSyntaxComboBox};
    my $filterCaseSensitivityCheckBox = this->{filterCaseSensitivityCheckBox};
    my $filterPatternLineEdit = this->{filterPatternLineEdit};
    my $proxyModel = this->{proxyModel};
    my $syntax =
            $filterSyntaxComboBox->itemData(
                    $filterSyntaxComboBox->currentIndex())->toInt();
    my $caseSensitivity =
            $filterCaseSensitivityCheckBox->isChecked() ? Qt::CaseSensitive()
                                                       : Qt::CaseInsensitive();

    my $regExp = Qt::RegExp($filterPatternLineEdit->text(), $caseSensitivity, $syntax);
    $proxyModel->setFilterRegExp($regExp);
}

sub filterColumnChanged {
    my $proxyModel = this->{proxyModel};
    my $filterColumnComboBox = this->{filterColumnComboBox};
    $proxyModel->setFilterKeyColumn($filterColumnComboBox->currentIndex());
}

sub sortChanged {
    my $proxyModel = this->{proxyModel};
    my $sortCaseSensitivityCheckBox = this->{sortCaseSensitivityCheckBox};
    $proxyModel->setSortCaseSensitivity(
            $sortCaseSensitivityCheckBox->isChecked() ? Qt::CaseSensitive()
                                                     : Qt::CaseInsensitive() );
}

1;
