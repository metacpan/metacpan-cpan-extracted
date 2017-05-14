package Dialog;

use Qt;
use Qt::QString;
use Qt::QStringList;
use Qt::QCheckBox;
use Qt::QLabel;
use Qt::QPushButton;
use Qt::QLineEdit;
use Qt::QGridLayout;
use Qt::QDir;
use Qt::QColor;
use Qt::QPalette;
use Qt::QFont;
use Qt::QMessageBox;
use Qt::QErrorMessage;
use Qt::QDialog;
use Qt::QInputDialog;
use Qt::QColorDialog;
use Qt::QFontDialog;
use Qt::QFileDialog;


our @ISA=qw(Qt::QDialog);

our @EXPORT=qw(Dialog);

my $MESSAGE = TR('<p>Message boxes have a caption, a text, '.
               'and any number of buttons, each with standard or custom texts.'.
               '<p>Click a button to close the message box. Pressing the Esc button '.
               'will activate the detected escape button (if any).');

sub Dialog {
    my $class = 'Dialog';
    my @signals = ();
    my @slots = ('setInteger()', 'setDouble()', 'setItem()', 'setText()', 'setColor()', 'setFont()', 'setExistingDirectory()',
	'setOpenFileName()', 'setOpenFileNames()', 'setSaveFileName()', 'criticalMessage()', 'informationMessage()',
	'questionMessage()', 'warningMessage()', 'errorMessage()');
    my $this = QDialog(\@signals, \@slots);
    bless $this, $class;

    $this->{errorMessageDialog} = QErrorMessage($this);

    my $frameStyle = Qt::QFrame::Sunken | Qt::QFrame::Panel;

    $this->{integerLabel} = QLabel();
    $this->{integerLabel}->setFrameStyle($frameStyle);
    $this->{integerButton} = QPushButton(TR("QInputDialog::get&Integer()"));

    $this->{doubleLabel} = QLabel();
    $this->{doubleLabel}->setFrameStyle($frameStyle);
    $this->{doubleButton} = QPushButton(TR("QInputDialog::get&Double()"));

    $this->{itemLabel} = QLabel();
    $this->{itemLabel}->setFrameStyle($frameStyle);
    $this->{itemButton} = QPushButton(TR("QInputDialog::getIte&m()"));

    $this->{textLabel} = QLabel();
    $this->{textLabel}->setFrameStyle($frameStyle);
    $this->{textButton} = QPushButton(TR("QInputDialog::get&Text()"));

    $this->{colorLabel} = QLabel();
    $this->{colorLabel}->setFrameStyle($frameStyle);
    $this->{colorButton} = QPushButton(TR("QColorDialog::get&Color()"));

    $this->{fontLabel} = QLabel();
    $this->{fontLabel}->setFrameStyle($frameStyle);
    $this->{fontButton} = QPushButton(TR("QFontDialog::get&Font()"));

    $this->{directoryLabel} = QLabel();
    $this->{directoryLabel}->setFrameStyle($frameStyle);
    $this->{directoryButton} = QPushButton(TR("QFileDialog::getE&xistingDirectory()"));

    $this->{openFileNameLabel} = QLabel();
    $this->{openFileNameLabel}->setFrameStyle($frameStyle);
    $this->{openFileNameButton} = QPushButton(TR("QFileDialog::get&OpenFileName()"));

    $this->{openFileNamesLabel} = QLabel();
    $this->{openFileNamesLabel}->setFrameStyle($frameStyle);
    $this->{openFileNamesButton} = QPushButton(TR("QFileDialog::&getOpenFileNames()"));

    $this->{saveFileNameLabel} = QLabel;
    $this->{saveFileNameLabel}->setFrameStyle($frameStyle);
    $this->{saveFileNameButton} = QPushButton(TR("QFileDialog::get&SaveFileName()"));

    $this->{criticalLabel} = QLabel();
    $this->{criticalLabel}->setFrameStyle($frameStyle);
    $this->{criticalButton} = QPushButton(TR("QMessageBox::critica&l()"));

    $this->{informationLabel} = QLabel();
    $this->{informationLabel}->setFrameStyle($frameStyle);
    $this->{informationButton} = QPushButton(TR("QMessageBox::i&nformation()"));

    $this->{questionLabel} = QLabel();
    $this->{questionLabel}->setFrameStyle($frameStyle);
    $this->{questionButton} = QPushButton(TR("QMessageBox::&question()"));

    $this->{warningLabel} = QLabel();
    $this->{warningLabel}->setFrameStyle($frameStyle);
    $this->{warningButton} = QPushButton(TR("QMessageBox::&warning()"));

    $this->{errorLabel} = QLabel();
    $this->{errorLabel}->setFrameStyle($frameStyle);
    $this->{errorButton} = QPushButton(TR("QErrorMessage::show&M&essage()"));

    $this->connect($this->{integerButton}, SIGNAL('clicked()'), $this, SLOT('setInteger()'));
    $this->connect($this->{doubleButton}, SIGNAL('clicked()'), $this, SLOT('setDouble()'));
    $this->connect($this->{itemButton}, SIGNAL('clicked()'), $this, SLOT('setItem()'));
    $this->connect($this->{textButton}, SIGNAL('clicked()'), $this, SLOT('setText()'));
    $this->connect($this->{colorButton}, SIGNAL('clicked()'), $this, SLOT('setColor()'));
    $this->connect($this->{fontButton}, SIGNAL('clicked()'), $this, SLOT('setFont()'));
    CONNECT($this->{directoryButton}, SIGNAL('clicked()'),
            $this, SLOT('setExistingDirectory()'));
    CONNECT($this->{openFileNameButton}, SIGNAL('clicked()'),
            $this, SLOT('setOpenFileName()'));
    CONNECT($this->{openFileNamesButton}, SIGNAL('clicked()'),
            $this, SLOT('setOpenFileNames()'));
    $this->connect($this->{saveFileNameButton}, SIGNAL('clicked()'),
            $this, SLOT('setSaveFileName()'));
    $this->connect($this->{criticalButton}, SIGNAL('clicked()'), $this, SLOT('criticalMessage()'));
    $this->connect($this->{informationButton}, SIGNAL('clicked()'),
            $this, SLOT('informationMessage()'));
    $this->connect($this->{questionButton}, SIGNAL('clicked()'), $this, SLOT('questionMessage()'));
    $this->connect($this->{warningButton}, SIGNAL('clicked()'), $this, SLOT('warningMessage()'));
    $this->connect($this->{errorButton}, SIGNAL('clicked()'), $this, SLOT('errorMessage()'));

    $this->{native} = QCheckBox($this);
    $this->{native}->setText(QString("Use native file dialog."));
    $this->{native}->setChecked(1); # true
#ifndef Q_WS_WIN
#ifndef Q_OS_MAC
    $this->{native}->hide();
#endif
#endif
    $this->{layout} = QGridLayout();
    $this->{layout}->setColumnStretch(1, 1);
    $this->{layout}->setColumnMinimumWidth(1, 250);
    $this->{layout}->addWidget($this->{integerButton}, 0, 0);
    $this->{layout}->addWidget($this->{integerLabel}, 0, 1);
    $this->{layout}->addWidget($this->{doubleButton}, 1, 0);
    $this->{layout}->addWidget($this->{doubleLabel}, 1, 1);
    $this->{layout}->addWidget($this->{itemButton}, 2, 0);
    $this->{layout}->addWidget($this->{itemLabel}, 2, 1);
    $this->{layout}->addWidget($this->{textButton}, 3, 0);
    $this->{layout}->addWidget($this->{textLabel}, 3, 1);
    $this->{layout}->addWidget($this->{colorButton}, 4, 0);
    $this->{layout}->addWidget($this->{colorLabel}, 4, 1);
    $this->{layout}->addWidget($this->{fontButton}, 5, 0);
    $this->{layout}->addWidget($this->{fontLabel}, 5, 1);
    $this->{layout}->addWidget($this->{directoryButton}, 6, 0);
    $this->{layout}->addWidget($this->{directoryLabel}, 6, 1);
    $this->{layout}->addWidget($this->{openFileNameButton}, 7, 0);
    $this->{layout}->addWidget($this->{openFileNameLabel}, 7, 1);
    $this->{layout}->addWidget($this->{openFileNamesButton}, 8, 0);
    $this->{layout}->addWidget($this->{openFileNamesLabel}, 8, 1);
    $this->{layout}->addWidget($this->{saveFileNameButton}, 9, 0);
    $this->{layout}->addWidget($this->{saveFileNameLabel}, 9, 1);
    $this->{layout}->addWidget($this->{criticalButton}, 10, 0);
    $this->{layout}->addWidget($this->{criticalLabel}, 10, 1);
    $this->{layout}->addWidget($this->{informationButton}, 11, 0);
    $this->{layout}->addWidget($this->{informationLabel}, 11, 1);
    $this->{layout}->addWidget($this->{questionButton}, 12, 0);
    $this->{layout}->addWidget($this->{questionLabel}, 12, 1);
    $this->{layout}->addWidget($this->{warningButton}, 13, 0);
    $this->{layout}->addWidget($this->{warningLabel}, 13, 1);
    $this->{layout}->addWidget($this->{errorButton}, 14, 0);
    $this->{layout}->addWidget($this->{errorLabel}, 14, 1);
    $this->{layout}->addWidget($this->{native}, 15, 0);
    $this->setLayout($this->{layout});

    $this->setWindowTitle(TR("Standard Dialogs"));
    
    return $this;
}

