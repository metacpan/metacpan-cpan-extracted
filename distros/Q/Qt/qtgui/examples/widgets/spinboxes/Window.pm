package Window;

use strict;
use warnings;

use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    changePrecision => ['int'],
    setFormatString => ['const QString&'];

sub meetingEdit() {
    return this->{meetingEdit};
}

sub doubleSpinBox() {
    return this->{doubleSpinBox};
}

sub priceSpinBox() {
    return this->{priceSpinBox};
}

sub scaleSpinBox() {
    return this->{scaleSpinBox};
}

sub spinBoxesGroup() {
    return this->{spinBoxesGroup};
}

sub editsGroup() {
    return this->{editsGroup};
}

sub doubleSpinBoxesGroup() {
    return this->{doubleSpinBoxesGroup};
}

sub meetingLabel() {
    return this->{meetingLabel};
}
# [0]

# [0]
sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );

    this->createSpinBoxes();
    this->createDateTimeEdits();
    this->createDoubleSpinBoxes();

    my $layout = Qt::HBoxLayout();
    $layout->addWidget(this->spinBoxesGroup);
    $layout->addWidget(this->editsGroup);
    $layout->addWidget(this->doubleSpinBoxesGroup);
    this->setLayout($layout);

    this->setWindowTitle(this->tr('Spin Boxes'));
}
# [0]

# [1]
sub createSpinBoxes {
    my $spinBoxesGroup = this->{spinBoxesGroup} = Qt::GroupBox(this->tr('Spinboxes'));

    my $integerLabel = this->{integerLabel} =
        Qt::Label( sprintf this->tr('Enter a value between %d and %d:'), -20, 20 );
    my $integerSpinBox = this->{integerSpinBox} = Qt::SpinBox();
    $integerSpinBox->setRange(-20, 20);
    $integerSpinBox->setSingleStep(1);
    $integerSpinBox->setValue(0);
# [1]

# [2]
    my $zoomLabel = this->{zoomLabel} =
        Qt::Label( sprintf this->tr('Enter a zoom value between %d and %d:'), 0, 1000 );
# [3]
    my $zoomSpinBox = this->{zoomSpinBox} = Qt::SpinBox();
    $zoomSpinBox->setRange(0, 1000);
    $zoomSpinBox->setSingleStep(10);
    $zoomSpinBox->setSuffix('%');
    $zoomSpinBox->setSpecialValueText(this->tr('Automatic'));
    $zoomSpinBox->setValue(100);
# [2] //! [3]

# [4]
    my $priceLabel = this->{priceLabel} =
        Qt::Label( sprintf this->tr('Enter a price between %d and %d:'), 0, 999 );
    my $priceSpinBox = this->{priceSpinBox} = Qt::SpinBox();
    $priceSpinBox->setRange(0, 999);
    $priceSpinBox->setSingleStep(1);
    $priceSpinBox->setPrefix('$');
    $priceSpinBox->setValue(99);
# [4] //! [5]

    my $spinBoxLayout = this->{spinBoxLayout} = Qt::VBoxLayout();
    $spinBoxLayout->addWidget($integerLabel);
    $spinBoxLayout->addWidget($integerSpinBox);
    $spinBoxLayout->addWidget($zoomLabel);
    $spinBoxLayout->addWidget($zoomSpinBox);
    $spinBoxLayout->addWidget($priceLabel);
    $spinBoxLayout->addWidget($priceSpinBox);
    $spinBoxesGroup->setLayout($spinBoxLayout);
}
# [5]

# [6]
sub createDateTimeEdits {
    my $editsGroup = Qt::GroupBox(this->tr('Date and time spin boxes'));
    this->{editsGroup} = $editsGroup;

    my $dateLabel = Qt::Label();
    my $dateEdit = Qt::DateEdit(Qt::Date::currentDate());
    $dateEdit->setDateRange(Qt::Date(2005, 1, 1), Qt::Date(2010, 12, 31));
    $dateLabel->setText(sprintf this->tr('Appointment date (between %s and %s):'),
                       $dateEdit->minimumDate()->toString(Qt::ISODate()),
                       ($dateEdit->maximumDate()->toString(Qt::ISODate())));
# [6]

# [7]
    my $timeLabel = Qt::Label();
    my $timeEdit = Qt::TimeEdit(Qt::Time::currentTime());
    $timeEdit->setTimeRange(Qt::Time(9, 0, 0, 0), Qt::Time(16, 30, 0, 0));
    $timeLabel->setText(sprintf this->tr('Appointment time (between %s and %s):'),
                       $timeEdit->minimumTime()->toString(Qt::ISODate()),
                       $timeEdit->maximumTime()->toString(Qt::ISODate()));
# [7]

# [8]
    my $meetingLabel = this->{meetingLabel} = Qt::Label();
    my $meetingEdit = this->{meetingEdit} = Qt::DateTimeEdit(Qt::DateTime::currentDateTime());
# [8]

# [9]
    my $formatLabel = Qt::Label(sprintf this->tr('Format string for the meeting date ' .
                                        'and time:'));
    my $formatComboBox = Qt::ComboBox();
    $formatComboBox->addItem('yyyy-MM-dd hh:mm:ss (zzz \'ms\')');
    $formatComboBox->addItem('hh:mm:ss MM/dd/yyyy');
    $formatComboBox->addItem('hh:mm:ss dd/MM/yyyy');
    $formatComboBox->addItem('hh:mm:ss');
    $formatComboBox->addItem('hh:mm ap');
# [9] //! [10]

    this->connect($formatComboBox, SIGNAL 'activated(const QString &)',
            this, SLOT 'setFormatString(const QString &)');
# [10]

    this->setFormatString($formatComboBox->currentText());

# [11]
    my $editsLayout = Qt::VBoxLayout();
    $editsLayout->addWidget($dateLabel);
    $editsLayout->addWidget($dateEdit);
    $editsLayout->addWidget($timeLabel);
    $editsLayout->addWidget($timeEdit);
    $editsLayout->addWidget($meetingLabel);
    $editsLayout->addWidget($meetingEdit);
    $editsLayout->addWidget($formatLabel);
    $editsLayout->addWidget($formatComboBox);
    $editsGroup->setLayout($editsLayout);
}
# [11]

