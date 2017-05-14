package Node;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::GraphicsItem );
use GraphWidget;
use List::Util qw( min max );

sub edgeList() {
    return this->{edgeList};
}

sub newPos() {
    return this->{newPos};
}

sub graph() {
    return this->{graph};
}

sub NEW
{
    my ($class, $graphWidget) = @_;
    $class->SUPER::NEW();
    this->{graph} = $graphWidget;
    this->setFlag(Qt::GraphicsItem::ItemIsMovable());
    this->setFlag(Qt::GraphicsItem::ItemSendsGeometryChanges());
    this->setCacheMode(Qt::GraphicsItem::DeviceCoordinateCache());
    this->setZValue(-1);
    this->{edgeList} = [];
}

sub addEdge
{
    my ($edge) = @_;
    push @{this->edgeList}, $edge;
    $edge->adjust();
}

sub edges
{
    return this->edgeList;
}

sub calculateForces
{
    my $mouseGrabberItem = this->scene()->mouseGrabberItem();
    if (!this->scene() || ($mouseGrabberItem && $mouseGrabberItem == this)) {
        this->{newPos} = this->pos();
        return;
    }
    
    # Sum up all forces pushing this item away
    my $xvel = 0;
    my $yvel = 0;
    foreach my $item (@{this->scene()->items()}) {
        my $node = $item;
        if (!$node->isa('Node')) {
            next;
        }

        my $line = Qt::LineF(this->mapFromItem($node, 0, 0), Qt::PointF(0, 0));
        my $dx = $line->dx();
        my $dy = $line->dy();
        my $l = 2.0 * ($dx * $dx + $dy * $dy);
        if ($l > 0) {
            $xvel += ($dx * 150.0) / $l;
            $yvel += ($dy * 150.0) / $l;
        }
    }

    # Now subtract all forces pulling items together
    my $weight = scalar @{this->edgeList} + 1 * 10;
    foreach my $edge (@{this->edgeList}) {
        my $pos;
        if ($edge->sourceNode() == this) {
            $pos = this->mapFromItem($edge->destNode(), 0, 0);
        }
        else {
            $pos = this->mapFromItem($edge->sourceNode(), 0, 0);
        }
        $xvel += $pos->x() / $weight;
        $yvel += $pos->y() / $weight;
    }
 
    if (abs($xvel) < 0.1 && abs($yvel) < 0.1) {
        $xvel = $yvel = 0;
    }

    my $sceneRect = this->scene()->sceneRect();
    this->{newPos} = this->pos() + Qt::PointF($xvel, $yvel);
    this->newPos->setX(min(max(this->newPos->x(), $sceneRect->left() + 10), $sceneRect->right() - 10));
    this->newPos->setY(min(max(this->newPos->y(), $sceneRect->top() + 10), $sceneRect->bottom() - 10));
}

sub advance
{
    if (this->newPos == this->pos()) {
        return 0;
    }

    this->setPos(this->newPos);
    return 1;
}

sub boundingRect
{
    my $adjust = 2;
    return Qt::RectF(-10 - $adjust, -10 - $adjust,
                  23 + $adjust, 23 + $adjust);
}

sub shape
{
    my $path = Qt::PainterPath();
    $path->addEllipse(-10, -10, 20, 20);
    return $path;
}

sub paint
{
    my ($painter, $option) = @_;
    $painter->setPen(Qt::NoPen());
    $painter->setBrush(Qt::Brush(Qt::Color(Qt::darkGray())));
    $painter->drawEllipse(-7, -7, 20, 20);

    my $gradient = Qt::RadialGradient(-3, -3, 10);
    if ($option->state & Qt::Style::State_Sunken()) {
        $gradient->setCenter(3, 3);
        $gradient->setFocalPoint(3, 3);
        $gradient->setColorAt(1, Qt::Color(Qt::yellow())->light(120));
        $gradient->setColorAt(0, Qt::Color(Qt::darkYellow())->light(120));
    } else {
        $gradient->setColorAt(0, Qt::Color(Qt::yellow()));
        $gradient->setColorAt(1, Qt::Color(Qt::darkYellow()));
    }
    $painter->setBrush(Qt::Brush($gradient));
    $painter->setPen(Qt::Pen(Qt::Brush(Qt::Color(Qt::black())), 0));
    $painter->drawEllipse(-10, -10, 20, 20);
}

sub itemChange
{
    my ($change, $value) = @_;
    if ($change == Qt::GraphicsItem::ItemPositionHasChanged()) {
        foreach my $edge (@{this->edgeList}) {
            $edge->adjust();
        }
        this->graph->itemMoved();
    };

    return this->SUPER::itemChange($change, $value);
}

sub mousePressEvent
{
    my ($event) = @_;
    this->update();
    this->SUPER::mousePressEvent($event);
}

sub mouseReleaseEvent
{
    my ($event) = @_;
    this->update();
    this->SUPER::mouseReleaseEvent($event);
}

1;
