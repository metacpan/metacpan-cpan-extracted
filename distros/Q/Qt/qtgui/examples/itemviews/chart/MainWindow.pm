package MainWindow;

use strict;
use warnings;

use PieView;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::MainWindow );
use QtCore4::slots
    openFile => ['const Qt::String'],
    openFile => [],
    saveFile => [];

sub NEW {
    shift->SUPER::NEW();
    my $fileMenu = Qt::Menu(this->tr('&File'), this);
    my $openAction = $fileMenu->addAction(this->tr('&Open...'));
    $openAction->setShortcut(Qt::KeySequence(this->tr('Ctrl+O')));
    my $saveAction = $fileMenu->addAction(this->tr('&Save As...'));
    $saveAction->setShortcut(Qt::KeySequence(this->tr('Ctrl+S')));
    my $quitAction = $fileMenu->addAction(this->tr('E&xit'));
    $quitAction->setShortcut(Qt::KeySequence(this->tr('Ctrl+Q')));

    setupModel();
    setupViews();

    this->connect($openAction, SIGNAL 'triggered()', this, SLOT 'openFile()');
    this->connect($saveAction, SIGNAL 'triggered()', this, SLOT 'saveFile()');
    this->connect($quitAction, SIGNAL 'triggered()', Qt::qApp, SLOT 'quit()');

    this->menuBar()->addMenu($fileMenu);
    this->statusBar();

    openFile('qtdata.cht');

    this->setWindowTitle(this->tr('Chart'));
    this->resize(870, 550);
}

sub setupModel {
    my $model = Qt::StandardItemModel(8, 2, this);
    this->{model} = $model;
    $model->setHeaderData(0, Qt::Horizontal(), Qt::Variant(Qt::String(this->tr('Label'))));
    $model->setHeaderData(1, Qt::Horizontal(), Qt::Variant(Qt::String(this->tr('Quantity'))));
}

sub setupViews {
    my $splitter = Qt::Splitter();
    my $table = Qt::TableView();
    my $pieChart = PieView();
    my $model = this->{model};
    this->{pieChart} = $pieChart;
    $splitter->addWidget($table);
    $splitter->addWidget($pieChart);
    $splitter->setStretchFactor(0, 0);
    $splitter->setStretchFactor(1, 1);

    $table->setModel($model);
    $pieChart->setModel($model);

    my $selectionModel = Qt::ItemSelectionModel($model);
    this->{selectionModel} = $selectionModel;
    $table->setSelectionModel($selectionModel);
    $pieChart->setSelectionModel($selectionModel);

    my $headerView = $table->horizontalHeader();
    $headerView->setStretchLastSection(1);

    this->setCentralWidget($splitter);
}

sub openFile {
    my ($path) = @_;
    my $fileName;
    my $model = this->{model};
    if (!$path) {
        $fileName = Qt::FileDialog::getOpenFileName(this, this->tr('Choose a data file'),
                                                '', '*.cht');
    }
    else {
        $fileName = $path;
    }

    if ($fileName) {
        my $file = Qt::File($fileName);

        if ($file->open(Qt::File::ReadOnly() | Qt::File::Text())) {
            my $stream = Qt::TextStream($file);
            my $line;

            $model->removeRows(0, $model->rowCount(Qt::ModelIndex()), Qt::ModelIndex());

            my $row = 0;
            do {
                $line = $stream->readLine();
                if ($line) {

                    $model->insertRows($row, 1, Qt::ModelIndex());

                    my @pieces = grep { $_ } split /,/, $line;
                    $model->setData($model->index($row, 0, Qt::ModelIndex()),
                                   Qt::Variant(Qt::String($pieces[0])));
                    $model->setData($model->index($row, 1, Qt::ModelIndex()),
                                   Qt::Variant(Qt::String($pieces[1])));
                    $model->setData($model->index($row, 0, Qt::ModelIndex()),
                                   Qt::qVariantFromValue(Qt::Color(Qt::String($pieces[2]))), Qt::DecorationRole());
                    $row++;
                }
            } while ($line);

            $file->close();
            this->statusBar()->showMessage(this->tr("Loaded $fileName"), 2000);
        }
    }
}

sub saveFile {
    my $model = this->{model};
    my $fileName = Qt::FileDialog::getSaveFileName(this,
        this->tr('Save file as'), '', '*.cht');

    if ($fileName) {
        my $file = Qt::File($fileName);
        my $stream = Qt::TextStream($file);

        if ($file->open(Qt::File::WriteOnly() | Qt::File::Text())) {
            foreach my $row (0..$model->rowCount(Qt::ModelIndex())-1) {

                my @pieces;

                push @pieces, $model->data($model->index($row, 0, Qt::ModelIndex()),
                                          Qt::DisplayRole())->toString();
                push @pieces, $model->data($model->index($row, 1, Qt::ModelIndex()),
                                          Qt::DisplayRole())->toString();
                push @pieces, $model->data($model->index($row, 0, Qt::ModelIndex()),
                                          Qt::DecorationRole())->toString();

                {
                    no warnings qw(void);
                    $stream << join ( ',', @pieces ) . "\n";
                }
            }
        }

        $file->close();
        this->statusBar()->showMessage(this->tr("Saved $fileName"), 2000);
    }
}

1;
