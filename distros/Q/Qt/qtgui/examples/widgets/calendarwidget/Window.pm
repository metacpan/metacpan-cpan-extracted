package Window;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Widget );

# [0]
use QtCore4::slots
    localeChanged => ['int'],
    firstDayChanged => ['int'],
    selectionModeChanged => ['int'],
    horizontalHeaderChanged => ['int'],
    verticalHeaderChanged => ['int'],
    selectedDateChanged => [],
    minimumDateChanged => ['QDate'],
    maximumDateChanged => ['QDate'],
    weekdayFormatChanged => [],
    weekendFormatChanged => [],
    reformatHeaders => [],
    reformatCalendarPage => [];

sub previewGroupBox() {
    return this->{previewGroupBox};
}

sub previewLayout() {
    return this->{previewLayout};
}

sub calendar() {
    return this->{calendar};
}

sub generalOptionsGroupBox() {
    return this->{generalOptionsGroupBox};
}

sub localeLabel() {
    return this->{localeLabel};
}

sub firstDayLabel() {
    return this->{firstDayLabel};
}

# [0]
sub selectionModeLabel() {
    return this->{selectionModeLabel};
}

sub horizontalHeaderLabel() {
    return this->{horizontalHeaderLabel};
}

sub verticalHeaderLabel() {
    return this->{verticalHeaderLabel};
}

sub localeCombo() {
    return this->{localeCombo};
}

sub firstDayCombo() {
    return this->{firstDayCombo};
}

sub selectionModeCombo() {
    return this->{selectionModeCombo};
}

sub gridCheckBox() {
    return this->{gridCheckBox};
}

sub navigationCheckBox() {
    return this->{navigationCheckBox};
}

sub horizontalHeaderCombo() {
    return this->{horizontalHeaderCombo};
}

sub verticalHeaderCombo() {
    return this->{verticalHeaderCombo};
}

sub datesGroupBox() {
    return this->{datesGroupBox};
}

sub currentDateLabel() {
    return this->{currentDateLabel};
}

sub minimumDateLabel() {
    return this->{minimumDateLabel};
}

sub maximumDateLabel() {
    return this->{maximumDateLabel};
}

sub currentDateEdit() {
    return this->{currentDateEdit};
}

sub minimumDateEdit() {
    return this->{minimumDateEdit};
}

sub maximumDateEdit() {
    return this->{maximumDateEdit};
}

sub textFormatsGroupBox() {
    return this->{textFormatsGroupBox};
}

sub weekdayColorLabel() {
    return this->{weekdayColorLabel};
}

sub weekendColorLabel() {
    return this->{weekendColorLabel};
}

sub headerTextFormatLabel() {
    return this->{headerTextFormatLabel};
}

sub weekdayColorCombo() {
    return this->{weekdayColorCombo};
}

sub weekendColorCombo() {
    return this->{weekendColorCombo};
}

sub headerTextFormatCombo() {
    return this->{headerTextFormatCombo};
}

sub firstFridayCheckBox() {
    return this->{firstFridayCheckBox};
}

# [1]
sub mayFirstCheckBox() {
    return this->{mayFirstCheckBox};
}

# [1]

# [0]
sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
    this->createPreviewGroupBox();
    this->createGeneralOptionsGroupBox();
    this->createDatesGroupBox();
    this->createTextFormatsGroupBox();

    my $layout = Qt::GridLayout();
    $layout->addWidget(this->previewGroupBox, 0, 0);
    $layout->addWidget(this->generalOptionsGroupBox, 0, 1);
    $layout->addWidget(this->datesGroupBox, 1, 0);
    $layout->addWidget(this->textFormatsGroupBox, 1, 1);
    $layout->setSizeConstraint(Qt::Layout::SetFixedSize());
    this->setLayout($layout);

    this->previewLayout->setRowMinimumHeight(0, this->calendar->sizeHint()->height());
    this->previewLayout->setColumnMinimumWidth(0, this->calendar->sizeHint()->width());

    this->setWindowTitle(this->tr('Calendar Widget'));
}
# [0]

sub localeChanged {
    my ($index) = @_;
    this->calendar->setLocale(this->localeCombo->itemData($index)->toLocale());
}

