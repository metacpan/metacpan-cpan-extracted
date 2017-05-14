package MoveCommand;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use DiagramItem;
# [0]
use QtCore4::isa qw( Qt::UndoCommand );
use constant { Id => 1234 };

sub id() { return Id; }

sub myDiagramItem() {
    return this->{myDiagramItem};
}

sub myOldPos() {
    return this->{myOldPos};
}

sub newPos() {
    return this->{newPos};
}

# [0]
sub NEW
{
    my ($class, $diagramItem, $oldPos, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{myDiagramItem} = $diagramItem;
    this->{newPos} = $diagramItem->pos();
    this->{myOldPos} = $oldPos;
}
# [0]

# [1]
sub mergeWith
{
    my ($command) = @_;
    my $moveCommand = $command;
    my $item = $moveCommand->myDiagramItem;

    if (myDiagramItem != $item) {
        return 0;
    }

    this->{newPos} = $item->pos();
    setText(Qt::String( Qt::Object::tr('Move %1') )
        ->arg(CommandsCommon::createCommandString(myDiagramItem, newPos)));

    return 1;
}
# [1]

# [2]
sub undo
{
    myDiagramItem->setPos(myOldPos);
    myDiagramItem->scene()->update();
    setText(Qt::String( Qt::Object::tr('Move %1') )
        ->arg(CommandsCommon::createCommandString(myDiagramItem, newPos)));
}
# [2]

# [3]
sub redo
{
    myDiagramItem->setPos(newPos);
    setText(Qt::String( Qt::Object::tr('Move %1') )
        ->arg(CommandsCommon::createCommandString(myDiagramItem, newPos)));
}
# [3]

package DeleteCommand;

# [1]
use strict;
use warnings;
use QtCore4;
use QtGui4;
use DiagramItem;
use QtCore4::isa qw( Qt::UndoCommand );

sub myDiagramItem() {
    return this->{myDiagramItem};
}

sub myGraphicsScene() {
    return this->{myGraphicsScene};
}

# [1]
# [4]
sub NEW
{
    my ($class, $scene, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{myGraphicsScene} = $scene;
    this->{list} = myGraphicsScene->selectedItems();
    list()->[0]->setSelected(0);
    this->{myDiagramItem} = list()->[0];
    setText(Qt::String( Qt::Object::tr('Delete %1') )
        ->arg(CommandsCommon::createCommandString(myDiagramItem, myDiagramItem->pos())));
}
# [4]

# [5]
sub undo
{
    myGraphicsScene->addItem(myDiagramItem);
    myGraphicsScene->update();
}
# [5]

# [6]
sub redo
{
    myGraphicsScene->removeItem(myDiagramItem);
}
# [6]

package AddCommand;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use DiagramItem;
use QtCore4::isa qw( Qt::UndoCommand );

sub myDiagramItem() {
    return this->{myDiagramItem};
}

sub myGraphicsScene() {
    return this->{myGraphicsScene};
}

sub initialPosition() {
    return this->{initialPosition};
}

# [2]
# [7]
my $itemCount = 0;

sub NEW
{
    my ($class, $addType, $scene, $parent) = @_;
    $class->SUPER::NEW($parent);

    this->{myGraphicsScene} = $scene;
    this->{myDiagramItem} = DiagramItem($addType);
    this->{initialPosition} = Qt::PointF(($itemCount * 15) % int($scene->width()),
                              ($itemCount * 15) % int($scene->height()));
    $scene->update();
    ++$itemCount;
    setText(Qt::String( Qt::Object::tr('Add %1') )
        ->arg(CommandsCommon::createCommandString(myDiagramItem, myDiagramItem->pos())));
}
# [7]

# [8]
sub undo
{
    myGraphicsScene->removeItem(myDiagramItem);
    myGraphicsScene->update();
}
# [8]

# [9]
sub redo
{
    myGraphicsScene->addItem(myDiagramItem);
    myDiagramItem->setPos(initialPosition);
    myGraphicsScene->clearSelection();
    myGraphicsScene->update();
}
# [9]

package CommandsCommon;

use strict;
use warnings;

sub createCommandString
{
    my ($item, $pos) = @_;
    return Qt::String( Qt::Object::tr('%1 at (%2, %3)') )
        ->arg($item->diagramType() == DiagramItem::Box ? 'Box' : 'Triangle')
        ->arg($pos->x())->arg( $pos->y() );
}

1;
