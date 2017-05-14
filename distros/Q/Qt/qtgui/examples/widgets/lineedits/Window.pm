package Window;

use strict;
use warnings;

use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    echoChanged => ['int'],
    validatorChanged => ['int'],
    alignmentChanged => ['int'],
    inputMaskChanged => ['int'],
    accessChanged => ['int'];

sub echoLineEdit() {
    return this->{echoLineEdit};
}

sub setEchoLineEdit() {
    return this->{echoLineEdit} = shift;
}

sub validatorLineEdit() {
    return this->{validatorLineEdit};
}

sub setValidatorLineEdit() {
    return this->{validatorLineEdit} = shift;
}

sub alignmentLineEdit() {
    return this->{alignmentLineEdit};
}

sub setAlignmentLineEdit() {
    return this->{alignmentLineEdit} = shift;
}

sub inputMaskLineEdit() {
    return this->{inputMaskLineEdit};
}

sub setInputMaskLineEdit() {
    return this->{inputMaskLineEdit} = shift;
}

sub accessLineEdit() {
    return this->{accessLineEdit};
}

sub setAccessLineEdit() {
    return this->{accessLineEdit} = shift;
}

# [0]

# [0]
sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );

    my $echoGroup = Qt::GroupBox(this->tr('Echo'));

    my $echoLabel = Qt::Label(this->tr('Mode:'));
    my $echoComboBox = Qt::ComboBox();
    $echoComboBox->addItem(this->tr('Normal'));
    $echoComboBox->addItem(this->tr('Password'));
    $echoComboBox->addItem(this->tr('PasswordEchoOnEdit'));
    $echoComboBox->addItem(this->tr('No Echo'));

    this->setEchoLineEdit( Qt::LineEdit() );
    this->echoLineEdit->setFocus();
# [0]

# [1]
    my $validatorGroup = Qt::GroupBox(this->tr('Validator'));

    my $validatorLabel = Qt::Label(this->tr('Type:'));
    my $validatorComboBox = Qt::ComboBox();
    $validatorComboBox->addItem(this->tr('No validator'));
    $validatorComboBox->addItem(this->tr('Integer validator'));
    $validatorComboBox->addItem(this->tr('Double validator'));

    this->setValidatorLineEdit( Qt::LineEdit() );
# [1]

# [2]
    my $alignmentGroup = Qt::GroupBox(this->tr('Alignment'));

    my $alignmentLabel = Qt::Label(this->tr('Type:'));
    my $alignmentComboBox = Qt::ComboBox();
    $alignmentComboBox->addItem(this->tr('Left'));
    $alignmentComboBox->addItem(this->tr('Centered'));
    $alignmentComboBox->addItem(this->tr('Right'));

    this->setAlignmentLineEdit( Qt::LineEdit() );
# [2]

# [3]
    my $inputMaskGroup = Qt::GroupBox(this->tr('Input mask'));

    my $inputMaskLabel = Qt::Label(this->tr('Type:'));
    my $inputMaskComboBox = Qt::ComboBox();
    $inputMaskComboBox->addItem(this->tr('No mask'));
    $inputMaskComboBox->addItem(this->tr('Phone number'));
    $inputMaskComboBox->addItem(this->tr('ISO date'));
    $inputMaskComboBox->addItem(this->tr('License key'));

    this->setInputMaskLineEdit( Qt::LineEdit() );
# [3]

# [4]
    my $accessGroup = Qt::GroupBox(this->tr('Access'));

    my $accessLabel = Qt::Label(this->tr('Read-only:'));
    my $accessComboBox = Qt::ComboBox();
    $accessComboBox->addItem(this->tr('False'));
    $accessComboBox->addItem(this->tr('True'));

    this->setAccessLineEdit( Qt::LineEdit() );
# [4]

# [5]
    this->connect($echoComboBox, SIGNAL 'activated(int)',
            this, SLOT 'echoChanged(int)');
    this->connect($validatorComboBox, SIGNAL 'activated(int)',
            this, SLOT 'validatorChanged(int)');
    this->connect($alignmentComboBox, SIGNAL 'activated(int)',
            this, SLOT 'alignmentChanged(int)');
    this->connect($inputMaskComboBox, SIGNAL 'activated(int)',
            this, SLOT 'inputMaskChanged(int)');
    this->connect($accessComboBox, SIGNAL 'activated(int)',
            this, SLOT 'accessChanged(int)');
# [5]

# [6]
    my $echoLayout = Qt::GridLayout();
    $echoLayout->addWidget($echoLabel, 0, 0);
    $echoLayout->addWidget($echoComboBox, 0, 1);
    $echoLayout->addWidget(this->echoLineEdit, 1, 0, 1, 2);
    $echoGroup->setLayout($echoLayout);
