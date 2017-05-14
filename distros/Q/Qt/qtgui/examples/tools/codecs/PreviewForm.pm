package PreviewForm;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Dialog );
use QtCore4::slots
    updateTextEdit => [];

sub decodedString() { return decodedStr(); }

sub encodedData() {
    return this->{encodedData};
}

sub decodedStr() {
    return this->{decodedStr};
}

sub encodingComboBox() {
    return this->{encodingComboBox};
}

sub encodingLabel() {
    return this->{encodingLabel};
}

sub textEdit() {
    return this->{textEdit};
}

sub buttonBox() {
    return this->{buttonBox};
}

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{encodingComboBox} = Qt::ComboBox();

    this->{encodingLabel} = Qt::Label(this->tr('&Encoding:'));
    encodingLabel->setBuddy(encodingComboBox);

    this->{textEdit} = Qt::TextEdit();
    textEdit->setLineWrapMode(Qt::TextEdit::NoWrap());
    textEdit->setReadOnly(1);

    this->{buttonBox} = Qt::DialogButtonBox(Qt::DialogButtonBox::Ok()
                                    | Qt::DialogButtonBox::Cancel());

    this->connect(encodingComboBox, SIGNAL 'activated(int)',
            this, SLOT 'updateTextEdit()');
    this->connect(buttonBox, SIGNAL 'accepted()', this, SLOT 'accept()');
    this->connect(buttonBox, SIGNAL 'rejected()', this, SLOT 'reject()');

    my $mainLayout = Qt::GridLayout();
    $mainLayout->addWidget(encodingLabel, 0, 0);
    $mainLayout->addWidget(encodingComboBox, 0, 1);
    $mainLayout->addWidget(textEdit, 1, 0, 1, 2);
    $mainLayout->addWidget(buttonBox, 2, 0, 1, 2);
    this->setLayout($mainLayout);

    setWindowTitle(this->tr('Choose Encoding'));
    resize(400, 300);
}

sub setCodecList
{
    my ($list) = @_;
    encodingComboBox->clear();
    foreach my $codec ( @{$list} ) {
        encodingComboBox->addItem($codec->name()->constData(), Qt::Variant(Qt::Int($codec->mibEnum())));
    }
}

sub setEncodedData
{
    my ($data) = @_;
    this->{encodedData} = $data;
    updateTextEdit();
}

sub updateTextEdit
{
    my $mib = encodingComboBox->itemData(
                      encodingComboBox->currentIndex())->toInt();
    my $codec = Qt::TextCodec::codecForMib($mib);

    my $in = Qt::TextStream(encodedData);
    $in->setAutoDetectUnicode(0);
    $in->setCodec($codec);
    this->{decodedStr} = $in->readAll();

    textEdit->setPlainText(decodedStr);
}

1;