# [1]
sub firstDayChanged {
    my ($index) = @_;
    this->calendar->setFirstDayOfWeek(
                                this->firstDayCombo->itemData($index)->toInt());
}
# [1]

sub selectionModeChanged {
    my ($index) = @_;
    this->calendar->setSelectionMode(
                               this->selectionModeCombo->itemData($index)->toInt());
}

sub horizontalHeaderChanged {
    my ($index) = @_;
    this->calendar->setHorizontalHeaderFormat(
        this->horizontalHeaderCombo->itemData($index)->toInt());
}

sub verticalHeaderChanged {
    my ($index) = @_;
    this->calendar->setVerticalHeaderFormat(
        this->verticalHeaderCombo->itemData($index)->toInt());
}

# [2]
sub selectedDateChanged {
    this->currentDateEdit->setDate(this->calendar->selectedDate());
}
# [2]

# [3]
sub minimumDateChanged {
    my ($date) = @_;
    this->calendar->setMinimumDate($date);
    this->maximumDateEdit->setDate(this->calendar->maximumDate());
}
# [3]

# [4]
sub maximumDateChanged {
    my ($date) = @_;
    this->calendar->setMaximumDate($date);
    this->minimumDateEdit->setDate(this->calendar->minimumDate());
}
# [4]

# [5]
sub weekdayFormatChanged {
    my $format = Qt::TextCharFormat();

    $format->setForeground( Qt::Brush(
        Qt::qVariantValue(
            this->weekdayColorCombo->itemData(this->weekdayColorCombo->currentIndex()),
            'Qt::Color')
        )
    );
    this->calendar->setWeekdayTextFormat(Qt::Monday(), $format);
    this->calendar->setWeekdayTextFormat(Qt::Tuesday(), $format);
    this->calendar->setWeekdayTextFormat(Qt::Wednesday(), $format);
    this->calendar->setWeekdayTextFormat(Qt::Thursday(), $format);
    this->calendar->setWeekdayTextFormat(Qt::Friday(), $format);
}
# [5]

# [6]
sub weekendFormatChanged {
    my $format = Qt::TextCharFormat();

    $format->setForeground( Qt::Brush(
        Qt::qVariantValue(
            this->weekendColorCombo->itemData(this->weekendColorCombo->currentIndex()),
            'Qt::Color')
        )
    );
    this->calendar->setWeekdayTextFormat(Qt::Saturday(), $format);
    this->calendar->setWeekdayTextFormat(Qt::Sunday(), $format);
}
# [6]

# [7]
sub reformatHeaders {
    my $text = this->headerTextFormatCombo->currentText();
    my $format = Qt::TextCharFormat();

    if ($text eq this->tr('Bold')) {
        $format->setFontWeight(Qt::Font::Bold());
    } elsif ($text eq this->tr('Italic')) {
        $format->setFontItalic(1);
    } elsif ($text eq this->tr('Green')) {
        $format->setForeground(Qt::Color(Qt::green()));
    }
    this->calendar->setHeaderTextFormat($format);
}
# [7]

# [8]
sub reformatCalendarPage {
    my $mayFirstFormat = Qt::TextCharFormat();
    this->{mayFirstFormat} = $mayFirstFormat;
    if (this->mayFirstCheckBox->isChecked()) {
        $mayFirstFormat->setForeground(Qt::Brush(Qt::red()));
    }

    my $firstFridayFormat = Qt::TextCharFormat();
    this->{firstFridayFormat} = $firstFridayFormat;
    if (this->firstFridayCheckBox->isChecked()) {
        $firstFridayFormat->setForeground(Qt::Brush(Qt::blue()));
    }

    my $date = Qt::Date(this->calendar->yearShown(), this->calendar->monthShown(), 1); 

    this->calendar->setDateTextFormat(Qt::Date($date->year(), 5, 1), $mayFirstFormat);

    $date->setDate($date->year(), $date->month(), 1);
    while ($date->dayOfWeek() != Qt::Friday()) {
        $date = $date->addDays(1);
    }
    this->calendar->setDateTextFormat($date, $firstFridayFormat);
}
# [8]

