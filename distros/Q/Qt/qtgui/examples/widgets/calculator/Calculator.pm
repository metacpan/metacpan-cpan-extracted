package Calculator;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Dialog );

use QtCore4::slots
    digitClicked => [],
    unaryOperatorClicked => [],
    additiveOperatorClicked => [],
    multiplicativeOperatorClicked => [],
    equalClicked => [],
    pointClicked => [],
    changeSignClicked => [],
    backspaceClicked => [],
    clear => [],
    clearAll => [],
    clearMemory => [],
    readMemory => [],
    setMemory => [],
    addToMemory => [];

use Button;

use constant { NumDigitButtons => 10 };

sub sumInMemory() {
    return this->{sumInMemory};
}

sub sumSoFar() {
    return this->{sumSoFar};
}

sub factorSoFar() {
    return this->{factorSoFar};
}

sub pendingAdditiveOperator() {
    return this->{pendingAdditiveOperator};
}

sub pendingMultiplicativeOperator() {
    return this->{pendingMultiplicativeOperator};
}

sub waitingForOperand() {
    return this->{waitingForOperand};
}

sub display() {
    return this->{display};
}

sub digitButtons() {
    return this->{digitButtons};
}

# [0]
sub NEW {
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);

    this->{sumInMemory} = 0.0;
    this->{sumSoFar} = 0.0;
    this->{factorSoFar} = 0.0;
    this->{waitingForOperand} = 1;
# [0]

# [1]
    my $display = Qt::LineEdit('0');
    this->{display} = $display;
# [1] //! [2]
    $display->setReadOnly(1);
    $display->setAlignment(Qt::AlignRight());
    $display->setMaxLength(15);

    my $font = $display->font();
    $font->setPointSize($font->pointSize() + 8);
    $display->setFont($font);

# [2]

# [4]
    for (my $i = 0; $i < NumDigitButtons; ++$i) {
        this->{digitButtons}->[$i] = this->createButton($i, SLOT 'digitClicked()');
    }

    my $pointButton = this->createButton(this->tr('.'), SLOT 'pointClicked()');
    my $str;
    my $changeSignButton = this->createButton(this->tr("\261"), SLOT 'changeSignClicked()');

    my $backspaceButton = this->createButton(this->tr('Backspace'), SLOT 'backspaceClicked()');
    my $clearButton = this->createButton(this->tr('Clear'), SLOT 'clear()');
    my $clearAllButton = this->createButton(this->tr('Clear All'), SLOT 'clearAll()');

    my $clearMemoryButton = this->createButton(this->tr('MC'), SLOT 'clearMemory()');
    my $readMemoryButton = this->createButton(this->tr('MR'), SLOT 'readMemory()');
    my $setMemoryButton = this->createButton(this->tr('MS'), SLOT 'setMemory()');
    my $addToMemoryButton = this->createButton(this->tr('M+'), SLOT 'addToMemory()');

    my $divisionButton = this->createButton(this->tr("\367"), SLOT 'multiplicativeOperatorClicked()');
    my $timesButton = this->createButton(this->tr("\327"), SLOT 'multiplicativeOperatorClicked()');
    my $minusButton = this->createButton(this->tr('-'), SLOT 'additiveOperatorClicked()');
    my $plusButton = this->createButton(this->tr('+'), SLOT 'additiveOperatorClicked()');

    my $squareRootButton = this->createButton(this->tr('Sqrt'), SLOT 'unaryOperatorClicked()');
    my $powerButton = this->createButton(this->tr("x\262"), SLOT 'unaryOperatorClicked()');
    my $reciprocalButton = this->createButton(this->tr('1/x'), SLOT 'unaryOperatorClicked()');
    my $equalButton = this->createButton(this->tr('='), SLOT 'equalClicked()');

    this->{pointButton} = $pointButton;
    this->{changeSignButton} = $changeSignButton;
    this->{backspaceButton} = $backspaceButton;
    this->{clearButton} = $clearButton;
    this->{clearAllButton} = $clearAllButton;
    this->{clearMemoryButton} = $clearMemoryButton;
    this->{readMemoryButton} = $readMemoryButton;
    this->{setMemoryButton} = $setMemoryButton;
    this->{addToMemoryButton} = $addToMemoryButton;
    this->{divisionButton} = $divisionButton;
    this->{timesButton} = $timesButton;
    this->{minusButton} = $minusButton;
    this->{plusButton} = $plusButton;
    this->{squareRootButton} = $squareRootButton;
    this->{powerButton} = $powerButton;
    this->{reciprocalButton} = $reciprocalButton;
    this->{equalButton} = $equalButton;
