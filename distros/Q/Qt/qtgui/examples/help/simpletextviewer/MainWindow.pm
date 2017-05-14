package MainWindow;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::MainWindow );
use QtCore4::slots
    about => [],
    showDocumentation => [],
    open => [];

use FindFileDialog;
use Assistant;
use TextEdit;

sub assistant() {
    return this->{assistant};
}

sub textViewer() {
    return this->{textViewer};
}

sub fileMenu() {
    return this->{fileMenu};
}

sub helpMenu() {
    return this->{helpMenu};
}

sub assistantAct() {
    return this->{assistantAct};
}

sub clearAct() {
    return this->{clearAct};
}

sub openAct() {
    return this->{openAct};
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


# ![0]
sub NEW
{
    my ($class) = @_;
    $class->SUPER::NEW();
    this->{assistant} = Assistant->new();
# ![0]
    this->{textViewer} = TextEdit();
    textViewer->setContents(Qt::LibraryInfo::location(Qt::LibraryInfo::ExamplesPath())
            . '/help/simpletextviewer/documentation/intro.html');
    setCentralWidget(textViewer);

    createActions();
    createMenus();

    setWindowTitle(this->tr('Simple Text Viewer'));
    resize(750, 400);
# ![1]
}
# [1]

# [2]
sub closeEvent
{
    this->{assistant} = undef;
}
# [2]

sub about
{
    Qt::MessageBox::about(this, this->tr('About Simple Text Viewer'),
                       this->tr("This example demonstrates how to use\n" .
                          "Qt Assistant as help system for your\n" .
                          'own application.'));
}

# [3]
sub showDocumentation
{
    assistant->showDocumentation('index.html');    
}
# [3]

sub open
{
    my $dialog = FindFileDialog(textViewer, assistant);
    $dialog->exec();
}

# [4]
sub createActions
{
    this->{assistantAct} = Qt::Action(this->tr('Help Contents'), this);
    assistantAct->setShortcut(Qt::KeySequence(Qt::KeySequence::HelpContents()));
    this->connect(assistantAct, SIGNAL 'triggered()', this, SLOT 'showDocumentation()');
# [4]

    this->{openAct} = Qt::Action(this->tr('&Open...'), this);
    openAct->setShortcut(Qt::KeySequence(Qt::KeySequence::Open()));
    this->connect(openAct, SIGNAL 'triggered()', this, SLOT 'open()');

    this->{clearAct} = Qt::Action(this->tr('&Clear'), this);
    clearAct->setShortcut(Qt::KeySequence(this->tr('Ctrl+C')));
    this->connect(clearAct, SIGNAL 'triggered()', textViewer, SLOT 'clear()');

    this->{exitAct} = Qt::Action(this->tr('E&xit'), this);
    exitAct->setShortcuts([Qt::KeySequence(Qt::KeySequence::Quit())]);
    this->connect(exitAct, SIGNAL 'triggered()', this, SLOT 'close()');

    this->{aboutAct} = Qt::Action(this->tr('&About'), this);
    this->connect(aboutAct, SIGNAL 'triggered()', this, SLOT 'about()');

    this->{aboutQtAct} = Qt::Action(this->tr('About &Qt'), this);
    this->connect(aboutQtAct, SIGNAL 'triggered()', qApp, SLOT 'aboutQt()');
# [5]
}
# [5]

sub createMenus
{
    this->{fileMenu} = Qt::Menu(this->tr('&File'), this);
    fileMenu->addAction(openAct);
    fileMenu->addAction(clearAct);
    fileMenu->addSeparator();
    fileMenu->addAction(exitAct);

    this->{helpMenu} = Qt::Menu(this->tr('&Help'), this);
    helpMenu->addAction(assistantAct);
    helpMenu->addSeparator();
    helpMenu->addAction(aboutAct);
    helpMenu->addAction(aboutQtAct);


    menuBar()->addMenu(fileMenu);
    menuBar()->addMenu(helpMenu);
}

1;
