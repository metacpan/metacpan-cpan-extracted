package MainWindow;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtXml4;
use QtCore4::isa qw( Qt::MainWindow );
use QtCore4::slots
    openFile => [];
use DomModel;

sub model() {
    return this->{model};
}

sub setModel($) {
    return this->{model} = shift;
}

sub fileMenu() {
    return this->{fileMenu};
}

sub setFileMenu($) {
    return this->{fileMenu} = shift;
}

sub xmlPath() {
    return this->{xmlPath};
}

sub setXmlPath($) {
    return this->{xmlPath} = shift;
}

sub view() {
    return this->{view};
}

sub setView($) {
    return this->{view} = shift;
}

sub NEW
{
    my ( $class ) = @_;
    $class->SUPER::NEW();
    this->setFileMenu( this->menuBar()->addMenu(this->tr('&File')) );
    this->fileMenu->addAction(this->tr('&Open...'), this, SLOT 'openFile()',
                        Qt::KeySequence(this->tr('Ctrl+O')));
    this->fileMenu->addAction(this->tr('E&xit'), this, SLOT 'close()',
                        Qt::KeySequence(this->tr('Ctrl+Q')));

    this->setModel( DomModel(Qt::DomDocument(), this) );
    this->setView( Qt::TreeView(this) );
    this->view->setModel(this->model);

    this->setCentralWidget(this->view);
    this->setWindowTitle(this->tr('Simple DOM Model'));
}

sub openFile
{
    my $filePath = Qt::FileDialog::getOpenFileName(this, this->tr('Open File'),
        this->xmlPath, this->tr('XML files (*.xml);;HTML files (*.html);;' .
                    'SVG files (*.svg);;User Interface files (*.ui)'));

    if ($filePath) {
        my $file = Qt::File($filePath);
        if ($file->open(Qt::IODevice::ReadOnly())) {
            my $document = Qt::DomDocument();
            if ($document->setContent($file)) {
                my $newModel = DomModel($document, this);
                this->view->setModel($newModel);
                this->setModel( $newModel );
                this->setXmlPath( $filePath );
            }
            $file->close();
        }
    }
}

1;
