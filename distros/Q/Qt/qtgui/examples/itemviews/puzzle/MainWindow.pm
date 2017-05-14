package MainWindow;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::MainWindow );
use QtCore4::slots
    openImage => [],
    setupPuzzle => [],
    setCompleted => [];
use PiecesModel;
use PuzzleWidget;
use List::Util qw( min );

sub puzzleImage() {
    return this->{puzzleImage};
}

sub piecesList() {
    return this->{piecesList};
}

sub puzzleWidget() {
    return this->{puzzleWidget};
}

sub model() {
    return this->{model};
}

sub NEW
{
    my ( $class, $parent ) = @_;
    $class->SUPER::NEW( $parent );
    this->setupMenus();
    this->setupWidgets();
    this->{model} = PiecesModel(this);
    this->piecesList->setModel(this->model);

    this->setSizePolicy(Qt::SizePolicy(Qt::SizePolicy::Fixed(), Qt::SizePolicy::Fixed()));
    this->setWindowTitle(this->tr('Puzzle'));
}

sub openImage
{
    my ($path) = @_;
    my $fileName = $path;

    if (!$fileName) {
        $fileName = Qt::FileDialog::getOpenFileName(this,
            this->tr('Open Image'), '', this->tr('Image Files (*.png *.jpg *.bmp)'));
    }

    if ($fileName) {
        my $newImage = Qt::Pixmap();
        if (!$newImage->load($fileName)) {
            Qt::MessageBox::warning(this, this->tr('Open Image'),
                                 this->tr('The image file could not be loaded.'),
                                 Qt::MessageBox::Cancel());
            return;
        }
        this->{puzzleImage} = $newImage;
        this->setupPuzzle();
    }
}

sub setCompleted
{
    Qt::MessageBox::information(this, this->tr('Puzzle Completed'),
        this->tr("Congratulations! You have completed the puzzle!\n" .
           'Click OK to start again.'),
        Qt::MessageBox::Ok());

    this->setupPuzzle();
}

sub setupPuzzle
{
    my $size = min(this->puzzleImage->width(), this->puzzleImage->height());
    this->{puzzleImage} = this->puzzleImage->copy((this->puzzleImage->width() - $size)/2,
        (this->puzzleImage->height() - $size)/2, $size, $size)->scaled(400,
            400, Qt::IgnoreAspectRatio(), Qt::SmoothTransformation());

    srand(Qt::Cursor::pos()->x() ^ Qt::Cursor::pos()->y());


    this->model->addPieces(this->puzzleImage);
    this->puzzleWidget->clear();
}

sub setupMenus
{
    my $fileMenu = this->menuBar()->addMenu(this->tr('&File'));

    my $openAction = $fileMenu->addAction(this->tr('&Open...'));
    $openAction->setShortcut(Qt::KeySequence(this->tr('Ctrl+O')));

    my $exitAction = $fileMenu->addAction(this->tr('E&xit'));
    $exitAction->setShortcut(Qt::KeySequence(this->tr('Ctrl+Q')));

    my $gameMenu = this->menuBar()->addMenu(this->tr('&Game'));

    my $restartAction = $gameMenu->addAction(this->tr('&Restart'));

    this->connect($openAction, SIGNAL 'triggered()', this, SLOT 'openImage()');
    this->connect($exitAction, SIGNAL 'triggered()', qApp, SLOT 'quit()');
    this->connect($restartAction, SIGNAL 'triggered()', this, SLOT 'setupPuzzle()');
}

sub setupWidgets
{
    my $frame = Qt::Frame();
    my $frameLayout = Qt::HBoxLayout($frame);

    my $piecesList = this->{piecesList} = Qt::ListView();
    $piecesList->setDragEnabled(1);
    $piecesList->setViewMode(Qt::ListView::IconMode());
    $piecesList->setIconSize(Qt::Size(60, 60));
    $piecesList->setGridSize(Qt::Size(80, 80));
    $piecesList->setSpacing(10);
    $piecesList->setMovement(Qt::ListView::Snap());
    $piecesList->setAcceptDrops(1);
    $piecesList->setDropIndicatorShown(1);

    my $model = PiecesModel(this);
    this->piecesList->setModel($model);

    this->{puzzleWidget} = PuzzleWidget();

    this->connect(this->puzzleWidget, SIGNAL 'puzzleCompleted()',
            this, SLOT 'setCompleted()', Qt::QueuedConnection());

    $frameLayout->addWidget($piecesList);
    $frameLayout->addWidget(this->puzzleWidget);
    this->setCentralWidget($frame);
}

1;
