package ImageViewer;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::MainWindow );
use QtCore4::slots
    open => [],
    print => [],
    zoomIn => [],
    zoomOut => [],
    normalSize => [],
    fitToWindow => [],
    about => [];

sub imageLabel() {
    return this->{imageLabel};
}

sub scrollArea() {
    return this->{scrollArea};
}

sub scaleFactor() {
    return this->{scaleFactor};
}

sub printer() {
    return this->{printer};
}

sub openAct() {
    return this->{openAct};
}

sub printAct() {
    return this->{printAct};
}

sub exitAct() {
    return this->{exitAct};
}

sub zoomInAct() {
    return this->{zoomInAct};
}

sub zoomOutAct() {
    return this->{zoomOutAct};
}

sub normalSizeAct() {
    return this->{normalSizeAct};
}

sub fitToWindowAct() {
    return this->{fitToWindowAct};
}

sub aboutAct() {
    return this->{aboutAct};
}

sub aboutQtAct() {
    return this->{aboutQtAct};
}

sub fileMenu() {
    return this->{fileMenu};
}

sub viewMenu() {
    return this->{viewMenu};
}

sub helpMenu() {
    return this->{helpMenu};
}

# [0]

# [0]
sub NEW {
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
    this->{imageLabel} = Qt::Label();
    this->imageLabel->setBackgroundRole(Qt::Palette::Base());
    this->imageLabel->setSizePolicy(Qt::SizePolicy::Ignored(), Qt::SizePolicy::Ignored());
    this->imageLabel->setScaledContents(1);

    this->{scrollArea} = Qt::ScrollArea();
    this->scrollArea->setBackgroundRole(Qt::Palette::Dark());
    this->scrollArea->setWidget(this->imageLabel);
    this->setCentralWidget(this->scrollArea);

    this->createActions();
    this->createMenus();

    this->setWindowTitle(this->tr('Image Viewer'));
    this->resize(500, 400);
}
# [0]

# [1]
sub open {
# [1] //! [2]
    my $fileName = Qt::FileDialog::getOpenFileName(this,
                                    this->tr('Open File'), Qt::Dir::currentPath());
    if ($fileName) {
        my $image = Qt::Image(Qt::String($fileName));
        if ($image->isNull()) {
            Qt::MessageBox::information(this, this->tr('Image Viewer'),
                                     sprintf( this->tr('Cannot load %s.'), $fileName ));
            return;
        }
# [2] //! [3]
        this->imageLabel->setPixmap(Qt::Pixmap::fromImage($image));
# [3] //! [4]
        this->{scaleFactor} = 1.0;

        this->printAct->setEnabled(1);
        this->fitToWindowAct->setEnabled(1);
        this->updateActions();

        if (!this->fitToWindowAct->isChecked()) {
            this->imageLabel->adjustSize();
        }
    }
}
# [4]

# [5]
sub print {
# [5] //! [6]
# [6] //! [7]
    my $dialog = Qt::PrintDialog(this->printer, this);
# [7] //! [8]
    if ($dialog->exec()) {
        my $painter = Qt::Painter(this->printer);
        my $rect = this->painter->viewport();
        my $size = this->imageLabel->pixmap()->size();
        $size->scale($rect->size(), Qt::KeepAspectRatio());
        $painter->setViewport($rect->x(), $rect->y(), $size->width(), $size->height());
        $painter->setWindow(this->imageLabel->pixmap()->rect());
        $painter->drawPixmap(0, 0, this->imageLabel->pixmap());
    }
}
# [8]

# [9]
sub zoomIn {
# [9] //! [10]
    this->scaleImage(1.25);
}

sub zoomOut {
    this->scaleImage(0.8);
}

# [10] //! [11]
sub normalSize {
# [11] //! [12]
    this->imageLabel->adjustSize();
    this->{scaleFactor} = 1.0;
}
# [12]

# [13]
sub fitToWindow {
# [13] //! [14]
    my $fitToWindow = this->fitToWindowAct->isChecked();
    this->scrollArea->setWidgetResizable($fitToWindow);
    if (!$fitToWindow) {
        this->normalSize();
    }
    this->updateActions();
}
# [14]


# [15]
sub about {
# [15] //! [16]
    Qt::MessageBox::about(this, this->tr('About Image Viewer'),
            this->tr('<p>The <b>Image Viewer</b> example shows how to combine Qt::Label ' .
               'and Qt::ScrollArea to display an image. Qt::Label is typically used ' .
               'for displaying a text, but it can also display an image. ' .
               'Qt::ScrollArea provides a scrolling view around another widget. ' .
               'If the child widget exceeds the size of the frame, Qt::ScrollArea ' .
               'automatically provides scroll bars. </p><p>The example ' .
               'demonstrates how Qt::Label\'s ability to scale its contents ' .
               '(Qt::Label::scaledContents), and Qt::ScrollArea\'s ability to ' .
               'automatically resize its contents ' .
               '(Qt::ScrollArea::widgetResizable), can be used to implement ' .
               'zooming and scaling features. </p><p>In addition the example ' .
               'shows how to use Qt::Painter to print an image.</p>'));
}
# [16]

