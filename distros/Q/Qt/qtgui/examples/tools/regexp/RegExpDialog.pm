package RegExpDialog;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Dialog );
use QtCore4::slots
    refresh => [];

use constant { MaxCaptures => 6 };
sub patternLabel() {
    return this->{patternLabel};
}

sub escapedPatternLabel() {
    return this->{escapedPatternLabel};
}

sub syntaxLabel() {
    return this->{syntaxLabel};
}

sub textLabel() {
    return this->{textLabel};
}

sub patternComboBox() {
    return this->{patternComboBox};
}

sub escapedPatternLineEdit() {
    return this->{escapedPatternLineEdit};
}

sub textComboBox() {
    return this->{textComboBox};
}

sub caseSensitiveCheckBox() {
    return this->{caseSensitiveCheckBox};
}

sub minimalCheckBox() {
    return this->{minimalCheckBox};
}

sub syntaxComboBox() {
    return this->{syntaxComboBox};
}

sub indexLabel() {
    return this->{indexLabel};
}

sub matchedLengthLabel() {
    return this->{matchedLengthLabel};
}

sub indexEdit() {
    return this->{indexEdit};
}

sub matchedLengthEdit() {
    return this->{matchedLengthEdit};
}

sub captureLabels() {
    return this->{captureLabels};
}

sub captureEdits() {
    return this->{captureEdits};
}

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{patternComboBox} = Qt::ComboBox();
    patternComboBox->setEditable(1);
    patternComboBox->setSizePolicy(Qt::SizePolicy::Expanding(),
                                   Qt::SizePolicy::Preferred());

    this->{patternLabel} = Qt::Label(this->tr('&Pattern:'));
    patternLabel->setBuddy(patternComboBox);

    this->{escapedPatternLineEdit} = Qt::LineEdit();
    escapedPatternLineEdit->setReadOnly(1);
    my $palette = escapedPatternLineEdit->palette();
    $palette->setBrush(Qt::Palette::Base(),
                     $palette->brush(Qt::Palette::Disabled(), Qt::Palette::Base()));
    escapedPatternLineEdit->setPalette($palette);

    this->{escapedPatternLabel} = Qt::Label(this->tr('&Escaped Pattern:'));
    escapedPatternLabel->setBuddy(escapedPatternLineEdit);

    this->{syntaxComboBox} = Qt::ComboBox();
    syntaxComboBox->addItem(this->tr('Regular expression v1'), Qt::Variant(Qt::Int(${Qt::RegExp::RegExp()})));
    syntaxComboBox->addItem(this->tr('Regular expression v2'), Qt::Variant(Qt::Int(${Qt::RegExp::RegExp2()})));
    syntaxComboBox->addItem(this->tr('Wildcard'), Qt::Variant(Qt::Int(${Qt::RegExp::Wildcard()})));
    syntaxComboBox->addItem(this->tr('Fixed string'), Qt::Variant(Qt::Int(${Qt::RegExp::FixedString()})));
    syntaxComboBox->addItem(this->tr('W3C Xml Schema 1.1'), Qt::Variant(Qt::Int(${Qt::RegExp::W3CXmlSchema11()})));

    this->{syntaxLabel} = Qt::Label(this->tr('&Pattern Syntax:'));
    syntaxLabel->setBuddy(syntaxComboBox);

    this->{textComboBox} = Qt::ComboBox();
    textComboBox->setEditable(1);
    textComboBox->setSizePolicy(Qt::SizePolicy::Expanding(), Qt::SizePolicy::Preferred());

    this->{textLabel} = Qt::Label(this->tr('&Text:'));
    textLabel->setBuddy(textComboBox);

    this->{caseSensitiveCheckBox} = Qt::CheckBox(this->tr('Case &Sensitive'));
    caseSensitiveCheckBox->setChecked(1);
    this->{minimalCheckBox} = Qt::CheckBox(this->tr('&Minimal'));

    this->{indexLabel} = Qt::Label(this->tr('Index of Match:'));
    this->{indexEdit} = Qt::LineEdit();
    indexEdit->setReadOnly(1);

    this->{matchedLengthLabel} = Qt::Label(this->tr('Matched Length:'));
    this->{matchedLengthEdit} = Qt::LineEdit();
    matchedLengthEdit->setReadOnly(1);

    this->{captureLabels} = [];
    this->{captureEdits} = [];
    for (my $i = 0; $i < MaxCaptures; ++$i) {
        push @{captureLabels()}, Qt::Label(sprintf this->tr('Capture %d:'), $i);
        push @{captureEdits()}, Qt::LineEdit();
        captureEdits()->[$i]->setReadOnly(1);
    }
    captureLabels->[0]->setText(this->tr('Match:'));

    my $checkBoxLayout = Qt::HBoxLayout();
    $checkBoxLayout->addWidget(caseSensitiveCheckBox);
    $checkBoxLayout->addWidget(minimalCheckBox);
    $checkBoxLayout->addStretch(1);

    my $mainLayout = Qt::GridLayout();
    $mainLayout->addWidget(patternLabel, 0, 0);
    $mainLayout->addWidget(patternComboBox, 0, 1);
    $mainLayout->addWidget(escapedPatternLabel, 1, 0);
    $mainLayout->addWidget(escapedPatternLineEdit, 1, 1);
    $mainLayout->addWidget(syntaxLabel, 2, 0);
    $mainLayout->addWidget(syntaxComboBox, 2, 1);
    $mainLayout->addLayout($checkBoxLayout, 3, 0, 1, 2);
    $mainLayout->addWidget(textLabel, 4, 0);
    $mainLayout->addWidget(textComboBox, 4, 1);
    $mainLayout->addWidget(indexLabel, 5, 0);
    $mainLayout->addWidget(indexEdit, 5, 1);
    $mainLayout->addWidget(matchedLengthLabel, 6, 0);
    $mainLayout->addWidget(matchedLengthEdit, 6, 1);

    for (my $j = 0; $j < MaxCaptures; ++$j) {
        $mainLayout->addWidget(captureLabels()->[$j], 7 + $j, 0);
        $mainLayout->addWidget(captureEdits()->[$j], 7 + $j, 1);
    }
    this->setLayout($mainLayout);

    this->connect(patternComboBox, SIGNAL 'editTextChanged(QString)',
            this, SLOT 'refresh()');
    this->connect(textComboBox, SIGNAL 'editTextChanged(QString)',
            this, SLOT 'refresh()');
    this->connect(caseSensitiveCheckBox, SIGNAL 'toggled(bool)',
            this, SLOT 'refresh()');
    this->connect(minimalCheckBox, SIGNAL 'toggled(bool)', this, SLOT 'refresh()');
    this->connect(syntaxComboBox, SIGNAL 'currentIndexChanged(int)',
            this, SLOT 'refresh()');

    patternComboBox->addItem(this->tr('[A-Za-z_]+([A-Za-z_0-9]*)'));
    textComboBox->addItem(this->tr('(10 + delta4) * 32'));

    setWindowTitle(this->tr('RegExp'));
    setFixedHeight(sizeHint()->height());
    refresh();
}