# [6]

# [7]
    my $validatorLayout = Qt::GridLayout();
    $validatorLayout->addWidget($validatorLabel, 0, 0);
    $validatorLayout->addWidget($validatorComboBox, 0, 1);
    $validatorLayout->addWidget(this->validatorLineEdit, 1, 0, 1, 2);
    $validatorGroup->setLayout($validatorLayout);

    my $alignmentLayout = Qt::GridLayout();
    $alignmentLayout->addWidget($alignmentLabel, 0, 0);
    $alignmentLayout->addWidget($alignmentComboBox, 0, 1);
    $alignmentLayout->addWidget(this->alignmentLineEdit, 1, 0, 1, 2);
    $alignmentGroup->setLayout($alignmentLayout);

    my $inputMaskLayout = Qt::GridLayout();
    $inputMaskLayout->addWidget($inputMaskLabel, 0, 0);
    $inputMaskLayout->addWidget($inputMaskComboBox, 0, 1);
    $inputMaskLayout->addWidget(this->inputMaskLineEdit, 1, 0, 1, 2);
    $inputMaskGroup->setLayout($inputMaskLayout);

    my $accessLayout = Qt::GridLayout();
    $accessLayout->addWidget($accessLabel, 0, 0);
    $accessLayout->addWidget($accessComboBox, 0, 1);
    $accessLayout->addWidget(this->accessLineEdit, 1, 0, 1, 2);
    $accessGroup->setLayout($accessLayout);
# [7]

# [8]
    my $layout = Qt::GridLayout();
    $layout->addWidget($echoGroup, 0, 0);
    $layout->addWidget($validatorGroup, 1, 0);
    $layout->addWidget($alignmentGroup, 2, 0);
    $layout->addWidget($inputMaskGroup, 0, 1);
    $layout->addWidget($accessGroup, 1, 1);
    this->setLayout($layout);

    this->setWindowTitle(this->tr('Line Edits'));
}
# [8]

# [9]
sub echoChanged {
    my ($index) = @_;
    if ($index == 0) {
        this->echoLineEdit->setEchoMode(Qt::LineEdit::Normal());
    }
    elsif ( $index == 1 ) {
        this->echoLineEdit->setEchoMode(Qt::LineEdit::Password());
    }
    elsif ( $index == 2 ) {
    	this->echoLineEdit->setEchoMode(Qt::LineEdit::PasswordEchoOnEdit());
    }
    elsif ( $index == 3 ) {
        this->echoLineEdit->setEchoMode(Qt::LineEdit::NoEcho());
    }
}
# [9]

# [10]
sub validatorChanged {
    my ($index) = @_;
    if ( $index == 0 ) {
        this->validatorLineEdit->setValidator(undef);
    }
    elsif ( $index == 1 ) {
        this->validatorLineEdit->setValidator(Qt::IntValidator(
            this->validatorLineEdit));
    }
    elsif ( $index == 2 ) {
        this->validatorLineEdit->setValidator(Qt::DoubleValidator(-999.0,
            999.0, 2, this->validatorLineEdit));
    }

    this->validatorLineEdit->clear();
}
# [10]

# [11]
sub alignmentChanged {
    my ($index) = @_;
    if ( $index == 0 ) {
        this->alignmentLineEdit->setAlignment(Qt::AlignLeft());
    }
    elsif ( $index == 1 ) {
        this->alignmentLineEdit->setAlignment(Qt::AlignCenter());
    }
    elsif ( $index == 2 ) {
    	this->alignmentLineEdit->setAlignment(Qt::AlignRight());
    }
}
# [11]

# [12]
sub inputMaskChanged {
    my ($index) = @_;
    if ( $index == 0 ) {
        this->inputMaskLineEdit->setInputMask('');
    }
    elsif ( $index == 1 ) {
        this->inputMaskLineEdit->setInputMask('+99 99 99 99 99;_');
    }
    elsif ( $index == 2 ) {
        this->inputMaskLineEdit->setInputMask('0000-00-00');
        this->inputMaskLineEdit->setText('00000000');
        this->inputMaskLineEdit->setCursorPosition(0);
    }
    elsif ( $index == 3 ) {
        this->inputMaskLineEdit->setInputMask('>AAAAA-AAAAA-AAAAA-AAAAA-AAAAA;#');
    }
}
# [12]

# [13]
sub accessChanged {
    my ($index) = @_;
    if ( $index == 0 ) {
        this->accessLineEdit->setReadOnly(0);
    }
    elsif ( $index == 1 ) {
        this->accessLineEdit->setReadOnly(1);
    }
}
# [13]

1;
