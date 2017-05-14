package MainWindow;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::MainWindow );
use QtCore4::slots
    chooseImage => [],
    printImage => [],
    showAboutBox => [],
    updateView => [];
use ImageModel;
use PixelDelegate;
use List::Util qw(min);

sub model() {
    return this->{model};
}

sub printAction() {
    return this->{printAction};
}

sub currentPath() {
    return this->{currentPath};
}

sub view() {
    return this->{view};
}


# [0]
sub NEW 
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
# [0]
    this->{currentPath} = Qt::Dir::homePath();
    this->{model} = ImageModel(this);

    my $centralWidget = Qt::Widget();

# [1]
    this->{view} = Qt::TableView();
    view->setShowGrid(0);
    view->horizontalHeader()->hide();
    view->verticalHeader()->hide();
    view->horizontalHeader()->setMinimumSectionSize(1);
    view->verticalHeader()->setMinimumSectionSize(1);
    view->setModel(model);
# [1]

# [2]
    my $delegate = PixelDelegate(this);
    view->setItemDelegate($delegate);
# [2]

# [3]
    my $pixelSizeLabel = Qt::Label(this->tr('Pixel size:'));
    my $pixelSizeSpinBox = Qt::SpinBox();
    $pixelSizeSpinBox->setMinimum(4);
    $pixelSizeSpinBox->setMaximum(32);
    $pixelSizeSpinBox->setValue(12);
# [3]

    my $fileMenu = Qt::Menu(this->tr('&File'), this);
    my $openAction = $fileMenu->addAction(this->tr('&Open...'));
    $openAction->setShortcut(Qt::KeySequence(Qt::KeySequence::Open()));

    this->{printAction} = $fileMenu->addAction(this->tr('&Print...'));
    printAction->setEnabled(0);
    printAction->setShortcut(Qt::KeySequence(Qt::KeySequence::Print()));

    my $quitAction = $fileMenu->addAction(this->tr('E&xit'));
    $quitAction->setShortcut(Qt::KeySequence(Qt::KeySequence::Quit()));

    my $helpMenu = Qt::Menu(this->tr('&Help'), this);
    my $aboutAction = $helpMenu->addAction(this->tr('&About'));

    menuBar()->addMenu($fileMenu);
    menuBar()->addSeparator();
    menuBar()->addMenu($helpMenu);

    this->connect($openAction, SIGNAL 'triggered()', this, SLOT 'chooseImage()');
    this->connect(printAction, SIGNAL 'triggered()', this, SLOT 'printImage()');
    this->connect($quitAction, SIGNAL 'triggered()', qApp, SLOT 'quit()');
    this->connect($aboutAction, SIGNAL 'triggered()', this, SLOT 'showAboutBox()');
# [4]
    this->connect($pixelSizeSpinBox, SIGNAL 'valueChanged(int)',
            $delegate, SLOT 'setPixelSize(int)');
    this->connect($pixelSizeSpinBox, SIGNAL 'valueChanged(int)',
            this, SLOT 'updateView()');
# [4]

    my $controlsLayout = Qt::HBoxLayout();
    $controlsLayout->addWidget($pixelSizeLabel);
    $controlsLayout->addWidget($pixelSizeSpinBox);
    $controlsLayout->addStretch(1);

    my $mainLayout = Qt::VBoxLayout();
    $mainLayout->addWidget(view);
    $mainLayout->addLayout($controlsLayout);
    $centralWidget->setLayout($mainLayout);

    setCentralWidget($centralWidget);

    setWindowTitle(this->tr('Pixelator'));
    resize(640, 480);
# [5]
}
# [5]

sub chooseImage
{
    my $fileName = Qt::FileDialog::getOpenFileName(this,
        this->tr('Choose an image'), currentPath, '*');

    if ($fileName) {
        openImage($fileName);
    }
}