# [4]
# [5]
    my $mainLayout = Qt::GridLayout();
# [5] //! [6]
    $mainLayout->setSizeConstraint(Qt::Layout::SetFixedSize());

    $mainLayout->addWidget($display, 0, 0, 1, 6);
    $mainLayout->addWidget($backspaceButton, 1, 0, 1, 2);
    $mainLayout->addWidget($clearButton, 1, 2, 1, 2);
    $mainLayout->addWidget($clearAllButton, 1, 4, 1, 2);

    $mainLayout->addWidget($clearMemoryButton, 2, 0);
    $mainLayout->addWidget($readMemoryButton, 3, 0);
    $mainLayout->addWidget($setMemoryButton, 4, 0);
    $mainLayout->addWidget($addToMemoryButton, 5, 0);

    for (my $i = 1; $i < NumDigitButtons; ++$i) {
        my $row = ((9 - $i) / 3) + 2;
        my $column = (($i - 1) % 3) + 1;
        $mainLayout->addWidget(this->digitButtons->[$i], $row, $column);
    }

    $mainLayout->addWidget(this->digitButtons->[0], 5, 1);
    $mainLayout->addWidget($pointButton, 5, 2);
    $mainLayout->addWidget($changeSignButton, 5, 3);

    $mainLayout->addWidget($divisionButton, 2, 4);
    $mainLayout->addWidget($timesButton, 3, 4);
    $mainLayout->addWidget($minusButton, 4, 4);
    $mainLayout->addWidget($plusButton, 5, 4);

    $mainLayout->addWidget($squareRootButton, 2, 5);
    $mainLayout->addWidget($powerButton, 3, 5);
    $mainLayout->addWidget($reciprocalButton, 4, 5);
    $mainLayout->addWidget($equalButton, 5, 5);
    this->setLayout($mainLayout);

    this->setWindowTitle(this->tr('Calculator'));
}
# [6]

# [7]
sub digitClicked {
    my $clickedButton = this->sender();
    my $digitValue = $clickedButton->text();
    if (this->display->text() eq '0' && $digitValue == 0.0) {
        return;
    }

    if (this->waitingForOperand) {
        this->display->clear();
        this->{waitingForOperand} = 0;
    }
    this->display->setText(this->display->text() . $digitValue);
}
# [7]

# [8]
sub unaryOperatorClicked {
# [8] //! [9]
    my $clickedButton = this->sender();
    my $clickedOperator = $clickedButton->text();
    my $operand = this->display->text();
    my $result = 0.0;

    if ($clickedOperator eq this->tr('Sqrt')) {
        if ($operand < 0.0) {
            this->abortOperation();
            return;
        }
        $result = sqrt($operand);
    } elsif ($clickedOperator eq this->tr("x\262")) {
        $result = $operand**2.0;
    } elsif ($clickedOperator eq this->tr('1/x')) {
        if ($operand == 0.0) {
            this->abortOperation();
            return;
        }
        $result = 1.0 / $operand;
    }
    this->display->setText($result);
    this->{waitingForOperand} = 1;
}
# [9]

# [10]
sub additiveOperatorClicked {
# [10] //! [11]
    my $clickedButton = this->sender();
    my $clickedOperator = $clickedButton->text();
    my $operand = this->display->text();

# [11] //! [12]
    if (this->pendingMultiplicativeOperator) {
# [12] //! [13]
        if (!this->calculate($operand, this->pendingMultiplicativeOperator)) {
            this->abortOperation();
            return;
        }
        this->display->setText(this->factorSoFar);
        $operand = this->factorSoFar;
        this->{factorSoFar} = 0.0;
        this->{pendingMultiplicativeOperator} = undef;
    }

# [13] //! [14]
    if (this->pendingAdditiveOperator) {
# [14] //! [15]
        if (!this->calculate($operand, this->pendingAdditiveOperator)) {
            this->abortOperation();
            return;
        }
        this->display->setText(this->sumSoFar);
    } else {
        this->{sumSoFar} = $operand;
    }

# [15] //! [16]
    this->{pendingAdditiveOperator} = $clickedOperator;
# [16] //! [17]
    this->{waitingForOperand} = 1;
}
# [17]

