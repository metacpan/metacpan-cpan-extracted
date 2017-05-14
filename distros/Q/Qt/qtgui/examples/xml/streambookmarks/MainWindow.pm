package MainWindow;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::MainWindow );
use QtCore4::slots
    open => [],
    saveAs => [],
    about => [];
use XbelReader;
use XbelWriter;

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

# [0]
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

    setWindowTitle(this->tr('Qt::XmlStream Bookmarks'));
    resize(480, 320);
}
# [0]

# [1]
sub open
{
    my ($fileName) = @_;
    if (!$fileName) {
        $fileName =
            Qt::FileDialog::getOpenFileName(this, this->tr('Open Bookmark File'),
                                         Qt::Dir::currentPath(),
                                         this->tr('XBEL Files (*.xbel *.xml)'));
    }

    if (!$fileName) {
        return;
    }

    treeWidget->clear();


    my $file = Qt::File($fileName);
    if (!$file->open(Qt::File::ReadOnly() | Qt::File::Text())) {
        Qt::MessageBox::warning(this, this->tr('Qt::XmlStream Bookmarks'),
                             sprintf this->tr("Cannot read file %s:\n%s."),
                             $fileName,
                             $file->errorString());
        return;
    }

    my $reader = XbelReader(treeWidget);
    if ($reader->read($file) != Qt::XmlStreamReader::NoError()) {
        Qt::MessageBox::warning(this, this->tr('Qt::XmlStream Bookmarks'),
                             sprintf this->tr("Parse error in file %s:\n\n%s"),
                             $fileName,
                             $file->errorString());
    } else {
        statusBar()->showMessage(this->tr('File loaded'), 2000);
    }

}
# [1]

# [2]
sub saveAs
{
    my ($fileName) = @_;
    if (!$fileName) {
        $fileName =
            Qt::FileDialog::getSaveFileName(this, this->tr('Save Bookmark File'),
                                         Qt::Dir::currentPath(),
                                         this->tr('XBEL Files (*.xbel *.xml)'));
    }

    if (!$fileName) {
        return;
    }

    my $file = Qt::File($fileName);
    if (!$file->open(Qt::File::WriteOnly() | Qt::File::Text())) {
        Qt::MessageBox::warning(this, this->tr('Qt::XmlStream Bookmarks'),
                             sprintf this->tr("Cannot write file %s:\n%s."),
                             $fileName,
                             $file->errorString());
        return;
    }

    my $writer = XbelWriter(treeWidget);
    if ($writer->writeFile($file)) {
        statusBar()->showMessage(this->tr('File saved'), 2000);
    }
    $file->close();
}
# [2]

# [3]
sub about
{
   Qt::MessageBox::about(this, this->tr('About Qt::XmlStream Bookmarks'),
            this->tr('The <b>Qt::XmlStream Bookmarks</b> example demonstrates how to use Qt\'s ' .
               'Qt::XmlStream classes to read and write XML documents.'));
}
# [3]

# [4]
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
# [4]

# [5]
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
# [5]

1;
