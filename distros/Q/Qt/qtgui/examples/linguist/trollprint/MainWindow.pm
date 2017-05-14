package MainWindow;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::MainWindow );
use QtCore4::slots
    about => [];
use PrintPanel;

sub printPanel() {
    return this->{printPanel};
}

sub fileMenu() {
    return this->{fileMenu};
}

sub helpMenu() {
    return this->{helpMenu};
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

sub NEW
{
    my ($class) = @_;
    $class->SUPER::NEW();

    this->{printPanel} = PrintPanel();
    this->setCentralWidget(this->printPanel);

    this->createActions();
    this->createMenus();

# [0]
    this->setWindowTitle(MainWindow::tr("Troll Print 1.0"));
# [0]
}

sub about
{
    Qt::MessageBox::information(this, MainWindow::tr("About Troll Print 1.0"),
                      MainWindow::tr("Troll Print 1.0.\n\n" .
                      "Copyright 1999 Software, Inc."));
}

# [1]
sub createActions
{
# [2]
    this->{exitAct} = Qt::Action(MainWindow::tr("E&xit"), this);
    this->exitAct->setShortcut(MainWindow::tr("Ctrl+Q", "Quit"));
# [2]
    this->connect(this->exitAct, SIGNAL 'triggered()', this, SLOT 'close()');

    this->{aboutAct} = Qt::Action(MainWindow::tr("&About"), this);
    this->aboutAct->setShortcut(Qt::KeySequence(${Qt::Key_F1()}));
    this->connect(this->aboutAct, SIGNAL 'triggered()', this, SLOT 'about()');

    this->{aboutQtAct} = Qt::Action(MainWindow::tr("About &Qt"), this);
    this->connect(this->aboutQtAct, SIGNAL 'triggered()', qApp, SLOT 'aboutQt()');
}

sub createMenus
# [1] //! [3]
{
    my $fileMenu = this->menuBar()->addMenu(MainWindow::tr("&File"));
    $fileMenu->addAction(this->exitAct);

    this->menuBar()->addSeparator();

    my $helpMenu = this->menuBar()->addMenu(MainWindow::tr("&Help"));
    $helpMenu->addAction(this->aboutAct);
    $helpMenu->addAction(this->aboutQtAct);
}
# [3]

1;
