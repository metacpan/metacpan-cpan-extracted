package MainWindow;

use strict;
use warnings;

use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::MainWindow );
use QtCore4::slots
    open => [],
    save => [],
    penColor => [],
    penWidth => [],
    about => [];
use ScribbleArea;

sub scribbleArea() {
    return this->{scribbleArea};
}

sub saveAsMenu() {
    return this->{saveAsMenu};
}

sub fileMenu() {
    return this->{fileMenu};
}

sub optionMenu() {
    return this->{optionMenu};
}

sub helpMenu() {
    return this->{helpMenu};
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

sub penColorAct() {
    return this->{penColorAct};
}

sub penWidthAct() {
    return this->{penWidthAct};
}

sub printAct() {
    return this->{printAct};
}

sub clearScreenAct() {
    return this->{clearScreenAct};
}

sub aboutAct() {
    return this->{aboutAct};
}

sub aboutQtAct() {
    return this->{aboutQtAct};
}
# [0]

# [0]
sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );

    this->{scribbleArea} = ScribbleArea();
    this->setCentralWidget(this->scribbleArea);

    this->createActions();
    this->createMenus();

    this->setWindowTitle(this->tr('Scribble'));
    this->resize(500, 500);
}
# [0]

# [1]
sub closeEvent {
# [1] //! [2]
    my ($event) = @_;
    if (this->maybeSave()) {
        $event->accept();
    } else {
        $event->ignore();
    }
}
# [2]

# [3]
sub open {
# [3] //! [4]
    if (maybeSave()) {
        my $fileName = Qt::FileDialog::getOpenFileName(this,
                                   this->tr('Open File'), Qt::Dir::currentPath());
        if ($fileName) {
            this->scribbleArea->openImage($fileName);
        }
    }
}
# [4]

# [5]
sub save {
# [5] //! [6]
    my $action = this->sender();
    my $fileFormat = $action->data()->toString();
    this->saveFile($fileFormat);
}
# [6]

# [7]
sub penColor {
# [7] //! [8]
    my $newColor = Qt::ColorDialog::getColor(this->scribbleArea->penColor());
    if ($newColor->isValid()) {
        this->scribbleArea->setPenColor($newColor);
    }
}
# [8]

# [9]
sub penWidth {
# [9] //! [10]
    my $ok = 0;
    my $newWidth = Qt::InputDialog::getInteger(this, this->tr('Scribble'),
                                            this->tr('Select pen width:'),
                                            this->scribbleArea->penWidth(),
                                            1, 50, 1, $ok);
    if ($ok) {
        this->scribbleArea->setPenWidth($newWidth);
    }
}
# [10]

# [11]
sub about {
# [11] //! [12]
    Qt::MessageBox::about(this, this->tr('About Scribble'),
            this->tr('<p>The <b>Scribble</b> example shows how to use Qt::MainWindow as the ' .
               'base widget for an application, and how to reimplement some of ' .
               'Qt::Widget\'s event handlers to receive the events generated for ' .
               'the application\'s widgets:</p><p> We reimplement the mouse event ' .
               'handlers to facilitate drawing, the paint event handler to ' .
               'update the application and the resize event handler to optimize ' .
               'the application\'s appearance. In addition we reimplement the ' .
               'close event handler to intercept the close events before ' .
               'terminating the application.</p><p> The example also demonstrates ' .
               'how to use Qt::Painter to draw an image in real time, as well as ' .
               'to repaint widgets.</p>'));
}
# [12]