# [18]
sub multiplicativeOperatorClicked {
    my $clickedButton = this->sender();
    my $clickedOperator = $clickedButton->text();
    my $operand = this->display->text();

    if (this->pendingMultiplicativeOperator) {
        if (!this->calculate($operand, this->pendingMultiplicativeOperator)) {
            this->abortOperation();
            return;
        }
        this->display->setText(this->factorSoFar);
    } else {
        this->{factorSoFar} = $operand;
    }

    this->{pendingMultiplicativeOperator} = $clickedOperator;
    this->{waitingForOperand} = 1;
}
# [18]

# [20]
sub equalClicked {
    my $operand = this->display->text();

    if (this->pendingMultiplicativeOperator) {
        if (!this->calculate($operand, this->pendingMultiplicativeOperator)) {
            this->abortOperation();
            return;
        }
        $operand = this->{factorSoFar};
        this->{factorSoFar} = 0.0;
        this->{pendingMultiplicativeOperator} = undef;
    }
    if (this->pendingAdditiveOperator) {
        if (!this->calculate($operand, this->pendingAdditiveOperator)) {
            this->abortOperation();
            return;
        }
        this->{pendingAdditiveOperator} = undef;
    } else {
        this->{sumSoFar} = $operand;
    }

    this->display->setText(this->sumSoFar);
    this->{sumSoFar} = 0.0;
    this->{waitingForOperand} = 1;
}
# [20]

# [22]
sub pointClicked {
    if (this->waitingForOperand) {
        this->display->setText('0');
    }
    if (this->display->text() !~ m/\./) {
        this->display->setText(this->display->text() . this->tr('.'));
    }
    this->{waitingForOperand} = 0;
}
# [22]

# [24]
sub changeSignClicked {
    my $text = this->display->text();

    if ($text > 0.0) {
        $text = this->tr('-') . $text;
    } elsif ($text < 0.0) {
        $text = substr( $text, 1 );
    }
    this->display->setText($text);
}
# [24]

# [26]
sub backspaceClicked {
    if (this->waitingForOperand) {
        return;
    }

    my $text = this->display->text();
    chop($text);
    if ($text eq '') {
        $text = '0';
        this->{waitingForOperand} = 1;
    }
    this->display->setText($text);
}
# [26]

# [28]
sub clear {
    if (this->waitingForOperand) {
        return;
    }

    this->display->setText('0');
    this->{waitingForOperand} = 1;
}
# [28]

# [30]
sub clearAll {
    this->{sumSoFar} = 0.0;
    this->{factorSoFar} = 0.0;
    this->{pendingAdditiveOperator} = undef;
    this->{pendingMultiplicativeOperator} = undef;
    this->display->setText('0');
    this->{waitingForOperand} = 1;
}
# [30]

# [32]
sub clearMemory {
    this->{sumInMemory} = 0.0;
}

sub readMemory {
    this->display->setText(this->sumInMemory);
    this->{waitingForOperand} = 1;
}

sub setMemory {
    this->equalClicked();
    this->{sumInMemory} = this->display->text();
}

sub addToMemory {
    this->equalClicked();
    this->{sumInMemory} += this->display->text();
}
# [32]

# [34]
sub createButton {
    my ($text, $member) = @_;
    my $button = Button($text);
    this->connect($button, SIGNAL 'clicked()', this, $member);
    return $button;
}
# [34]

# [36]
sub abortOperation {
    clearAll();
    this->display->setText(this->tr('####'));
}
# [36]

# [38]
sub calculate {
    my ($rightOperand, $pendingOperator) = @_;
    if ($pendingOperator eq this->tr('+')) {
        this->{sumSoFar} += $rightOperand;
    } elsif ($pendingOperator eq this->tr('-')) {
        this->{sumSoFar} -= $rightOperand;
    } elsif ($pendingOperator eq this->tr("\327")) {
        this->{factorSoFar} *= $rightOperand;
    } elsif ($pendingOperator eq this->tr("\367")) {
        if ($rightOperand == 0.0) {
            return 0;
        }
        this->{factorSoFar} /= $rightOperand;
    }
    return 1;
}
# [38]

1;