# [12]
sub setFormatString {
    my ($formatString) = @_;
    this->meetingEdit->setDisplayFormat($formatString);
# [12] //! [13]
    if (this->meetingEdit->displayedSections() & Qt::DateTimeEdit::DateSections_Mask()) {
        this->meetingEdit->setDateRange(Qt::Date(2004, 11, 1), Qt::Date(2005, 11, 30));
        this->meetingLabel->setText(sprintf this->tr('Meeting date (between %s and %s):'),
            this->meetingEdit->minimumDate()->toString(Qt::ISODate()),
	    this->meetingEdit->maximumDate()->toString(Qt::ISODate()));
    } else {
        this->meetingEdit->setTimeRange(Qt::Time(0, 7, 20, 0), Qt::Time(21, 0, 0, 0));
        this->meetingLabel->setText( sprintf this->tr('Meeting time (between %s and %s):'),
            this->meetingEdit->minimumTime()->toString(Qt::ISODate()),
	    this->meetingEdit->maximumTime()->toString(Qt::ISODate()) );
    }
}
# [13]

# [14]
sub createDoubleSpinBoxes {
    my $doubleSpinBoxesGroup = this->{doubleSpinBoxesGroup} = Qt::GroupBox(this->tr('Double precision spinboxes'));

    my $precisionLabel = Qt::Label(this->tr('Number of decimal places ' .
                                           'to show:'));
    my $precisionSpinBox = Qt::SpinBox();
    $precisionSpinBox->setRange(0, 100);
    $precisionSpinBox->setValue(2);
# [14]

# [15]
    my $doubleLabel = Qt::Label(sprintf this->tr('Enter a value between ' .
        '%d and %d:'), -20, 20);
    my $doubleSpinBox = this->{doubleSpinBox} = Qt::DoubleSpinBox();
    $doubleSpinBox->setRange(-20.0, 20.0);
    $doubleSpinBox->setSingleStep(1.0);
    $doubleSpinBox->setValue(0.0);
# [15]

# [16]
    my $scaleLabel = Qt::Label(sprintf this->tr('Enter a scale factor between ' .
        '%d and %d:'), 0, 1000);
    my $scaleSpinBox = this->{scaleSpinBox} = Qt::DoubleSpinBox();
    $scaleSpinBox->setRange(0.0, 1000.0);
    $scaleSpinBox->setSingleStep(10.0);
    $scaleSpinBox->setSuffix('%');
    $scaleSpinBox->setSpecialValueText(this->tr('No scaling'));
    $scaleSpinBox->setValue(100.0);
# [16]

# [17]
    my $priceLabel = Qt::Label(sprintf this->tr('Enter a price between ' .
        '%d and %d:'), 0, 1000);
    my $priceSpinBox = this->{priceSpinBox} = Qt::DoubleSpinBox();
    $priceSpinBox->setRange(0.0, 1000.0);
    $priceSpinBox->setSingleStep(1.0);
    $priceSpinBox->setPrefix('$');
    $priceSpinBox->setValue(99.99);

    this->connect($precisionSpinBox, SIGNAL 'valueChanged(int)',
# [17]
            this, SLOT 'changePrecision(int)');

# [18]
    my $spinBoxLayout = Qt::VBoxLayout();
    $spinBoxLayout->addWidget($precisionLabel);
    $spinBoxLayout->addWidget($precisionSpinBox);
    $spinBoxLayout->addWidget($doubleLabel);
    $spinBoxLayout->addWidget($doubleSpinBox);
    $spinBoxLayout->addWidget($scaleLabel);
    $spinBoxLayout->addWidget($scaleSpinBox);
    $spinBoxLayout->addWidget($priceLabel);
    $spinBoxLayout->addWidget($priceSpinBox);
    $doubleSpinBoxesGroup->setLayout($spinBoxLayout);
}
# [18]

# [19]
sub changePrecision {
    my ($decimals) = @_;
    this->doubleSpinBox->setDecimals($decimals);
    this->scaleSpinBox->setDecimals($decimals);
    this->priceSpinBox->setDecimals($decimals);
}
# [19]

1;
