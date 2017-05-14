package MainWindow;

use strict;
use warnings;
use QtCore4;
use QtGui4;

# [0]
use QtCore4::isa qw( Qt::MainWindow );
use QtCore4::slots
    about => [],
    newFile => [],
    openFile => ['const QString &', 'QString'],
    openFile2 => [];

use Highlighter;
# [0]

# [0]
sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->setupFileMenu();
    this->setupHelpMenu();
    this->setupEditor();

    this->setCentralWidget(this->{editor});
    this->setWindowTitle(this->tr('Syntax Highlighter'));
}
# [0]

sub about
{
    Qt::MessageBox::about(this, this->tr('About Syntax Highlighter'),
                this->tr('<p>The <b>Syntax Highlighter</b> example shows how ' .
                   'to perform simple syntax highlighting by subclassing ' .
                   'the Qt::SyntaxHighlighter class and describing ' .
                   'highlighting rules using regular expressions.</p>'));
}

sub newFile
{
    this->{editor}->clear();
}

sub openFile2 {
    this->openFile();
}

sub openFile
{
    my ($path) = @_;
    my $fileName = $path;

    if (!$fileName) {
        $fileName = Qt::FileDialog::getOpenFileName(this,
            this->tr('Open File'), '', 'C++ Files (*.cpp *.h)');
    }

    if ($fileName) {
        my $file = Qt::File($fileName);
        if ($file->open(Qt::File::ReadOnly() | Qt::File::Text())) {
            this->{editor}->setPlainText($file->readAll()->data());
        }
    }
}

# [1]
sub setupEditor
{
    my $font = Qt::Font();
    $font->setFamily('Courier');
    $font->setFixedPitch(1);
    $font->setPointSize(10);

    this->{editor} = Qt::TextEdit();
    this->{editor}->setFont($font);

    this->{highlighter} = Highlighter(this->{editor}->document());

    my $file = Qt::File('mainwindow.h');
    if ($file->open(Qt::File::ReadOnly() | Qt::File::Text())) {
        this->{editor}->setPlainText($file->readAll());
    }
}
# [1]

sub setupFileMenu
{
    my $fileMenu = Qt::Menu(this->tr('&File'), this);
    this->menuBar()->addMenu($fileMenu);

    $fileMenu->addAction(this->tr('&New'), this, SLOT 'newFile()',
                        Qt::KeySequence(Qt::KeySequence::New()));

    $fileMenu->addAction(this->tr('&Open...'), this, SLOT 'openFile2()',
                        Qt::KeySequence(Qt::KeySequence::Open()));
                        
    $fileMenu->addAction(this->tr('E&xit'), qApp, SLOT 'quit()',
                        #Qt::KeySequence(Qt::KeySequence::Quit()));
                        Qt::KeySequence('Ctrl+Q'));
}

sub setupHelpMenu
{
    my $helpMenu = Qt::Menu(this->tr('&Help'), this);
    this->menuBar()->addMenu($helpMenu);

    $helpMenu->addAction(this->tr('&About'), this, SLOT 'about()');
    $helpMenu->addAction(this->tr('About &Qt'), qApp, SLOT 'aboutQt()');
}

1;
