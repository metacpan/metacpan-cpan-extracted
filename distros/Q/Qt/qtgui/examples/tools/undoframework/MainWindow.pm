package MainWindow;

use strict;
use warnings;
use QtCore4;
use QtGui4;

# [0]
use QtCore4::isa qw( Qt::MainWindow );
use QtCore4::slots
    itemMoved => ['QGraphicsPolygonItem *', 'const QPointF &'],
    deleteItem => [],
    addBox => [],
    addTriangle => [],
    about => [],
    itemMenuAboutToShow => [],
    itemMenuAboutToHide => [];

use MainWindow;
use DiagramScene;
use DiagramItem;
use Commands;
use MoveCommand;
use DeleteCommand;
use AddCommand;

sub deleteAction() {
    return this->{deleteAction};
}

sub addBoxAction() {
    return this->{addBoxAction};
}

sub addTriangleAction() {
    return this->{addTriangleAction};
}

sub undoAction() {
    return this->{undoAction};
}

sub redoAction() {
    return this->{redoAction};
}

sub exitAction() {
    return this->{exitAction};
}

sub aboutAction() {
    return this->{aboutAction};
}

sub fileMenu() {
    return this->{fileMenu};
}

sub editMenu() {
    return this->{editMenu};
}

sub itemMenu() {
    return this->{itemMenu};
}

sub helpMenu() {
    return this->{helpMenu};
}

sub diagramScene() {
    return this->{diagramScene};
}

sub undoStack() {
    return this->{undoStack};
}

sub undoView() {
    return this->{undoView};
}

sub rootUndoCommand{
    return this->{rootUndoCommand};
}

# [0]
sub NEW
{
    my ($class) = @_;
    $class->SUPER::NEW();
    this->{undoStack} = Qt::UndoStack();
    this->{rootUndoCommand} = Qt::UndoCommand();

    createActions();
    createMenus();

    createUndoView();

    this->{diagramScene} = DiagramScene();
    my $pixmapBrush = Qt::Brush(Qt::Pixmap(':/images/cross.png')->scaled(30, 30));
    diagramScene->setBackgroundBrush($pixmapBrush);
    diagramScene->setSceneRect(Qt::RectF(0, 0, 500, 500));

    this->connect(diagramScene, SIGNAL 'itemMoved(QGraphicsPolygonItem*,QPointF)',
            this, SLOT 'itemMoved(QGraphicsPolygonItem*,QPointF)');

    setWindowTitle('Undo Framework');
    my $view = Qt::GraphicsView(diagramScene);
    setCentralWidget($view);
    resize(700, 500);
}
# [0]

# [1]
sub createUndoView
{
    this->{undoView} = Qt::UndoView(undoStack);
    undoView->setWindowTitle(this->tr('Command List'));
    undoView->show();
    undoView->setAttribute(Qt::WA_QuitOnClose(), 0);
}
# [1]

# [2]
sub createActions
{
    this->{deleteAction} = Qt::Action(this->tr('&Delete Item'), this);
    deleteAction->setShortcut(Qt::KeySequence(this->tr('Del')));
    this->connect(deleteAction, SIGNAL 'triggered()', this, SLOT 'deleteItem()');
# [2] //! [3]

# [3] //! [4]
    this->{addBoxAction} = Qt::Action(this->tr('Add &Box'), this);
# [4]
    addBoxAction->setShortcut(Qt::KeySequence(this->tr('Ctrl+O')));
    this->connect(addBoxAction, SIGNAL 'triggered()', this, SLOT 'addBox()');

    this->{addTriangleAction} = Qt::Action(this->tr('Add &Triangle'), this);
    addTriangleAction->setShortcut(Qt::KeySequence(this->tr('Ctrl+T')));
    this->connect(addTriangleAction, SIGNAL 'triggered()', this, SLOT 'addTriangle()');

# [5]
    this->{undoAction} = undoStack->createUndoAction(this, this->tr('&Undo'));
    undoAction->setShortcut(Qt::KeySequence(Qt::KeySequence::Undo()));

    this->{redoAction} = undoStack->createRedoAction(this, this->tr('&Redo'));
    redoAction->setShortcut(Qt::KeySequence(Qt::KeySequence::Redo()));
# [5]

    this->{exitAction} = Qt::Action(this->tr('E&xit'), this);
    exitAction->setShortcut(Qt::KeySequence(Qt::KeySequence::Quit()));
    this->connect(exitAction, SIGNAL 'triggered()', this, SLOT 'close()');

    this->{aboutAction} = Qt::Action(this->tr('&About'), this);
    my @aboutShortcuts = (
        Qt::KeySequence( this->tr('Ctrl+A') ),
        Qt::KeySequence( this->tr('Ctrl+B') )
    );
    aboutAction->setShortcuts(\@aboutShortcuts);
    this->connect(aboutAction, SIGNAL 'triggered()', this, SLOT 'about()');
}

# [6]
sub createMenus
{
# [6]
    this->{fileMenu} = menuBar()->addMenu(this->tr('&File'));
    fileMenu->addAction(exitAction);

# [7]
    this->{editMenu} = menuBar()->addMenu(this->tr('&Edit'));
    editMenu->addAction(undoAction);
    editMenu->addAction(redoAction);
    editMenu->addSeparator();
    editMenu->addAction(deleteAction);
    this->connect(editMenu, SIGNAL 'aboutToShow()',
            this, SLOT 'itemMenuAboutToShow()');
    this->connect(editMenu, SIGNAL 'aboutToHide()',
            this, SLOT 'itemMenuAboutToHide()');

# [7]
    this->{itemMenu} = menuBar()->addMenu(this->tr('&Item'));
    itemMenu->addAction(addBoxAction);
    itemMenu->addAction(addTriangleAction);

    this->{helpMenu} = menuBar()->addMenu(this->tr('&About'));
    helpMenu->addAction(aboutAction);
# [8]
}
# [8]

# [9]
sub itemMoved
{
    my ($movedItem, $oldPosition) = @_;
    undoStack->push(MoveCommand($movedItem, $oldPosition, rootUndoCommand));
}
# [9]

# [10]
sub deleteItem
{
    if (!scalar @{diagramScene->selectedItems()}) {
        return;
    }

    my $deleteCommand = DeleteCommand(diagramScene, rootUndoCommand);
    undoStack->push($deleteCommand);
}
# [10]

# [11]
sub itemMenuAboutToHide
{
    deleteAction->setEnabled(1);
}
# [11]

# [12]
sub itemMenuAboutToShow
{
    deleteAction->setEnabled(scalar @{diagramScene->selectedItems()} > 0);
}
# [12]

# [13]
sub addBox
{
    my $addCommand = AddCommand(DiagramItem::Box, diagramScene, rootUndoCommand);
    undoStack->push($addCommand);
}
# [13]

# [14]
sub addTriangle
{
    my $addCommand = AddCommand(DiagramItem::Triangle, diagramScene, rootUndoCommand);
    undoStack->push($addCommand);
}
# [14]

# [15]
sub about
{
    Qt::MessageBox::about(this, this->tr('About Undo'),
                       this->tr('The <b>Undo</b> example demonstrates how to ' .
                          'use Qt\'s undo framework.'));
}
# [15]

1;
