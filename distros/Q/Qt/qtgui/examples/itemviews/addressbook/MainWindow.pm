package MainWindow;

use strict;
use warnings;

use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::MainWindow );
use AddressWidget;

use QtCore4::slots
    updateActions => ['QItemSelection'],
    openFile      => [],
    saveFile      => [];

sub NEW {
    shift->SUPER::NEW(@_);
    my $addressWidget = AddressWidget( undef );
    this->{addressWidget} = $addressWidget;
    this->setCentralWidget($addressWidget);
    createMenus();
    this->setWindowTitle(this->tr('Address Book'));
}

sub createMenus {
    my $addressWidget = this->{addressWidget};
    my $fileMenu = this->menuBar()->addMenu(this->tr("&File"));
    
    my $openAct = Qt::Action(this->tr("&Open..."), this);
    $fileMenu->addAction($openAct);
    this->connect($openAct, SIGNAL 'triggered()',
        this, SLOT 'openFile()');

    my $saveAct = Qt::Action(this->tr("&Save As..."), this);
    $fileMenu->addAction($saveAct);
    this->connect($saveAct, SIGNAL 'triggered()',
        this, SLOT 'saveFile()');

    $fileMenu->addSeparator();

    my $exitAct = Qt::Action(this->tr("E&xit"), this);
    $fileMenu->addAction($exitAct);
    this->connect($exitAct, SIGNAL 'triggered()',
        this, SLOT 'close()');

    my $toolMenu = this->menuBar()->addMenu(this->tr("&Tools"));

    my $addAct = Qt::Action(this->tr("&Add Entry..."), this);
    $toolMenu->addAction($addAct);
    this->connect($addAct, SIGNAL 'triggered()',
        $addressWidget, SLOT 'addEntry()');
    

    my $editAct = Qt::Action(this->tr("&Edit Entry..."), this);
    this->{editAct} = $editAct;
    $editAct->setEnabled(0);
    $toolMenu->addAction($editAct);
    this->connect($editAct, SIGNAL 'triggered()',
        $addressWidget, SLOT 'editEntry()');

    $toolMenu->addSeparator();

    my $removeAct = Qt::Action(this->tr("&Remove Entry"), this);
    this->{removeAct} = $removeAct;
    $removeAct->setEnabled(0);
    $toolMenu->addAction($removeAct);
    this->connect($removeAct, SIGNAL 'triggered()',
        $addressWidget, SLOT 'removeEntry()');

    this->connect($addressWidget, SIGNAL 'selectionChanged(QItemSelection)',
        this, SLOT 'updateActions(QItemSelection)');
}

sub openFile {
    my $fileName = Qt::FileDialog::getOpenFileName(this);
    if ($fileName) {
        this->{addressWidget}->readFromFile($fileName);
    }
}

sub saveFile {
    my $fileName = Qt::FileDialog::getSaveFileName(this);
    if ($fileName) {
        this->{addressWidget}->writeToFile($fileName);
    }
}

sub updateActions {
    my ($selection) = @_;
    my $indexes = $selection->indexes();

    if ( ref $indexes eq 'ARRAY' && @{$indexes} ) {
        this->{removeAct}->setEnabled(1);
        this->{editAct}->setEnabled(1);
    } else {
        this->{removeAct}->setEnabled(0);
        this->{editAct}->setEnabled(0);
    }
}

1;
