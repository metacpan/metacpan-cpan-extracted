package Dialog;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::Dialog );
use QtCore4::slots
    setInteger => [],
    setDouble => [],
    setItem => [],
    setText => [],
    setColor => [],
    setFont => [],
    setExistingDirectory => [],
    setOpenFileName => [],
    setOpenFileNames => [],
    setSaveFileName => [],
    criticalMessage => [],
    informationMessage => [],
    questionMessage => [],
    warningMessage => [],
    errorMessage => [];

my $MESSAGE;

sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );

    $MESSAGE = Dialog::tr('<p>Message boxes have a caption, a text, ' .
        'and any number of buttons, each with standard or custom texts.' .
        '<p>Click a button to close the message box. Pressing the Esc button ' .
        'will activate the detected escape button (if any).');

    my $errorMessageDialog = Qt::ErrorMessage(this);
    this->{errorMessageDialog} = $errorMessageDialog;

    my $frameStyle = Qt::Frame::Sunken() | Qt::Frame::Panel();

    my $integerLabel = Qt::Label();
    this->{integerLabel} = $integerLabel;
    $integerLabel->setFrameStyle($frameStyle);
    my $integerButton = Qt::PushButton(this->tr('Qt::InputDialog::get&Integer()'));

    my $doubleLabel = Qt::Label();
    this->{doubleLabel} = $doubleLabel;
    $doubleLabel->setFrameStyle($frameStyle);
    my $doubleButton = Qt::PushButton(this->tr('Qt::InputDialog::get&Double()'));

    my $itemLabel = Qt::Label();
    this->{itemLabel} = $itemLabel;
    $itemLabel->setFrameStyle($frameStyle);
    my $itemButton = Qt::PushButton(this->tr('Qt::InputDialog::getIte&m()'));

    my $textLabel = Qt::Label();
    this->{textLabel} = $textLabel;
    $textLabel->setFrameStyle($frameStyle);
    my $textButton = Qt::PushButton(this->tr('Qt::InputDialog::get&Text()'));

    my $colorLabel = Qt::Label();
    this->{colorLabel} = $colorLabel;
    $colorLabel->setFrameStyle($frameStyle);
    my $colorButton = Qt::PushButton(this->tr('Qt::ColorDialog::get&Color()'));

    my $fontLabel = Qt::Label();
    this->{fontLabel} = $fontLabel;
    $fontLabel->setFrameStyle($frameStyle);
    my $fontButton = Qt::PushButton(this->tr('Qt::FontDialog::get&Font()'));

    my $directoryLabel = Qt::Label();
    this->{directoryLabel} = $directoryLabel;
    $directoryLabel->setFrameStyle($frameStyle);
    my $directoryButton =
            Qt::PushButton(this->tr('Qt::FileDialog::getE&xistingDirectory()'));

    my $openFileNameLabel = Qt::Label();
    this->{openFileNameLabel} = $openFileNameLabel;
    $openFileNameLabel->setFrameStyle($frameStyle);
    my $openFileNameButton =
            Qt::PushButton(this->tr('Qt::FileDialog::get&OpenFileName()'));

    my $openFileNamesLabel = Qt::Label();
    this->{openFileNamesLabel} = $openFileNamesLabel;
    $openFileNamesLabel->setFrameStyle($frameStyle);
    my $openFileNamesButton =
            Qt::PushButton(this->tr('Qt::FileDialog::&getOpenFileNames()'));

    my $saveFileNameLabel = Qt::Label();
    this->{saveFileNameLabel} = $saveFileNameLabel;
    $saveFileNameLabel->setFrameStyle($frameStyle);
    my $saveFileNameButton =
            Qt::PushButton(this->tr('Qt::FileDialog::get&SaveFileName()'));

    my $criticalLabel = Qt::Label();
    this->{criticalLabel} = $criticalLabel;
    $criticalLabel->setFrameStyle($frameStyle);
    my $criticalButton =
            Qt::PushButton(this->tr('Qt::MessageBox::critica&l()'));

    my $informationLabel = Qt::Label();
    this->{informationLabel} = $informationLabel;
    $informationLabel->setFrameStyle($frameStyle);
    my $informationButton =
            Qt::PushButton(this->tr('Qt::MessageBox::i&nformation()'));

    my $questionLabel = Qt::Label();
    this->{questionLabel} = $questionLabel;
    $questionLabel->setFrameStyle($frameStyle);
    my $questionButton =
            Qt::PushButton(this->tr('Qt::MessageBox::&question()'));

    my $warningLabel = Qt::Label();
    this->{warningLabel} = $warningLabel;
    $warningLabel->setFrameStyle($frameStyle);
    my $warningButton = Qt::PushButton(this->tr('Qt::MessageBox::&warning()'));

    my $errorLabel = Qt::Label();
    this->{errorLabel} = $errorLabel;
    $errorLabel->setFrameStyle($frameStyle);
    my $errorButton =
            Qt::PushButton(this->tr('Qt::ErrorMessage::show&M&essage()'));

    this->connect($integerButton, SIGNAL 'clicked()', this, SLOT 'setInteger()');
    this->connect($doubleButton, SIGNAL 'clicked()', this, SLOT 'setDouble()');
    this->connect($itemButton, SIGNAL 'clicked()', this, SLOT 'setItem()');
    this->connect($textButton, SIGNAL 'clicked()', this, SLOT 'setText()');
    this->connect($colorButton, SIGNAL 'clicked()', this, SLOT 'setColor()');
    this->connect($fontButton, SIGNAL 'clicked()', this, SLOT 'setFont()');
    this->connect($directoryButton, SIGNAL 'clicked()',
            this, SLOT 'setExistingDirectory()');
    this->connect($openFileNameButton, SIGNAL 'clicked()',
            this, SLOT 'setOpenFileName()');
    this->connect($openFileNamesButton, SIGNAL 'clicked()',
            this, SLOT 'setOpenFileNames()');
    this->connect($saveFileNameButton, SIGNAL 'clicked()',
            this, SLOT 'setSaveFileName()');
    this->connect($criticalButton, SIGNAL 'clicked()', this, SLOT 'criticalMessage()');
    this->connect($informationButton, SIGNAL 'clicked()',
            this, SLOT 'informationMessage()');
    this->connect($questionButton, SIGNAL 'clicked()', this, SLOT 'questionMessage()');
    this->connect($warningButton, SIGNAL 'clicked()', this, SLOT 'warningMessage()');
    this->connect($errorButton, SIGNAL 'clicked()', this, SLOT 'errorMessage()');

    my $native = Qt::CheckBox(this);
    this->{native} = $native;
    $native->setText('Use native file dialog.');
    $native->setChecked(1);