sub setInteger {
    my $this = shift;
    my $ok = 0; # need for idendification this variable as bool
    my $i = Qt::QInputDialog::getInteger($this, TR('QInputDialog::getInteger()'), TR('Percentage:'), 25, 0, 100, 1, $ok);
    $this->{integerLabel}->setText(TR("%1%")->arg($i)) if $ok;
}

sub setDouble {
    my $this = shift;
    my $ok = 0;
    my $d = Qt::QInputDialog::getDouble($this, TR("QInputDialog::getDouble()"), TR("Amount:"), 37.56, -10000.0, 10000.0, 2, $ok);
    $this->{doubleLabel}->setText(QString("$%1")->arg($d)) if $ok;
}

sub setItem {
    my $this = shift;
    my $items = QStringList();
    $items << TR("Spring") << TR("Summer") << TR("Fall") << TR("Winter");
    my $ok = 0;
    my $item = Qt::QInputDialog::getItem($this, TR("QInputDialog::getItem()"), TR("Season:"), $items, 0, 0, $ok);
    if ( $ok and not $item->isEmpty()) {
        $this->{itemLabel}->setText($item);
    }
}

sub setText {
    my $this = shift;
    my $ok = 0;
    my $text = Qt::QInputDialog::getText($this, TR("QInputDialog::getText()"), TR("User name:"), Qt::QLineEdit::Normal, Qt::QDir::home()->dirName(), $ok);
    if ($ok and not $text->isEmpty()) {
        $this->{textLabel}->setText($text);
    }
}

