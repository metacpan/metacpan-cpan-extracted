package Window;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    textFilterChanged => [],
    dateFilterChanged => [];

use MySortFilterProxyModel;

sub proxyModel() {
    return this->{proxyModel};
}

sub sourceGroupBox() {
    return this->{sourceGroupBox};
}

sub proxyGroupBox() {
    return this->{proxyGroupBox};
}

sub sourceView() {
    return this->{sourceView};
}

sub proxyView() {
    return this->{proxyView};
}

sub filterCaseSensitivityCheckBox() {
    return this->{filterCaseSensitivityCheckBox};
}

sub filterPatternLabel() {
    return this->{filterPatternLabel};
}

sub fromLabel() {
    return this->{fromLabel};
}

sub toLabel() {
    return this->{toLabel};
}

sub filterPatternLineEdit() {
    return this->{filterPatternLineEdit};
}

sub filterSyntaxComboBox() {
    return this->{filterSyntaxComboBox};
}

sub fromDateEdit() {
    return this->{fromDateEdit};
}

sub toDateEdit() {
    return this->{toDateEdit};
}
# [0]

# [0]
sub NEW
{
    my ($class) = @_;
    $class->SUPER::NEW();
    this->{proxyModel} = MySortFilterProxyModel(this);
    this->proxyModel->setDynamicSortFilter(1);
# [0]

# [1]
    this->{sourceView} = Qt::TreeView();
    this->sourceView->setRootIsDecorated(0);
    this->sourceView->setAlternatingRowColors(1);
# [1]

    my $sourceLayout = Qt::HBoxLayout();
# [2]
    $sourceLayout->addWidget(this->sourceView);
    this->{sourceGroupBox} = Qt::GroupBox(this->tr('Original Model'));
    this->sourceGroupBox->setLayout($sourceLayout);
# [2]

# [3]
    this->{filterCaseSensitivityCheckBox} = Qt::CheckBox(this->tr('Case sensitive filter'));
    this->filterCaseSensitivityCheckBox->setChecked(1);

    this->{filterPatternLineEdit} = Qt::LineEdit();
    this->filterPatternLineEdit->setText('Grace|Sports');

    this->{filterPatternLabel} = Qt::Label(this->tr('&Filter pattern:'));
    this->filterPatternLabel->setBuddy(this->filterPatternLineEdit);

    this->{filterSyntaxComboBox} = Qt::ComboBox();
    this->filterSyntaxComboBox->addItem(this->tr('Regular expression'), Qt::Variant(${Qt::RegExp::RegExp()}));
    this->filterSyntaxComboBox->addItem(this->tr('Wildcard'), Qt::Variant(${Qt::RegExp::Wildcard()}));
    this->filterSyntaxComboBox->addItem(this->tr('Fixed string'), Qt::Variant(${Qt::RegExp::FixedString()}));

    this->{fromDateEdit} = Qt::DateEdit();
    this->fromDateEdit->setDate(Qt::Date(1970, 01, 01));
    this->{fromLabel} = Qt::Label(this->tr('F&rom:'));
    this->fromLabel->setBuddy(this->fromDateEdit);

    this->{toDateEdit} = Qt::DateEdit();
    this->toDateEdit->setDate(Qt::Date(2099, 12, 31));
    this->{toLabel} = Qt::Label(this->tr('&To:'));
    this->toLabel->setBuddy(this->toDateEdit);

    this->connect(this->filterPatternLineEdit, SIGNAL 'textChanged(const QString &)',
            this, SLOT 'textFilterChanged()');
    this->connect(this->filterSyntaxComboBox, SIGNAL 'currentIndexChanged(int)',
            this, SLOT 'textFilterChanged()');
    this->connect(this->filterCaseSensitivityCheckBox, SIGNAL 'toggled(bool)',
            this, SLOT 'textFilterChanged()');
    this->connect(this->fromDateEdit, SIGNAL 'dateChanged(const QDate &)',
            this, SLOT 'dateFilterChanged()');
    this->connect(this->toDateEdit, SIGNAL 'dateChanged(const QDate &)',
# [3] //! [4]
            this, SLOT 'dateFilterChanged()');
# [4]

# [5]
    this->{proxyView} = Qt::TreeView();
    this->proxyView->setRootIsDecorated(0);
    this->proxyView->setAlternatingRowColors(1);
    this->proxyView->setModel(this->proxyModel);
    this->proxyView->setSortingEnabled(1);
    proxyView->sortByColumn(1, Qt::AscendingOrder());

    my $proxyLayout = Qt::GridLayout();
    $proxyLayout->addWidget(this->proxyView, 0, 0, 1, 3);
    $proxyLayout->addWidget(this->filterPatternLabel, 1, 0);
    $proxyLayout->addWidget(this->filterPatternLineEdit, 1, 1);
    $proxyLayout->addWidget(this->filterSyntaxComboBox, 1, 2);
    $proxyLayout->addWidget(this->filterCaseSensitivityCheckBox, 2, 0, 1, 3);
    $proxyLayout->addWidget(this->fromLabel, 3, 0);
    $proxyLayout->addWidget(this->fromDateEdit, 3, 1, 1, 2);
    $proxyLayout->addWidget(this->toLabel, 4, 0);
    $proxyLayout->addWidget(this->toDateEdit, 4, 1, 1, 2);

    this->{proxyGroupBox} = Qt::GroupBox(this->tr('Sorted/Filtered Model'));
    this->proxyGroupBox->setLayout($proxyLayout);
# [5]

# [6]
    my $mainLayout = Qt::VBoxLayout();
    $mainLayout->addWidget(this->sourceGroupBox);
    $mainLayout->addWidget(this->proxyGroupBox);
    this->setLayout($mainLayout);

    emit this->dateFilterChanged();
    emit this->textFilterChanged();

    this->setWindowTitle(this->tr('Custom Sort/Filter Model'));
    this->resize(500, 450);
}
# [6]

# [7]
sub setSourceModel
{
    my ($model) = @_;
    this->proxyModel->setSourceModel($model);
    this->sourceView->setModel($model);
}
# [7]

# [8]
sub textFilterChanged
{
    my $syntax = this->filterSyntaxComboBox->itemData(this->filterSyntaxComboBox->currentIndex())->toInt();
    my $caseSensitivity = this->filterCaseSensitivityCheckBox->isChecked() ?  1 : 0;

    my $pattern = this->filterPatternLineEdit->text();
    my $regExp;
    if ( $caseSensitivity ) {
        $regExp = qr/$pattern/;
    }
    else {
        $regExp = qr/$pattern/i;
    }

    proxyModel->setFilterRegExp($regExp);
}
# [8]

# [9]
sub dateFilterChanged
{
    this->proxyModel->setFilterMinimumDate(this->fromDateEdit->date());
    this->proxyModel->setFilterMaximumDate(this->toDateEdit->date());
}
# [9]

1;