# [9]
sub createPreviewGroupBox {
    my $previewGroupBox = Qt::GroupBox(this->tr('Preview'));
    this->{previewGroupBox} = $previewGroupBox;

    my $calendar = Qt::CalendarWidget();
    this->{calendar} = $calendar;
    $calendar->setMinimumDate(Qt::Date(1900, 1, 1));
    $calendar->setMaximumDate(Qt::Date(3000, 1, 1));
    $calendar->setGridVisible(1);

    this->connect($calendar, SIGNAL 'currentPageChanged(int, int)',
            this, SLOT 'reformatCalendarPage()');

    my $previewLayout = Qt::GridLayout();
    this->{previewLayout} = $previewLayout;
    $previewLayout->addWidget($calendar, 0, 0, Qt::AlignCenter());
    $previewGroupBox->setLayout($previewLayout);
}
# [9]

# [10]
sub createGeneralOptionsGroupBox {
    my $generalOptionsGroupBox = Qt::GroupBox(this->tr('General Options'));
    this->{generalOptionsGroupBox} = $generalOptionsGroupBox;

    my $localeCombo = Qt::ComboBox();
    this->{localeCombo} = $localeCombo;
    my $curLocaleIndex = -1;
    my $index = 0;
    for (my $_lang = Qt::Locale::C(); $_lang <= Qt::Locale::LastLanguage(); ++$_lang) {
        #Qt::Locale::Language lang = static_cast<Qt::Locale::Language>(_lang);
        my $lang = $_lang;
        my $countries = Qt::Locale::countriesForLanguage($lang);
        next unless $countries && ref $countries eq 'ARRAY';
        for (my $i = 0; $i < scalar @{$countries}; ++$i) {
            my $country = $countries->[$i];
            my $label = Qt::Locale::languageToString($lang);
            $label .= '/';
            $label .= Qt::Locale::countryToString($country);
            my $locale = Qt::Locale($lang, $country);
            if (this->locale()->language() == $lang && this->locale()->country() == $country) {
                $curLocaleIndex = $index;
            }
            $localeCombo->addItem($label, Qt::Variant($locale));
            ++$index;
        }
    }
    if ($curLocaleIndex != -1) {
        $localeCombo->setCurrentIndex($curLocaleIndex);
    }
    my $localeLabel = Qt::Label(this->tr('&Locale'));
    this->{localeLabel} = $localeLabel;
    $localeLabel->setBuddy($localeCombo);

    my $firstDayCombo = Qt::ComboBox();
    this->{firstDayCombo} = $firstDayCombo;
    $firstDayCombo->addItem(this->tr('Sunday'), Qt::Variant(Qt::Int(${Qt::Sunday()})));
    $firstDayCombo->addItem(this->tr('Monday'), Qt::Variant(Qt::Int(${Qt::Monday()})));
    $firstDayCombo->addItem(this->tr('Tuesday'), Qt::Variant(Qt::Int(${Qt::Tuesday()})));
    $firstDayCombo->addItem(this->tr('Wednesday'), Qt::Variant(Qt::Int(${Qt::Wednesday()})));
    $firstDayCombo->addItem(this->tr('Thursday'), Qt::Variant(Qt::Int(${Qt::Thursday()})));
    $firstDayCombo->addItem(this->tr('Friday'), Qt::Variant(Qt::Int(${Qt::Friday()})));
    $firstDayCombo->addItem(this->tr('Saturday'), Qt::Variant(Qt::Int(${Qt::Saturday()})));

    my $firstDayLabel = Qt::Label(this->tr('Wee&k starts on:'));
    this->{firstDayLabel} = $firstDayLabel;
    $firstDayLabel->setBuddy($firstDayCombo);
# [10]

    my $selectionModeCombo = Qt::ComboBox();
    this->{selectionModeCombo} = $selectionModeCombo;
    $selectionModeCombo->addItem(this->tr('Single selection'),
                                Qt::Variant(Qt::Int(${Qt::CalendarWidget::SingleSelection()})));
    $selectionModeCombo->addItem(this->tr('None'), Qt::Variant(Qt::Int(${Qt::CalendarWidget::NoSelection()})));

    my $selectionModeLabel = Qt::Label(this->tr('&Selection mode:'));
    this->{selectionModeLabel} = $selectionModeLabel;
    $selectionModeLabel->setBuddy($selectionModeCombo);

    my $gridCheckBox = Qt::CheckBox(this->tr('&Grid'));
    this->{gridCheckBox} = $gridCheckBox;
    $gridCheckBox->setChecked(this->calendar->isGridVisible());

    my $navigationCheckBox = Qt::CheckBox(this->tr('&Navigation bar'));
    this->{navigationCheckBox} = $navigationCheckBox;
    $navigationCheckBox->setChecked(1);

    my $horizontalHeaderCombo = Qt::ComboBox();
    this->{horizontalHeaderCombo} = $horizontalHeaderCombo;
    $horizontalHeaderCombo->addItem(this->tr('Single letter day names'),
                                   Qt::Variant(Qt::Int(${Qt::CalendarWidget::SingleLetterDayNames()})));
    $horizontalHeaderCombo->addItem(this->tr('Short day names'),
                                   Qt::Variant(Qt::Int(${Qt::CalendarWidget::ShortDayNames()})));
    $horizontalHeaderCombo->addItem(this->tr('None'),
                                   Qt::Variant(Qt::Int(${Qt::CalendarWidget::NoHorizontalHeader()})));
    $horizontalHeaderCombo->setCurrentIndex(1);

    my $horizontalHeaderLabel = Qt::Label(this->tr('&Horizontal header:'));
    this->{horizontalHeaderLabel} = $horizontalHeaderLabel;
    $horizontalHeaderLabel->setBuddy($horizontalHeaderCombo);

    my $verticalHeaderCombo = Qt::ComboBox();
    this->{verticalHeaderCombo} = $verticalHeaderCombo;
    $verticalHeaderCombo->addItem(this->tr('ISO week numbers'),
                                 Qt::Variant(Qt::Int(${Qt::CalendarWidget::ISOWeekNumbers()})));
    $verticalHeaderCombo->addItem(this->tr('None'), Qt::Variant(Qt::Int(${Qt::CalendarWidget::NoVerticalHeader()})));

    my $verticalHeaderLabel = Qt::Label(this->tr('&Vertical header:'));
    this->{verticalHeaderLabel} = $verticalHeaderLabel;
    $verticalHeaderLabel->setBuddy($verticalHeaderCombo);

# [11]
    this->connect($localeCombo, SIGNAL 'currentIndexChanged(int)',
            this, SLOT 'localeChanged(int)');
    this->connect($firstDayCombo, SIGNAL 'currentIndexChanged(int)',
            this, SLOT 'firstDayChanged(int)');
    this->connect($selectionModeCombo, SIGNAL 'currentIndexChanged(int)',
            this, SLOT 'selectionModeChanged(int)');
    this->connect($gridCheckBox, SIGNAL 'toggled(bool)',
            calendar, SLOT 'setGridVisible(bool)');
    this->connect($navigationCheckBox, SIGNAL 'toggled(bool)',
            calendar, SLOT 'setNavigationBarVisible(bool)');
    this->connect($horizontalHeaderCombo, SIGNAL 'currentIndexChanged(int)',
            this, SLOT 'horizontalHeaderChanged(int)');
    this->connect($verticalHeaderCombo, SIGNAL 'currentIndexChanged(int)',
            this, SLOT 'verticalHeaderChanged(int)');
# [11]

    my $checkBoxLayout = Qt::HBoxLayout();
    $checkBoxLayout->addWidget($gridCheckBox);
    $checkBoxLayout->addStretch();
    $checkBoxLayout->addWidget($navigationCheckBox);

    my $outerLayout = Qt::GridLayout();
    $outerLayout->addWidget($localeLabel, 0, 0);
    $outerLayout->addWidget($localeCombo, 0, 1);
    $outerLayout->addWidget($firstDayLabel, 1, 0);
    $outerLayout->addWidget($firstDayCombo, 1, 1);
    $outerLayout->addWidget($selectionModeLabel, 2, 0);
    $outerLayout->addWidget($selectionModeCombo, 2, 1);
    $outerLayout->addLayout($checkBoxLayout, 3, 0, 1, 2);
    $outerLayout->addWidget($horizontalHeaderLabel, 4, 0);
    $outerLayout->addWidget($horizontalHeaderCombo, 4, 1);
    $outerLayout->addWidget($verticalHeaderLabel, 5, 0);
    $outerLayout->addWidget($verticalHeaderCombo, 5, 1);
    $generalOptionsGroupBox->setLayout($outerLayout);

# [12]
    this->firstDayChanged(this->firstDayCombo->currentIndex());
    this->selectionModeChanged(this->selectionModeCombo->currentIndex());
    this->horizontalHeaderChanged(this->horizontalHeaderCombo->currentIndex());
    this->verticalHeaderChanged(this->verticalHeaderCombo->currentIndex());
}
# [12]