sub openImage
{
    my ($fileName) = @_;
    my $image = Qt::Image();

    if ($image->load($fileName)) {
        model->setImage($image);
        if ($fileName !~ m#^:/#) {
            this->{currentPath} = $fileName;
            setWindowTitle(sprintf this->tr('%s - Pixelator'), currentPath);
        }

        printAction->setEnabled(1);
        updateView();
    }
}

sub printImage
{
#ifndef QT_NO_PRINTER
    if (model->rowCount(Qt::ModelIndex())*model->columnCount(Qt::ModelIndex())
        > 90000) {
	    my $answer = Qt::MessageBox::question(this, this->tr('Large Image Size'),
            this->tr('The printed image may be very large. Are you sure that ' .
               'you want to print it?'),
            Qt::MessageBox::Yes() | Qt::MessageBox::No());
        if ($answer == Qt::MessageBox::No()) {
            return;
        }
    }

    my $printer = Qt::Printer(Qt::Printer::HighResolution());

    my $dlg = Qt::PrintDialog($printer, this);
    $dlg->setWindowTitle(this->tr('Print Image'));

    if ($dlg->exec() != Qt::Dialog::Accepted()) {
        return;
    }

    my $painter = Qt::Painter();
    $painter->begin($printer);

    my $rows = model->rowCount(Qt::ModelIndex());
    my $columns = model->columnCount(Qt::ModelIndex());
    my $sourceWidth = ($columns+1) * PixelDelegate::ItemSize;
    my $sourceHeight = ($rows+1) * PixelDelegate::ItemSize;

    $painter->save();

    my $xscale = $printer->pageRect()->width()/$sourceWidth;
    my $yscale = $printer->pageRect()->height()/$sourceHeight;
    my $scale = min($xscale, $yscale);

    $painter->translate($printer->paperRect()->x() + $printer->pageRect()->width()/2,
                      $printer->paperRect()->y() + $printer->pageRect()->height()/2);
    $painter->scale($scale, $scale);
    $painter->translate(-$sourceWidth/2, -$sourceHeight/2);

    my $option = Qt::StyleOptionViewItem();
    my $parent = Qt::ModelIndex();

    my $progress = Qt::ProgressDialog(this->tr('Printing...'), this->tr('Cancel'), 0, $rows, this);
    $progress->setWindowModality(Qt::ApplicationModal());
    my $y = PixelDelegate::ItemSize/2;

    for (my $row = 0; $row < $rows; ++$row) {
        $progress->setValue($row);
        qApp->processEvents();
        if ($progress->wasCanceled()) {
            last;
        }

        my $x = PixelDelegate::ItemSize/2;

        for (my $column = 0; $column < $columns; ++$column) {
            $option->rect = Qt::Rect(int($x), int($y), PixelDelegate::ItemSize, PixelDelegate::ItemSize);
            view->itemDelegate()->paint($painter, $option,
                                        model->index($row, $column, $parent));
            $x = $x + PixelDelegate::ItemSize;
        }
        $y = $y + PixelDelegate::ItemSize;
    }
    $progress->setValue($rows);

    $painter->restore();
    $painter->end();

    if ($progress->wasCanceled()) {
        Qt::MessageBox::information(this, this->tr('Printing canceled'),
            this->tr('The printing process was canceled.'), Qt::MessageBox::Cancel());
    }
#else
    #Qt::MessageBox::information(this, this->tr('Printing canceled'), 
        #this->tr('Printing is not supported on this Qt build'), Qt::MessageBox::Cancel());
#endif
}

sub showAboutBox
{
    Qt::MessageBox::about(this, this->tr('About the Pixelator example'),
        this->tr("This example demonstrates how a standard view and a custom\n" .
           "delegate can be used to produce a specialized representation\n" .
           'of data in a simple custom model.'));
}

# [6]
sub updateView
{
    view->resizeColumnsToContents();
    view->resizeRowsToContents();
}
# [6]

1;