sub refresh
{
    setUpdatesEnabled(0);

    my $pattern = patternComboBox->currentText();
    my $text = textComboBox->currentText();

    my $escaped = $pattern;
    $escaped =~ s/\\/\\\\/g;
    $escaped =~ s/'/\\'/g;
    $escaped = "'$escaped'";
    escapedPatternLineEdit->setText($escaped);

    my $rx = Qt::RegExp($pattern);
    my $cs = Qt::CaseInsensitive();
    if (caseSensitiveCheckBox->isChecked()) {
        $cs = Qt::CaseSensitive();
    }
    $rx->setCaseSensitivity($cs);
    $rx->setMinimal(minimalCheckBox->isChecked());
    my $syntax = syntaxComboBox->itemData(syntaxComboBox->currentIndex())->toInt();
    $rx->setPatternSyntax($syntax);

    my $palette = patternComboBox->palette();
    if ($rx->isValid()) {
        $palette->setColor(Qt::Palette::Text(),
                         textComboBox->palette()->color(Qt::Palette::Text()));
    } else {
        $palette->setColor(Qt::Palette::Text(), Qt::Color(Qt::red()));
    }
    patternComboBox->setPalette($palette);

    indexEdit->setText($rx->indexIn($text));
    matchedLengthEdit->setText($rx->matchedLength());
    for (my $i = 0; $i < MaxCaptures; ++$i) {
        captureLabels->[$i]->setEnabled($i <= $rx->captureCount());
        captureEdits->[$i]->setEnabled($i <= $rx->captureCount());
        captureEdits->[$i]->setText($rx->cap($i));
    }

    setUpdatesEnabled(1);
}

1;
