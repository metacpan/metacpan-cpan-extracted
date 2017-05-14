package FindDialog;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Dialog );

# [0]
sub NEW {
    shift->SUPER::NEW(@_);
    my $label = Qt::Label(this->tr("Find &what:"));
    my $lineEdit = Qt::LineEdit();
    $label->setBuddy($lineEdit);

    my $caseCheckBox = Qt::CheckBox(this->tr("Match &case"));
    my $fromStartCheckBox = Qt::CheckBox(this->tr("Search from &start"));
    $fromStartCheckBox->setChecked(1);

# [1]
    my $findButton = Qt::PushButton(this->tr("&Find"));
    $findButton->setDefault(1);

    my $moreButton = Qt::PushButton(this->tr("&More"));
    $moreButton->setCheckable(1);
# [0]
    $moreButton->setAutoDefault(0);

    my $buttonBox = Qt::DialogButtonBox(Qt::Vertical());
    $buttonBox->addButton($findButton, Qt::DialogButtonBox::ActionRole());
    $buttonBox->addButton($moreButton, Qt::DialogButtonBox::ActionRole());
# [1]

# [2]
    my $extension = Qt::Widget();

    my $wholeWordsCheckBox = Qt::CheckBox(this->tr("&Whole words"));
    my $backwardCheckBox = Qt::CheckBox(this->tr("Search &backward"));
    my $searchSelectionCheckBox = Qt::CheckBox(this->tr("Search se&lection"));
# [2]

# [3]
    this->connect($moreButton, SIGNAL 'toggled(bool)', $extension, SLOT 'setVisible(bool)');

    my $extensionLayout = Qt::VBoxLayout();
    $extensionLayout->setMargin(0);
    $extensionLayout->addWidget($wholeWordsCheckBox);
    $extensionLayout->addWidget($backwardCheckBox);
    $extensionLayout->addWidget($searchSelectionCheckBox);
    $extension->setLayout($extensionLayout);
# [3]

# [4]
    my $topLeftLayout = Qt::HBoxLayout();
    $topLeftLayout->addWidget($label);
    $topLeftLayout->addWidget($lineEdit);

    my $leftLayout = Qt::VBoxLayout();
    $leftLayout->addLayout($topLeftLayout);
    $leftLayout->addWidget($caseCheckBox);
    $leftLayout->addWidget($fromStartCheckBox);
    $leftLayout->addStretch(1);

    my $mainLayout = Qt::GridLayout();
    $mainLayout->setSizeConstraint(Qt::Layout::SetFixedSize());
    $mainLayout->addLayout($leftLayout, 0, 0);
    $mainLayout->addWidget($buttonBox, 0, 1);
    $mainLayout->addWidget($extension, 1, 0, 1, 2);
    this->setLayout($mainLayout);

    this->setWindowTitle(this->tr("Extension"));
# [4] //! [5]
    $extension->hide();
}
# [5]

1;