sub setColor {
    my $this = shift;
    $color = Qt::QColorDialog::getColor(QColor(Qt::green), $this);
    if ( $color->isValid() ) {
        $this->{colorLabel}->setText($color->name());
        $this->{colorLabel}->setPalette(QPalette($color));
        $this->{colorLabel}->setAutoFillBackground(1); # true
    }
}

sub setFont {
    my $this = shift;
    my $ok = 0;
    my $font = Qt::QFontDialog::getFont($ok, QFont($this->{fontLabel}->text()), $this);
    if ( $ok ) {
        $this->{fontLabel}->setText($font->key());
        $this->{fontLabel}->setFont($font);
    }
}

sub setExistingDirectory {
    my $this = shift;
    my $options = Qt::QFileDialog::DontResolveSymlinks | Qt::QFileDialog::ShowDirsOnly;
    unless ($this->{native}->isChecked()) {
        $options |= Qt::QFileDialog::DontUseNativeDialog;
    }
    my $directory = Qt::QFileDialog::getExistingDirectory($this, TR("QFileDialog::getExistingDirectory()"), $this->{directoryLabel}->text(), $options);
    unless ($directory->isEmpty()) {
        $this->{directoryLabel}->setText($directory);
    }
}

sub setOpenFileName {
    my $this = shift;
    my $options = 0;
    unless ($this->{native}->isChecked()) {
        $options |= Qt::QFileDialog::DontUseNativeDialog;
    }
    my $selectedFilter = QString();
    my $fileName = Qt::QFileDialog::getOpenFileName($this, TR("QFileDialog::getOpenFileName()"), $this->{openFileNameLabel}->text(),
        TR("All Files (*);;Text Files (*.txt)"), $selectedFilter, $options);
    unless ($fileName->isEmpty()) {
        $this->{openFileNameLabel}->setText($fileName);
    }
}