# [13]
sub createDatesGroupBox {
    my $datesGroupBox = Qt::GroupBox(this->tr('Dates'));
    this->{datesGroupBox} = $datesGroupBox;

    my $minimumDateEdit = Qt::DateEdit();
    this->{minimumDateEdit} = $minimumDateEdit;
    $minimumDateEdit->setDisplayFormat('MMM d yyyy');
    $minimumDateEdit->setDateRange(this->calendar->minimumDate(),
                                  this->calendar->maximumDate());
    $minimumDateEdit->setDate(this->calendar->minimumDate());

    my $minimumDateLabel = Qt::Label(this->tr('&Minimum Date:'));
    this->{minimumDateLabel} = $minimumDateLabel;
    $minimumDateLabel->setBuddy($minimumDateEdit);

    my $currentDateEdit = Qt::DateEdit();
    this->{currentDateEdit} = $currentDateEdit;
    $currentDateEdit->setDisplayFormat('MMM d yyyy');
    $currentDateEdit->setDate(this->calendar->selectedDate());
    $currentDateEdit->setDateRange(this->calendar->minimumDate(),
                                  this->calendar->maximumDate());

    my $currentDateLabel = Qt::Label(this->tr('&Current Date:'));
    this->{currentDateLabel} = $currentDateLabel;
    $currentDateLabel->setBuddy($currentDateEdit);

    my $maximumDateEdit = Qt::DateEdit();
    this->{maximumDateEdit} = $maximumDateEdit;
    $maximumDateEdit->setDisplayFormat('MMM d yyyy');
    $maximumDateEdit->setDateRange(this->calendar->minimumDate(),
                                  this->calendar->maximumDate());
    $maximumDateEdit->setDate(this->calendar->maximumDate());

    my $maximumDateLabel = Qt::Label(this->tr('Ma&ximum Date:'));
    this->{maximumDateLabel} = $maximumDateLabel;
    $maximumDateLabel->setBuddy($maximumDateEdit);

# [13] //! [14]
    this->connect(currentDateEdit, SIGNAL 'dateChanged(const QDate &)',
            calendar, SLOT 'setSelectedDate(const QDate &)');
    this->connect(calendar, SIGNAL 'selectionChanged()',
            this, SLOT 'selectedDateChanged()');
    this->connect(minimumDateEdit, SIGNAL 'dateChanged(const QDate &)',
            this, SLOT 'minimumDateChanged(const QDate &)');
    this->connect(maximumDateEdit, SIGNAL 'dateChanged(const QDate &)',
            this, SLOT 'maximumDateChanged(const QDate &)');

# [14]
    my $dateBoxLayout = Qt::GridLayout();
    $dateBoxLayout->addWidget($currentDateLabel, 1, 0);
    $dateBoxLayout->addWidget($currentDateEdit, 1, 1);
    $dateBoxLayout->addWidget($minimumDateLabel, 0, 0);
    $dateBoxLayout->addWidget($minimumDateEdit, 0, 1);
    $dateBoxLayout->addWidget($maximumDateLabel, 2, 0);
    $dateBoxLayout->addWidget($maximumDateEdit, 2, 1);
    $dateBoxLayout->setRowStretch(3, 1);

    $datesGroupBox->setLayout($dateBoxLayout);
# [15]
}
# [15]