#ifndef Q_WS_WIN
#ifndef Q_OS_MAC
    $native->hide();
#endif
#endif
    my $layout = Qt::GridLayout();
    $layout->setColumnStretch(1, 1);
    $layout->setColumnMinimumWidth(1, 250);
    $layout->addWidget($integerButton, 0, 0);
    $layout->addWidget($integerLabel, 0, 1);
    $layout->addWidget($doubleButton, 1, 0);
    $layout->addWidget($doubleLabel, 1, 1);
    $layout->addWidget($itemButton, 2, 0);
    $layout->addWidget($itemLabel, 2, 1);
    $layout->addWidget($textButton, 3, 0);
    $layout->addWidget($textLabel, 3, 1);
    $layout->addWidget($colorButton, 4, 0);
    $layout->addWidget($colorLabel, 4, 1);
    $layout->addWidget($fontButton, 5, 0);
    $layout->addWidget($fontLabel, 5, 1);
    $layout->addWidget($directoryButton, 6, 0);
    $layout->addWidget($directoryLabel, 6, 1);
    $layout->addWidget($openFileNameButton, 7, 0);
    $layout->addWidget($openFileNameLabel, 7, 1);
    $layout->addWidget($openFileNamesButton, 8, 0);
    $layout->addWidget($openFileNamesLabel, 8, 1);
    $layout->addWidget($saveFileNameButton, 9, 0);
    $layout->addWidget($saveFileNameLabel, 9, 1);
    $layout->addWidget($criticalButton, 10, 0);
    $layout->addWidget($criticalLabel, 10, 1);
    $layout->addWidget($informationButton, 11, 0);
    $layout->addWidget($informationLabel, 11, 1);
    $layout->addWidget($questionButton, 12, 0);
    $layout->addWidget($questionLabel, 12, 1);
    $layout->addWidget($warningButton, 13, 0);
    $layout->addWidget($warningLabel, 13, 1);
    $layout->addWidget($errorButton, 14, 0);
    $layout->addWidget($errorLabel, 14, 1);
    $layout->addWidget($native, 15, 0);
    this->setLayout($layout);

    this->setWindowTitle(this->tr('Standard Dialogs'));
}