# [13]
sub createActions {
# [13] //! [14]
    this->{openAct} = Qt::Action(this->tr('&Open...'), this);
    this->openAct->setShortcut(Qt::KeySequence(this->tr('Ctrl+O')));
    this->connect(this->openAct, SIGNAL 'triggered()', this, SLOT 'open()');

    foreach my $format ( @{Qt::ImageWriter::supportedImageFormats()} ) {
        my $text = sprintf this->tr('%s...'), uc $format;

        my $action = Qt::Action($text, this);
        $action->setData(Qt::Variant(Qt::String($format)));
        this->connect($action, SIGNAL 'triggered()', this, SLOT 'save()');
        push @{this->{saveAsActs}}, $action;
    }

    this->{printAct} = Qt::Action(this->tr('&Print...'), this);
    this->connect(this->printAct, SIGNAL 'triggered()', this->scribbleArea, SLOT 'print()');

    this->{exitAct} = Qt::Action(this->tr('E&xit'), this);
    this->exitAct->setShortcut(Qt::KeySequence(this->tr('Ctrl+Q')));
    this->connect(this->exitAct, SIGNAL 'triggered()', this, SLOT 'close()');

    this->{penColorAct} = Qt::Action(this->tr('&Pen Color...'), this);
    this->connect(this->penColorAct, SIGNAL 'triggered()', this, SLOT 'penColor()');

    this->{penWidthAct} = Qt::Action(this->tr('Pen &Width...'), this);
    this->connect(this->penWidthAct, SIGNAL 'triggered()', this, SLOT 'penWidth()');

    this->{clearScreenAct} = Qt::Action(this->tr('&Clear Screen'), this);
    this->clearScreenAct->setShortcut(Qt::KeySequence(this->tr('Ctrl+L')));
    this->connect(this->clearScreenAct, SIGNAL 'triggered()',
            this->scribbleArea, SLOT 'clearImage()');

    this->{aboutAct} = Qt::Action(this->tr('&About'), this);
    this->connect(this->aboutAct, SIGNAL 'triggered()', this, SLOT 'about()');

    this->{aboutQtAct} = Qt::Action(this->tr('About &Qt'), this);
    this->connect(this->aboutQtAct, SIGNAL 'triggered()', qApp, SLOT 'aboutQt()');
}
# [14]

# [15]
sub createMenus {
# [15] //! [16]
    this->{saveAsMenu} = Qt::Menu(this->tr('&Save As'), this);
    foreach my $action ( @{this->{saveAsActs}} ) {
        this->saveAsMenu->addAction($action);
    }

    this->{fileMenu} = Qt::Menu(this->tr('&File'), this);
    this->fileMenu->addAction(this->openAct);
    this->fileMenu->addMenu(this->saveAsMenu);
    this->fileMenu->addAction(this->printAct);
    this->fileMenu->addSeparator();
    this->fileMenu->addAction(this->exitAct);

    this->{optionMenu} = Qt::Menu(this->tr('&Options'), this);
    this->optionMenu->addAction(this->penColorAct);
    this->optionMenu->addAction(this->penWidthAct);
    this->optionMenu->addSeparator();
    this->optionMenu->addAction(this->clearScreenAct);

    this->{helpMenu} = Qt::Menu(this->tr('&Help'), this);
    this->helpMenu->addAction(this->aboutAct);
    this->helpMenu->addAction(this->aboutQtAct);

    this->menuBar()->addMenu(this->fileMenu);
    this->menuBar()->addMenu(this->optionMenu);
    this->menuBar()->addMenu(this->helpMenu);
}
# [16]

# [17]
sub maybeSave {
# [17] //! [18]
    if (this->scribbleArea->isModified()) {
        my $ret = Qt::MessageBox::warning(this, this->tr('Scribble'),
                          this->tr("The image has been modified.\n" .
                             'Do you want to save your changes?'),
                          CAST Qt::MessageBox::Save() | Qt::MessageBox::Discard()
			  | Qt::MessageBox::Cancel(), 'QMessageBox::StandardButtons');
        if ($ret == Qt::MessageBox::Save()) {
            return this->saveFile('png');
        } elsif ($ret == Qt::MessageBox::Cancel()) {
            return 0;
        }
    }
    return 1;
}
# [18]

# [19]
sub saveFile {
# [19] //! [20]
    my ($fileFormat) = @_;
    my $initialPath = Qt::Dir::currentPath() . '/untitled.' . $fileFormat;

    my $fileName = Qt::FileDialog::getSaveFileName(this, this->tr('Save As'),
                               $initialPath,
                               sprintf( this->tr('%s Files (*.%s);;All Files (*)'),
                                   uc $fileFormat,
                                   $fileFormat )
                               );
    if (!$fileName) {
        return 0;
    } else {
        return this->scribbleArea->saveImage($fileName, $fileFormat);
    }
}
# [20]

1;
