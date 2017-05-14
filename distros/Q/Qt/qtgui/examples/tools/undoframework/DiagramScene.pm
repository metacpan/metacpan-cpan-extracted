package DiagramScene;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::GraphicsScene );
use QtCore4::signals
    itemMoved => ['QGraphicsPolygonItem *', 'const QPointF &'];
use DiagramItem;

sub movingItem() {
    return this->{movingItem};
}

sub oldPos() {
    return this->{oldPos};
}

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{movingItem} = undef;
}

sub mousePressEvent
{
    my ($event) = @_;
    my $mousePos = Qt::PointF($event->buttonDownScenePos(Qt::LeftButton())->x(),
                     $event->buttonDownScenePos(Qt::LeftButton())->y());
    this->{movingItem} = itemAt($mousePos->x(), $mousePos->y());

    if (defined movingItem && $event->button() == Qt::LeftButton()) {
        this->{oldPos} = movingItem->pos();
    }
    
    clearSelection();    
    this->SUPER::mousePressEvent($event);
}

sub mouseReleaseEvent
{
    my ($event) = @_;
    if (defined movingItem && $event->button() == Qt::LeftButton()) {
        if (oldPos != movingItem->pos()) {
            emit itemMoved(movingItem, oldPos);
        }
        this->{movingItem} = undef;
    }
    this->SUPER::mouseReleaseEvent($event);
}

1;