sub setInteger {
#! [0]
    my $ok;
    my $i = Qt::InputDialog::getInteger(this, this->tr('Qt::InputDialog::getInteger()'),
                                     this->tr('Percentage:'), 25, 0, 100, 1, $ok);
    if ($ok) {
        my $integerLabel = this->{integerLabel};
        $integerLabel->setText(this->tr($i));
    }
#! [0]
}

sub setDouble {
#! [1]
    my $ok;
    my $d = Qt::InputDialog::getDouble(this, this->tr('Qt::InputDialog::getDouble()'),
                                       this->tr('Amount:'), 37.56, -10000, 10000, 2, $ok);
    if ($ok) {
        my $doubleLabel = this->{doubleLabel};
        $doubleLabel->setText(this->tr($d));
    }
#! [1]
}

sub setItem {
#! [2]
    my @items = ( this->tr('Spring'), this->tr('Summer'), this->tr('Fall'), this->tr('Winter') );

    my $ok;
    my $item = Qt::InputDialog::getItem(this, this->tr('Qt::InputDialog::getItem()'),
                                         this->tr('Season:'), \@items, 0, 0, $ok);
    if ($ok && $item) {
        my $itemLabel = this->{itemLabel};
        $itemLabel->setText($item);
    }
#! [2]
}

sub setText {
#! [3]
    my $ok;
    my $text = Qt::InputDialog::getText(this, this->tr('Qt::InputDialog::getText()'),
                                         this->tr('User name:'), Qt::LineEdit::Normal(),
                                         Qt::Dir::home()->dirName(), $ok);
    if ($ok && $text) {
        my $textLabel = this->{textLabel};
        $textLabel->setText($text);
    }
#! [3]
}

sub setColor {
    my $color = Qt::ColorDialog::getColor(Qt::Color(Qt::green()), this);
    if ($color->isValid()) {
        my $colorLabel = this->{colorLabel};
        $colorLabel->setText($color->name());
        $colorLabel->setPalette(Qt::Palette($color));
        $colorLabel->setAutoFillBackground(1);
    }
}

sub setFont {
    my $ok;
    my $fontLabel = this->{fontLabel};
    my $font = Qt::FontDialog::getFont($ok, Qt::Font(Qt::String($fontLabel->text())), this);
    if ($ok) {
        $fontLabel->setText($font->key());
        $fontLabel->setFont($font);
    }
}

sub setExistingDirectory {
    my $options = Qt::FileDialog::DontResolveSymlinks() | Qt::FileDialog::ShowDirsOnly();
    my $native = this->{native};
    if (!$native->isChecked()) {
        $options |= Qt::FileDialog::DontUseNativeDialog();
    }
    my $directoryLabel = this->{directoryLabel};
    my $directory = Qt::FileDialog::getExistingDirectory(this,
                                this->tr('Qt::FileDialog::getExistingDirectory()'),
                                $directoryLabel->text(),
                                $options);
    if ($directory) {
        $directoryLabel->setText($directory);
    }
}

sub setOpenFileName {
    my $options;
    my $native = this->{native};
    if (!$native->isChecked()) {
        $options |= Qt::FileDialog::DontUseNativeDialog();
    }
    my $selectedFilter;
    my $openFileNameLabel = this->{openFileNameLabel};
    my $fileName = Qt::FileDialog::getOpenFileName(this,
                                this->tr('Qt::FileDialog::getOpenFileName()'),
                                $openFileNameLabel->text(),
                                this->tr('All Files (*);;Text Files (*.txt)'),
                                $selectedFilter,
                                $options);
    if ($fileName) {
        $openFileNameLabel->setText($fileName);
    }
}

