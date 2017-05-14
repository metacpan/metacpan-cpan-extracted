package DiagramTextItem;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::GraphicsTextItem );
use DiagramScene;
use QtCore4::signals
    lostFocus => ['QGraphicsTextItem *'],
    selectedChange => ['QGraphicsItem *'];

use constant { Type => Qt::GraphicsTextItem::UserType() + 3 };

sub type()
    { return Type; }

# [0]
sub NEW
{
    my ($class, $parent, $scene) = @_;
    $class->SUPER::NEW($parent, $scene);
    this->setFlag(Qt::GraphicsItem::ItemIsMovable());
    this->setFlag(Qt::GraphicsItem::ItemIsSelectable());
}
# [0]

# [1]
sub itemChange
{
    my ($change, $value) = @_;
    if ($change == Qt::GraphicsItem::ItemSelectedHasChanged()) {
        emit this->selectedChange(this);
    }
    return $value;
}
# [1]

# [2]
sub focusOutEvent
{
    my ($event) = @_;
    this->setTextInteractionFlags(Qt::NoTextInteraction());
    emit this->lostFocus(this);
    this->SUPER::focusOutEvent($event);
}
# [2]

# [5]
sub mouseDoubleClickEvent
{
    my ($event) = @_;
    if (this->textInteractionFlags() == Qt::NoTextInteraction()) {
        this->setTextInteractionFlags(Qt::TextEditorInteraction());
    }
    this->SUPER::mouseDoubleClickEvent($event);
}
# [5]

1;
