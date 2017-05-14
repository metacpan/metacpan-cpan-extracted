package MainWindow;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::MainWindow );
use QtCore4::slots
    open => [],
    save => [],
    about => [],
    aboutToShowSaveAsMenu => [];
use PreviewForm;

sub textEdit() {
    return this->{textEdit};
}

sub previewForm() {
    return this->{previewForm};
}

sub codecs() {
    return this->{codecs};
}

sub fileMenu() {
    return this->{fileMenu};
}

sub helpMenu() {
    return this->{helpMenu};
}

sub saveAsMenu() {
    return this->{saveAsMenu};
}

sub openAct() {
    return this->{openAct};
}

sub saveAsActs() {
    return this->{saveAsActs};
}

sub exitAct() {
    return this->{exitAct};
}

sub aboutAct() {
    return this->{aboutAct};
}

sub aboutQtAct() {
    return this->{aboutQtAct};
}

sub NEW
{
    my ($class) = @_;
    $class->SUPER::NEW();
    this->{saveAsActs} = [];
    this->{textEdit} = Qt::TextEdit();
    textEdit->setLineWrapMode(Qt::TextEdit::NoWrap());
    setCentralWidget(textEdit);

    findCodecs();

    this->{previewForm} = PreviewForm(this);
    previewForm->setCodecList(codecs);

    createActions();
    createMenus();

    setWindowTitle(this->tr('Codecs'));
    resize(500, 400);
}

sub open
{
    my $fileName = Qt::FileDialog::getOpenFileName(this);
    if ($fileName) {
        my $file = Qt::File($fileName);
        if (!$file->open(Qt::File::ReadOnly())) {
            Qt::MessageBox::warning(this, this->tr('Codecs'),
                         sprintf this->tr("Cannot read file %s:\n%s"),
                                 $fileName,
                                 $file.errorString());
            return;
        }

        my $data = $file->readAll();

        previewForm->setEncodedData($data);
        if (previewForm->exec()) {
            textEdit->setPlainText(previewForm->decodedString());
        }
    }
}

sub save
{
    my $fileName = Qt::FileDialog::getSaveFileName(this);
    if ($fileName) {
        my $file = Qt::File($fileName);
        if (!$file->open(Qt::File::WriteOnly() | Qt::File::Text())) {
            Qt::MessageBox::warning(this, this->tr('Codecs'),
                         sprintf this->tr("Cannot write file %s:\n%s"),
                                 $fileName,
                                 $file.errorString());
            return;
        }

        my $action = sender();
        my $codecName = $action->data()->toByteArray();

        my $out = Qt::TextStream($file);
        $out->setCodec($codecName->constData());
        no warnings qw(void);
        $out << textEdit->toPlainText();
        $file->close();
    }
}

sub about
{
    Qt::MessageBox::about(this, this->tr('About Codecs'),
            this->tr('The <b>Codecs</b> example demonstrates how to read and write ' .
               'files using various encodings.'));
}

sub aboutToShowSaveAsMenu
{
    my $currentText = textEdit->toPlainText();

    foreach my $action ( @{saveAsActs()} ) {
        my $codecName = $action->data()->toByteArray();
        my $codec = Qt::TextCodec::codecForName($codecName);
        $action->setVisible($codec && $codec->canEncode($currentText));
    }
}

sub findCodecs
{
    my %codecMap;
    my $iso8859RegExp = Qt::RegExp('ISO[- ]8859-([0-9]+).*');

    foreach my $mib ( @{Qt::TextCodec::availableMibs()} ) {
        my $codec = Qt::TextCodec::codecForMib($mib);

        my $sortKey = $codec->name()->toUpper();
        my $rank;

        if ($sortKey->startsWith('UTF-8')) {
            $rank = 1;
        } elsif ($sortKey->startsWith('UTF-16')) {
            $rank = 2;
        } elsif ($iso8859RegExp->exactMatch($sortKey->constData())) {
            if (length $iso8859RegExp->cap(1) == 1) {
                $rank = 3;
            }
            else {
                $rank = 4;
            }
        } else {
            $rank = 5;
        }
        $sortKey->prepend(Qt::CString($rank));

        $codecMap{$sortKey->constData} = $codec;
    }
    this->{codecs} = [map{ $codecMap{$_} } sort keys %codecMap];
}

sub createActions
{
    this->{openAct} = Qt::Action(this->tr('&Open...'), this);
    openAct->setShortcut(Qt::KeySequence(Qt::KeySequence::Open()));
    this->connect(openAct, SIGNAL 'triggered()', this, SLOT 'open()');

    foreach my $codec ( @{codecs() } ) {
        my $text = sprintf this->tr('%s...'), $codec->name()->constData();

        my $action = Qt::Action($text, this);
        $action->setData(Qt::Variant($codec->name()));
        this->connect($action, SIGNAL 'triggered()', this, SLOT 'save()');
        push @{this->{saveAsActs}}, $action;
    }

    this->{exitAct} = Qt::Action(this->tr('E&xit'), this);
    exitAct->setShortcut(Qt::KeySequence(Qt::KeySequence::Quit()));
    this->connect(exitAct, SIGNAL 'triggered()', this, SLOT 'close()');

    this->{aboutAct} = Qt::Action(this->tr('&About'), this);
    this->connect(aboutAct, SIGNAL 'triggered()', this, SLOT 'about()');

    this->{aboutQtAct} = Qt::Action(this->tr('About &Qt'), this);
    this->connect(aboutQtAct, SIGNAL 'triggered()', qApp, SLOT 'aboutQt()');
}

sub createMenus
{
    this->{saveAsMenu} = Qt::Menu(this->tr('&Save As'), this);
    foreach my $action ( @{saveAsActs()} ) {
        saveAsMenu->addAction($action);
    }
    this->connect(saveAsMenu, SIGNAL 'aboutToShow()',
            this, SLOT 'aboutToShowSaveAsMenu()');

    this->{fileMenu} = Qt::Menu(this->tr('&File'), this);
    fileMenu->addAction(openAct);
    fileMenu->addMenu(saveAsMenu);
    fileMenu->addSeparator();
    fileMenu->addAction(exitAct);

    this->{helpMenu} = Qt::Menu(this->tr('&Help'), this);
    helpMenu->addAction(aboutAct);
    helpMenu->addAction(aboutQtAct);

    menuBar()->addMenu(fileMenu);
    menuBar()->addSeparator();
    menuBar()->addMenu(helpMenu);
}

1;