sub setOpenFileNames {
    my $options;
    my $native = this->{native};
    if (!$native->isChecked()) {
        $options |= Qt::FileDialog::DontUseNativeDialog();
    }
    my $selectedFilter;
    my $openFilesPath = this->{openFilesPath};
    my $files = Qt::FileDialog::getOpenFileNames(
                                this, this->tr('Qt::FileDialog::getOpenFileNames()'),
                                $openFilesPath,
                                this->tr('All Files (*);;Text Files (*.txt)'),
                                $selectedFilter,
                                $options);
    if ( ref $files eq 'ARRAY' && scalar @{$files}) {
        my $openFilesPath = $files->[0];
        this->{openFilesPath} = $openFilesPath;
        my $openFileNamesLabel = this->{openFileNamesLabel};
        $openFileNamesLabel->setText( '[' . join(', ', @{$files}) . ']' );
    }
}

sub setSaveFileName {
    my $options;
    my $native = this->{native};
    if (!$native->isChecked()) {
        $options |= Qt::FileDialog::DontUseNativeDialog();
    }
    my $selectedFilter;
    my $saveFileNameLabel = this->{saveFileNameLabel};
    my $fileName = Qt::FileDialog::getSaveFileName(this,
                                this->tr('Qt::FileDialog::getSaveFileName()'),
                                $saveFileNameLabel->text(),
                                this->tr('All Files (*);;Text Files (*.txt)'),
                                $selectedFilter,
                                $options);
    if ($fileName) {
        my $saveFileNameLabel = this->{saveFileNameLabel};
        $saveFileNameLabel->setText($fileName);
    }
}

sub criticalMessage {
    my $reply = Qt::MessageBox::critical(this, this->tr('Qt::MessageBox::critical()'),
                                    $MESSAGE,
                                    Qt::MessageBox::Abort() | Qt::MessageBox::Retry() | Qt::MessageBox::Ignore());
    my $criticalLabel = this->{criticalLabel};
    if ($reply == Qt::MessageBox::Abort()) {
        $criticalLabel->setText(this->tr('Abort'));
    }
    elsif ($reply == Qt::MessageBox::Retry()) {
        $criticalLabel->setText(this->tr('Retry'));
    }
    else {
        $criticalLabel->setText(this->tr('Ignore'));
    }
}

sub informationMessage {
    my $reply = Qt::MessageBox::information(this, this->tr('Qt::MessageBox::information()'), $MESSAGE);
    my $informationLabel = this->{informationLabel};
    if ($reply == Qt::MessageBox::Ok()) {
        $informationLabel->setText(this->tr('OK'));
    }
    else {
        $informationLabel->setText(this->tr('Escape'));
    }
}

sub questionMessage {
    my $reply = Qt::MessageBox::question(this, this->tr('Qt::MessageBox::question()'),
                                    $MESSAGE,
                                    Qt::MessageBox::Yes() | Qt::MessageBox::No() | Qt::MessageBox::Cancel());
    my $questionLabel = this->{questionLabel};
    if ($reply == Qt::MessageBox::Yes()) {
        $questionLabel->setText(this->tr('Yes'));
    }
    elsif ($reply == Qt::MessageBox::No()) {
        $questionLabel->setText(this->tr('No'));
    }
    else {
        $questionLabel->setText(this->tr('Cancel'));
    }
}

sub warningMessage {
    my $msgBox = Qt::MessageBox(Qt::MessageBox::Warning(), this->tr('Qt::MessageBox::warning()'),
                       $MESSAGE, 0, this);
    $msgBox->addButton(this->tr('Save &Again'), Qt::MessageBox::AcceptRole());
    $msgBox->addButton(this->tr('&Continue'), Qt::MessageBox::RejectRole());
    my $warningLabel = this->{warningLabel};
    if ($msgBox->exec() == Qt::MessageBox::AcceptRole()) {
        $warningLabel->setText(this->tr('Save Again'));
    }
    else {
        $warningLabel->setText(this->tr('Continue'));
    }
}

sub errorMessage {
    my $errorMessageDialog = this->{errorMessageDialog};
    $errorMessageDialog->showMessage(
            this->tr('This dialog shows and remembers error messages. ' .
               'If the checkbox is checked (as it is by default), ' .
               'the shown message will be shown again, ' .
               'but if the user unchecks the box the message ' .
               'will not appear again if Qt::ErrorMessage::showMessage() ' .
               'is called with the same message.'));
    my $errorLabel = this->{errorLabel};
    $errorLabel->setText(this->tr('If the box is unchecked, the message ' .
                           'won\'t appear again.'));
}

1;