# [17]
sub createActions {
# [17] //! [18]
    this->{openAct} = Qt::Action(this->tr('&Open...'), this);
    this->openAct->setShortcut(Qt::KeySequence(this->tr('Ctrl+O')));
    this->connect(this->openAct, SIGNAL 'triggered()', this, SLOT 'open()');

    this->{printAct} = Qt::Action(this->tr('&Print...'), this);
    this->printAct->setShortcut(Qt::KeySequence(this->tr('Ctrl+P')));
    this->printAct->setEnabled(0);
    this->connect(this->printAct, SIGNAL 'triggered()', this, SLOT 'print()');

    this->{exitAct} = Qt::Action(this->tr('E&xit'), this);
    this->exitAct->setShortcut(Qt::KeySequence(this->tr('Ctrl+Q')));
    this->connect(this->exitAct, SIGNAL 'triggered()', this, SLOT 'close()');

    this->{zoomInAct} = Qt::Action(this->tr('Zoom &In (25%)'), this);
    this->zoomInAct->setShortcut(Qt::KeySequence(this->tr('Ctrl++')));
    this->zoomInAct->setEnabled(0);
    this->connect(this->zoomInAct, SIGNAL 'triggered()', this, SLOT 'zoomIn()');

    this->{zoomOutAct} = Qt::Action(this->tr('Zoom &Out (25%)'), this);
    this->zoomOutAct->setShortcut(Qt::KeySequence(this->tr('Ctrl+-')));
    this->zoomOutAct->setEnabled(0);
    this->connect(this->zoomOutAct, SIGNAL 'triggered()', this, SLOT 'zoomOut()');

    this->{normalSizeAct} = Qt::Action(this->tr('&Normal Size'), this);
    this->normalSizeAct->setShortcut(Qt::KeySequence(this->tr('Ctrl+S')));
    this->normalSizeAct->setEnabled(0);
    this->connect(this->normalSizeAct, SIGNAL 'triggered()', this, SLOT 'normalSize()');

    this->{fitToWindowAct} = Qt::Action(this->tr('&Fit to Window'), this);
    this->fitToWindowAct->setEnabled(0);
    this->fitToWindowAct->setCheckable(1);
    this->fitToWindowAct->setShortcut(Qt::KeySequence(this->tr('Ctrl+F')));
    this->connect(this->fitToWindowAct, SIGNAL 'triggered()', this, SLOT 'fitToWindow()');

    this->{aboutAct} = Qt::Action(this->tr('&About'), this);
    this->connect(this->aboutAct, SIGNAL 'triggered()', this, SLOT 'about()');

    this->{aboutQtAct} = Qt::Action(this->tr('About &Qt'), this);
    this->connect(this->aboutQtAct, SIGNAL 'triggered()', qApp, SLOT 'aboutQt()');
}
# [18]

# [19]
sub createMenus {
# [19] //! [20]
    this->{fileMenu} = Qt::Menu(this->tr('&File'), this);
    this->fileMenu->addAction(this->openAct);
    this->fileMenu->addAction(this->printAct);
    this->fileMenu->addSeparator();
    this->fileMenu->addAction(this->exitAct);

    this->{viewMenu} = Qt::Menu(this->tr('&View'), this);
    this->viewMenu->addAction(this->zoomInAct);
    this->viewMenu->addAction(this->zoomOutAct);
    this->viewMenu->addAction(this->normalSizeAct);
    this->viewMenu->addSeparator();
    this->viewMenu->addAction(this->fitToWindowAct);

    this->{helpMenu} = Qt::Menu(this->tr('&Help'), this);
    this->helpMenu->addAction(this->aboutAct);
    this->helpMenu->addAction(this->aboutQtAct);

    this->menuBar()->addMenu(this->fileMenu);
    this->menuBar()->addMenu(this->viewMenu);
    this->menuBar()->addMenu(this->helpMenu);
}
# [20]

# [21]
sub updateActions {
# [21] //! [22]
    this->zoomInAct->setEnabled(!this->fitToWindowAct->isChecked());
    this->zoomOutAct->setEnabled(!this->fitToWindowAct->isChecked());
    this->normalSizeAct->setEnabled(!this->fitToWindowAct->isChecked());
}
# [22]

# [23]
sub scaleImage {
# [23] //! [24]
    my ( $factor ) = @_;
    this->{scaleFactor} *= $factor;
    this->imageLabel->resize(this->scaleFactor * this->imageLabel->pixmap()->size());

    this->adjustScrollBar(this->scrollArea->horizontalScrollBar(), $factor);
    this->adjustScrollBar(this->scrollArea->verticalScrollBar(), $factor);

    this->zoomInAct->setEnabled(this->scaleFactor < 3.0);
    this->zoomOutAct->setEnabled(this->scaleFactor > 0.333);
}
# [24]

# [25]
sub adjustScrollBar {
# [25] //! [26]
    my ($scrollBar, $factor) = @_;
    $scrollBar->setValue(int($factor * $scrollBar->value()
                            + (($factor - 1) * $scrollBar->pageStep()/2)));
}
# [26]

1;
