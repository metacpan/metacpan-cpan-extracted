package MainWindow;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::MainWindow );
use ArrowPad;

sub arrowPad() {
    return this->{arrowPad};
}

sub fileMenu() {
    return this->{fileMenu};
}

sub exitAct() {
    return this->{exitAct};
}

sub NEW
{
    my ($class) = @_;
    $class->SUPER::NEW();
# [0]
    this->{arrowPad} = ArrowPad();
# [0]
    this->setCentralWidget(this->arrowPad);

# [1]
    this->{exitAct} = Qt::Action(MainWindow::tr("E&xit"), this);
    this->exitAct->setShortcut(MainWindow::tr("Ctrl+Q"));
    this->connect(this->exitAct, SIGNAL 'triggered()', this, SLOT 'close()');
# [1]

    this->{fileMenu} = this->menuBar()->addMenu(MainWindow::tr("&File"));
    this->fileMenu->addAction(this->exitAct);
}

1;
