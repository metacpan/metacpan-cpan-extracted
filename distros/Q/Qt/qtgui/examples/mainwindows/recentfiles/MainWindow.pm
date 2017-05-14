package MainWindow;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use List::Util qw(min);

use QtCore4::isa qw( Qt::MainWindow );
use QtCore4::slots
    newFile => [],
    open => [],
    save => [],
    saveAs => [],
    openRecentFile => [],
    about => [];

sub curFile() {
    return this->{curFile};
}

sub textEdit() {
    return this->{textEdit};
}

sub fileMenu() {
    return this->{fileMenu};
}

sub recentFilesMenu() {
    return this->{recentFilesMenu};
}

sub helpMenu() {
    return this->{helpMenu};
}

sub newAct() {
    return this->{newAct};
}

sub openAct() {
    return this->{openAct};
}

sub saveAct() {
    return this->{saveAct};
}

sub saveAsAct() {
    return this->{saveAsAct};
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

sub separatorAct() {
    return this->{separatorAct};
}

use constant {
    MaxRecentFiles => 5
};

sub recentFileActs {
    return this->{recentFileActs};
}

sub NEW {
    my ( $class ) = @_;
    $class->SUPER::NEW();
    this->setAttribute(Qt::WA_DeleteOnClose());

    this->{recentFileActs} = [];
    this->{textEdit} = Qt::TextEdit();
    this->setCentralWidget(this->textEdit);

    this->createActions();
    this->createMenus();
    this->statusBar();

    this->setWindowTitle(this->tr('Recent Files'));
    this->resize(400, 300);
}

sub newFile()
{
    my $other = MainWindow();
    $other->show();
}

sub open()
{
    my $fileName = Qt::FileDialog::getOpenFileName(this);
    if ($fileName) {
        this->loadFile($fileName);
    }
}

sub save()
{
    if (!this->curFile) {
        this->saveAs();
    }
    else {
        this->saveFile(this->curFile);
    }
}

sub saveAs()
{
    my $fileName = Qt::FileDialog::getSaveFileName(this);
    if (!$fileName) {
        return;
    }

    this->saveFile($fileName);
}

sub openRecentFile()
{
    my $action = this->sender();
    if ($action) {
        this->loadFile($action->data()->toString());
    }
}

sub about()
{
   Qt::MessageBox::about(this, this->tr('About Recent Files'),
            this->tr('The <b>Recent Files</b> example demonstrates how to provide a ' .
               'recently used file menu in a Qt application.'));
}

sub createActions()
{
    my $newAct = this->{newAct} = Qt::Action(this->tr('&New'), this);
    $newAct->setShortcuts(Qt::KeySequence::New());
    $newAct->setStatusTip(this->tr('Create a file'));
    this->connect($newAct, SIGNAL 'triggered()', this, SLOT 'newFile()');

    my $openAct = this->{openAct} = Qt::Action(this->tr('&Open...'), this);
    $openAct->setShortcuts(Qt::KeySequence::Open());
    $openAct->setStatusTip(this->tr('Open an existing file'));
    this->connect($openAct, SIGNAL 'triggered()', this, SLOT 'open()');

    my $saveAct = this->{saveAct} = Qt::Action(this->tr('&Save'), this);
    $saveAct->setShortcuts(Qt::KeySequence::Save());
    $saveAct->setStatusTip(this->tr('Save the document to disk'));
    this->connect($saveAct, SIGNAL 'triggered()', this, SLOT 'save()');

    my $saveAsAct = this->{saveAsAct} = Qt::Action(this->tr('Save &As...'), this);
    $saveAsAct->setShortcut(Qt::KeySequence(this->tr('Ctrl+A')));
    $saveAsAct->setStatusTip(this->tr('Save the document under a name'));
    this->connect($saveAsAct, SIGNAL 'triggered()', this, SLOT 'saveAs()');

    foreach my $i (0..MaxRecentFiles-1) {
        this->recentFileActs->[$i] = Qt::Action(this);
        this->recentFileActs->[$i]->setVisible(0);
        this->connect(this->recentFileActs->[$i], SIGNAL 'triggered()',
                this, SLOT 'openRecentFile()');
    }

    my $exitAct = this->{exitAct} = Qt::Action(this->tr('E&xit'), this);
    $exitAct->setShortcut(Qt::KeySequence(this->tr('Ctrl+Q')));
    $exitAct->setStatusTip(this->tr('Exit the application'));
    this->connect($exitAct, SIGNAL 'triggered()', qApp, SLOT 'closeAllWindows()');

    my $aboutAct = this->{aboutAct} = Qt::Action(this->tr('&About'), this);
    $aboutAct->setStatusTip(this->tr('Show the application\'s About box'));
    this->connect($aboutAct, SIGNAL 'triggered()', this, SLOT 'about()');

    my $aboutQtAct = this->{aboutQtAct} = Qt::Action(this->tr('About &Qt'), this);
    $aboutQtAct->setStatusTip(this->tr('Show the Qt4 library\'s About box'));
    this->connect($aboutQtAct, SIGNAL 'triggered()', qApp, SLOT 'aboutQt()');
}

sub createMenus()
{
    my $fileMenu = this->{fileMenu} = this->menuBar()->addMenu(this->tr('&File'));
    $fileMenu->addAction(this->newAct);
    $fileMenu->addAction(this->openAct);
    $fileMenu->addAction(this->saveAct);
    $fileMenu->addAction(this->saveAsAct);
    my $separatorAct = this->{separatorAct} = $fileMenu->addSeparator();
    foreach my $i (0..MaxRecentFiles-1) {
        $fileMenu->addAction(this->recentFileActs->[$i]);
    }
    $fileMenu->addSeparator();
    $fileMenu->addAction(this->exitAct);
    this->updateRecentFileActions();

    this->menuBar()->addSeparator();

    my $helpMenu = this->{helpMenu} = this->menuBar()->addMenu(this->tr('&Help'));
    $helpMenu->addAction(this->aboutAct);
    $helpMenu->addAction(this->aboutQtAct);
}

sub loadFile
{
    my ($fileName) = @_;
    my $file = Qt::File($fileName);
    if (!$file->open(Qt::File::ReadOnly() | Qt::File::Text())) {
        Qt::MessageBox::warning(this, this->tr('Recent Files'),
                     sprintf this->tr("Cannot read file %s:\n%s."),
                             $fileName,
                             $file->errorString());
        return;
    }

    my $in = Qt::TextStream($file);
    Qt::Application::setOverrideCursor(Qt::Cursor(Qt::WaitCursor()));
    this->textEdit->setPlainText($in->readAll());
    Qt::Application::restoreOverrideCursor();

    this->setCurrentFile($fileName);
    this->statusBar()->showMessage(this->tr('File loaded'), 2000);
}

sub saveFile
{
    my ($fileName) = @_;
    my $file = Qt::File($fileName);
    if (!$file->open(Qt::File::WriteOnly() | Qt::File::Text())) {
        Qt::MessageBox::warning(this, this->tr('Recent Files'),
                     sprintf this->tr("Cannot write file %s:\n%s."),
                             $fileName,
                             $file->errorString());
        return;
    }

    my $out = Qt::TextStream($file);
    Qt::Application::setOverrideCursor(Qt::Cursor(Qt::WaitCursor()));
    no warnings qw(void); # For bitshift warning
    $out << this->textEdit->toPlainText();
    use warnings;
    Qt::Application::restoreOverrideCursor();

    this->setCurrentFile($fileName);
    this->statusBar()->showMessage(this->tr('File saved'), 2000);
}

sub setCurrentFile
{
    my ($fileName) = @_;
    this->{curFile} = $fileName;
    if (!this->curFile) {
        this->setWindowTitle(this->tr('Recent Files'));
    }
    else {
        this->setWindowTitle(sprintf this->tr('%s - %s'), this->strippedName(this->curFile),
                                     this->tr('Recent Files'));
    }

    my $settings = Qt::Settings('Trolltech', 'Recent Files Example');
    my $files = $settings->value('recentFileList')->toStringList();
    $files = [grep{ $_ ne $fileName} @{$files}];
    unshift @{$files}, $fileName;
    while (scalar @{$files} > MaxRecentFiles) {
        pop @{$files};
    }

    $settings->setValue('recentFileList', Qt::Variant($files));

    foreach my $widget (@{Qt::Application::topLevelWidgets()}) {
        my $mainWin = $widget->qobject_cast('Qt::MainWindow');
        if ($mainWin) {
            $mainWin->updateRecentFileActions();
        }
    }
}

sub updateRecentFileActions()
{
    my $settings = Qt::Settings('Trolltech', 'Recent Files Example');
    my $files = $settings->value('recentFileList')->toStringList();

    my $numRecentFiles = min(scalar @{$files}, MaxRecentFiles);

    foreach my $i (0..$numRecentFiles-1) {
        my $text = $i + 1 . ' ' . this->strippedName($files->[$i]);
        this->recentFileActs->[$i]->setText($text);
        this->recentFileActs->[$i]->setData(Qt::Variant(Qt::String($files->[$i])));
        this->recentFileActs->[$i]->setVisible(1);
    }
    foreach my $j ($numRecentFiles..MaxRecentFiles-1) {
        this->recentFileActs->[$j]->setVisible(0);
    }

    this->separatorAct->setVisible($numRecentFiles > 0);
}

sub strippedName
{
    my ($fullFileName) = @_;
    return Qt::FileInfo($fullFileName)->fileName();
}

1;