# [16]
sub createTextFormatsGroupBox {
    my $textFormatsGroupBox = Qt::GroupBox(this->tr('Text Formats'));
    this->{textFormatsGroupBox} = $textFormatsGroupBox;

    my $weekdayColorCombo = this->createColorComboBox();
    this->{weekdayColorCombo} = $weekdayColorCombo;
    $weekdayColorCombo->setCurrentIndex(
            $weekdayColorCombo->findText(this->tr('Black')));

    my $weekdayColorLabel = Qt::Label(this->tr('&Weekday color:'));
    this->{weekdayColorLabel} = $weekdayColorLabel;
    $weekdayColorLabel->setBuddy($weekdayColorCombo);

    my $weekendColorCombo = this->createColorComboBox();
    this->{weekendColorCombo} = $weekendColorCombo;
    $weekendColorCombo->setCurrentIndex(
            $weekendColorCombo->findText(this->tr('Red')));

    my $weekendColorLabel = Qt::Label(this->tr('Week&end color:'));
    this->{weekendColorLabel} = $weekendColorLabel;
    $weekendColorLabel->setBuddy($weekendColorCombo);

# [16] //! [17]
    my $headerTextFormatCombo = Qt::ComboBox();
    this->{headerTextFormatCombo} = $headerTextFormatCombo;
    $headerTextFormatCombo->addItem(this->tr('Bold'));
    $headerTextFormatCombo->addItem(this->tr('Italic'));
    $headerTextFormatCombo->addItem(this->tr('Plain'));

    my $headerTextFormatLabel = Qt::Label(this->tr('&Header text:'));
    this->{headerTextFormatLabel} = $headerTextFormatLabel;
    $headerTextFormatLabel->setBuddy($headerTextFormatCombo);

    my $firstFridayCheckBox = Qt::CheckBox(this->tr('&First Friday in blue'));
    this->{firstFridayCheckBox} = $firstFridayCheckBox;

    my $mayFirstCheckBox = Qt::CheckBox(this->tr('May &1 in red'));
    this->{mayFirstCheckBox} = $mayFirstCheckBox;

# [17] //! [18]
    this->connect($weekdayColorCombo, SIGNAL 'currentIndexChanged(int)',
            this, SLOT 'weekdayFormatChanged()');
    this->connect($weekendColorCombo, SIGNAL 'currentIndexChanged(int)',
            this, SLOT 'weekendFormatChanged()');
    this->connect($headerTextFormatCombo, SIGNAL 'currentIndexChanged(const QString &)',
            this, SLOT 'reformatHeaders()');
    this->connect($firstFridayCheckBox, SIGNAL 'toggled(bool)',
            this, SLOT 'reformatCalendarPage()');
    this->connect($mayFirstCheckBox, SIGNAL 'toggled(bool)',
            this, SLOT 'reformatCalendarPage()');

# [18]
    my $checkBoxLayout = Qt::HBoxLayout();
    $checkBoxLayout->addWidget($firstFridayCheckBox);
    $checkBoxLayout->addStretch();
    $checkBoxLayout->addWidget($mayFirstCheckBox);

    my $outerLayout = Qt::GridLayout();
    $outerLayout->addWidget($weekdayColorLabel, 0, 0);
    $outerLayout->addWidget($weekdayColorCombo, 0, 1);
    $outerLayout->addWidget($weekendColorLabel, 1, 0);
    $outerLayout->addWidget($weekendColorCombo, 1, 1);
    $outerLayout->addWidget($headerTextFormatLabel, 2, 0);
    $outerLayout->addWidget($headerTextFormatCombo, 2, 1);
    $outerLayout->addLayout($checkBoxLayout, 3, 0, 1, 2);
    $textFormatsGroupBox->setLayout($outerLayout);

    this->weekdayFormatChanged();
    this->weekendFormatChanged();
# [19]
    this->reformatHeaders();
    this->reformatCalendarPage();
}
# [19]

# [20]
sub createColorComboBox {
    my $comboBox = Qt::ComboBox();
    $comboBox->addItem(this->tr('Red'), Qt::qVariantFromValue(Qt::Color(Qt::red())));
    $comboBox->addItem(this->tr('Blue'), Qt::qVariantFromValue(Qt::Color(Qt::blue())));
    $comboBox->addItem(this->tr('Black'), Qt::qVariantFromValue(Qt::Color(Qt::black())));
    $comboBox->addItem(this->tr('Magenta'), Qt::qVariantFromValue(Qt::Color(Qt::magenta())));
    return $comboBox;
}
# [20]

1;
