package MainWindow;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtXml4;
use QtCore4::isa qw( Qt::MainWindow );
use QtCore4::slots
    open => [],
    saveAs => [],
    about => [];
use XbelGenerator;
use XbelHandler;

sub treeWidget() {
    return this->{treeWidget};
}

sub fileMenu() {
    return this->{fileMenu};
}

sub helpMenu() {
    return this->{helpMenu};
}

sub openAct() {
    return this->{openAct};
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

sub NEW
{
    my ($class) = @_;
    $class->SUPER::NEW();

    my @labels = (this->tr('Title'), this->tr('Location'));

    this->{treeWidget} = Qt::TreeWidget();
    treeWidget->header()->setResizeMode(Qt::HeaderView::Stretch());
    treeWidget->setHeaderLabels(\@labels);
    setCentralWidget(treeWidget);

    createActions();
    createMenus();

    statusBar()->showMessage(this->tr('Ready'));

    setWindowTitle(this->tr('SAX Bookmarks'));
    resize(480, 320);
}

sub open
{
#if defined(Q_OS_SYMBIAN)
    # Look for bookmarks on the same drive where the application is installed to,
    # if drive is not read only. Qt::DesktopServices::DataLocation does this check,
    # and returns writable drive.
    #Qt::String bookmarksFolder =
            #Qt::DesktopServices::storageLocation(Qt::DesktopServices::DataLocation).left(1);
    #bookmarksFolder.append(':/Data/qt/saxbookmarks');
    #Qt::Dir::setCurrent(bookmarksFolder);
#endif
    my $fileName =
            Qt::FileDialog::getOpenFileName(this, this->tr('Open Bookmark File'),
                                         Qt::Dir::currentPath(),
                                         this->tr('XBEL Files (*.xbel *.xml)'));
    if (!$fileName) {
        return;
    }

    treeWidget->clear();

    my $handler = XbelHandler(treeWidget);
    my $reader = Qt::XmlSimpleReader();
    $reader->setContentHandler($handler);
    $reader->setErrorHandler($handler);

    my $file = Qt::File($fileName);
    if (!$file->open(Qt::File::ReadOnly() | Qt::File::Text())) {
        Qt::MessageBox::warning(this, this->tr('SAX Bookmarks'),
                             sprintf this->tr("Cannot read file %s:\n%s."),
                             $fileName,
                             $file->errorString());
        return;
    }

    my $xmlInputSource = Qt::XmlInputSource($file);
    if ($reader->parse($xmlInputSource)) {
        statusBar()->showMessage(this->tr('File loaded'), 2000);
    }
}

sub saveAs
{
    my $fileName =
            Qt::FileDialog::getSaveFileName(this, this->tr('Save Bookmark File'),
                                         Qt::Dir::currentPath(),
                                         this->tr('XBEL Files (*.xbel *.xml)'));
    if (!$fileName) {
        return;
    }

    my $file = Qt::File($fileName);
    if (!$file->open(Qt::File::WriteOnly() | Qt::File::Text())) {
        Qt::MessageBox::warning(this, this->tr('SAX Bookmarks'),
                             sprintf this->tr("Cannot write file %s:\n%s."),
                             $fileName,
                             $file->errorString());
        return;
    }

    my $generator = XbelGenerator(treeWidget);
    if ($generator->write($file)) {
        statusBar()->showMessage(this->tr('File saved'), 2000);
    }
}

sub about
{
   Qt::MessageBox::about(this, this->tr('About SAX Bookmarks'),
            this->tr('The <b>SAX Bookmarks</b> example demonstrates how to use Qt\'s ' .
               'SAX classes to read XML documents and how to generate XML by ' .
               'hand.'));
}

sub createActions
{
    this->{openAct} = Qt::Action(this->tr('&Open...'), this);
    openAct->setShortcut(Qt::KeySequence(Qt::KeySequence::Open()));
    this->connect(openAct, SIGNAL 'triggered()', this, SLOT 'open()');

    this->{saveAsAct} = Qt::Action(this->tr('&Save As...'), this);
    saveAsAct->setShortcut(Qt::KeySequence(Qt::KeySequence::SaveAs()));
    this->connect(saveAsAct, SIGNAL 'triggered()', this, SLOT 'saveAs()');

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
    this->{fileMenu} = menuBar()->addMenu(this->tr('&File'));
    fileMenu->addAction(openAct);
    fileMenu->addAction(saveAsAct);
    fileMenu->addAction(exitAct);

    menuBar()->addSeparator();

    this->{helpMenu} = menuBar()->addMenu(this->tr('&Help'));
    helpMenu->addAction(aboutAct);
    helpMenu->addAction(aboutQtAct);
}

1;
