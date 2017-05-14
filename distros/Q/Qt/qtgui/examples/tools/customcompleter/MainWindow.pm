package MainWindow;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::MainWindow );
use QtCore4::slots
    about => [];
use TextEdit;

sub completer() {
    return this->{completer};
}

sub completingTextEdit() {
    return this->{completingTextEdit};
}

# [0]
sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    createMenu();

    this->{completingTextEdit} = TextEdit(this);
    this->{completer} = Qt::Completer(this);
    completer->setModel(modelFromFile(':/resources/wordlist.txt'));
    completer->setModelSorting(Qt::Completer::CaseInsensitivelySortedModel());
    completer->setCaseSensitivity(Qt::CaseInsensitive());
    completer->setWrapAround(0);
    completingTextEdit->setCompleter(completer);

    setCentralWidget(completingTextEdit);
    resize(500, 300);
    setWindowTitle(this->tr('Completer'));
}
# [0]

# [1]
sub createMenu
{
    my $exitAction = Qt::Action(this->tr('Exit'), this);
    my $aboutAct = Qt::Action(this->tr('About'), this);
    my $aboutQtAct = Qt::Action(this->tr('About Qt'), this);

    this->connect($exitAction, SIGNAL 'triggered()', qApp, SLOT 'quit()');
    this->connect($aboutAct, SIGNAL 'triggered()', this, SLOT 'about()');
    this->connect($aboutQtAct, SIGNAL 'triggered()', qApp, SLOT 'aboutQt()');

    my $fileMenu = menuBar()->addMenu(this->tr('File'));
    $fileMenu->addAction($exitAction);

    my $helpMenu = menuBar()->addMenu(this->tr('About'));
    $helpMenu->addAction($aboutAct);
    $helpMenu->addAction($aboutQtAct);
}
# [1]

# [2]
sub modelFromFile
{
    my ($fileName) = @_;
    my $file = Qt::File($fileName);
    if (!$file->open(Qt::File::ReadOnly())) {
        return Qt::StringListModel(completer);
    }

    Qt::Application::setOverrideCursor(Qt::Cursor(Qt::WaitCursor()));
    my @words;
    
    while (!$file->atEnd()) {
        my $line = $file->readLine();
        if ($line) {
            push @words, $line->constData;
        }
    }
    chomp(@words);

    Qt::Application::restoreOverrideCursor();
    return Qt::StringListModel(\@words, completer);
}
# [2]

# [3]
sub about
{
    Qt::MessageBox::about(this, this->tr('About'), this->tr('This example demonstrates the ' .
        'different features of the Qt::Completer class.'));
}
# [3]

1;