sub setOpenFileNames {
    my $this = shift;
    my $options = 0;
    if (!$this->{native}->isChecked()) {
        $options |= Qt::QFileDialog::DontUseNativeDialog;
    }
    my $selectedFilter = QString();
    my $files = Qt::QFileDialog::getOpenFileNames( $this, TR("QFileDialog::getOpenFileNames()"), QString("./"),
        TR("All Files (*);;Text Files (*.txt)"), $selectedFilter, $options);
    # count inherites from QList<>
#    if ( $files->count() ) { 
#        $this->{openFilesPath} = $files[0];
#        $this->{openFileNamesLabel}->setText(QString("[%1]")->arg($files->join(", ")));
#    }
    $this->{openFileNamesLabel}->setText($files->join(QString", "));
}

sub setSaveFileName {
    my $this = shift;
    my $options = 0;
    unless ($this->{native}->isChecked()) {
        $options |= Qt::QFileDialog::DontUseNativeDialog;
    }
    my $selectedFilter = QString();
    $fileName = Qt::QFileDialog::getSaveFileName($this, TR("QFileDialog::getSaveFileName()"), $this->{saveFileNameLabel}->text(),
        TR("All Files (*);;Text Files (*.txt)"), $selectedFilter, $options);
    unless ($fileName->isEmpty()) {
        $this->{saveFileNameLabel}->setText($fileName);
    }
}

sub criticalMessage {
    my $this = shift;
    my $reply = Qt::QMessageBox::critical($this, TR("QMessageBox::critical()"), $MESSAGE,
    		Qt::QMessageBox::Abort | Qt::QMessageBox::Retry | Qt::QMessageBox::Ignore);
    if ($reply == Qt::QMessageBox::Abort) {
        $this->{criticalLabel}->setText(TR("Abort"));
    }
    elsif ($reply == Qt::QMessageBox::Retry) {
        $this->{criticalLabel}->setText(TR("Retry"));
    }
    else {
        $this->{criticalLabel}->setText(TR("Ignore"));
    }
}

sub informationMessage {
    my $this = shift;
    my $reply = Qt::QMessageBox::information($this, TR("QMessageBox::information()"), $MESSAGE);
    if ($reply == Qt::QMessageBox::Ok) {
        $this->{informationLabel}->setText(TR("OK"));
    }
    else {
        $this->{informationLabel}->setText(TR("Escape"));
    }
}

sub questionMessage {
    my $this = shift;
    my $reply = Qt::QMessageBox::question($this, TR("QMessageBox::question()"), $MESSAGE,
                Qt::QMessageBox::Yes | Qt::QMessageBox::No | Qt::QMessageBox::Cancel);
    if ($reply == Qt::QMessageBox::Yes) {
        $this->{questionLabel}->setText(TR("Yes"));
    }
    elsif ($reply == Qt::QMessageBox::No) {
        $this->{questionLabel}->setText(TR("No"));
    }
    else {
        $this->{questionLabel}->setText(TR("Cancel"));
    }
}

sub warningMessage {
    my $this = shift;
    my $msgBox = QMessageBox(Qt::QMessageBox::Warning, TR("QMessageBox::warning()"), $MESSAGE, 0, $this);
    $msgBox->addButton(TR("Save &Again"), Qt::QMessageBox::AcceptRole);
    $msgBox->addButton(TR("&Continue"), Qt::QMessageBox::RejectRole);
    if ($msgBox->exec() == Qt::QMessageBox::AcceptRole) {
        $this->{warningLabel}->setText(TR("Save Again"));
    }
    else {
        $this->{warningLabel}->setText(TR("Continue"));
    }
}

sub errorMessage {
    $this = shift;
    $this->{errorMessageDialog}->showMessage(
            TR("This dialog shows and remembers error messages. ".
               "If the checkbox is checked (as it is by default), ".
               "the shown message will be shown again, ".
               "but if the user unchecks the box the message ".
               "will not appear again if QErrorMessage::showMessage() ".
               "is called with the same message."));
    $this->{errorLabel}->setText(TR("If the box is unchecked, the message won't appear again."));
}

1;
