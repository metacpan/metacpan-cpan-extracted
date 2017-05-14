package Arrow;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::GraphicsLineItem );
use Math::Trig;
use constant
    Type => Qt::GraphicsLineItem::UserType() + 4;

sub type() 
    { return Type; }
sub setColor
    { this->{myColor} = shift; }
sub startItem()
    { return this->{myStartItem}; }
sub endItem()
    { return this->{myEndItem}; }

use QtCore4::slots
    updatePosition => [];

sub myColor() {
    return this->{myColor};
}

sub arrowHead() {
    return this->{arrowHead};
}


my $Pi = 3.14;

# [0]
sub NEW
{
    my ($class, $startItem, $endItem, $parent, $scene) = @_;
    $class->SUPER::NEW($parent, $scene);
    this->{myStartItem} = $startItem;
    this->{myEndItem} = $endItem;
    this->setFlag(Qt::GraphicsItem::ItemIsSelectable(), 1);
    this->{myColor} = Qt::black();
    this->setPen(Qt::Pen(Qt::Brush(this->myColor), 2, Qt::SolidLine(), Qt::RoundCap(), Qt::RoundJoin()));
    this->{arrowHead} = Qt::PolygonF();
}
# [0]

# [1]
sub boundingRect
{
    my $extra = (this->pen()->width() + 20) / 2.0;

    return Qt::RectF(this->line()->p1(), Qt::SizeF(this->line()->p2()->x() - this->line()->p1()->x(),
                                      this->line()->p2()->y() - this->line()->p1()->y()))
        ->normalized()
        ->adjusted(-$extra, -$extra, $extra, $extra);
}
# [1]

# [2]
sub shape
{
    my $path = Qt::GraphicsLineItem::shape();
    $path->addPolygon(this->arrowHead);
    return $path;
}
# [2]

# [3]
sub updatePosition
{
    my $line = Qt::LineF(this->mapFromItem(this->startItem, 0, 0), this->mapFromItem(this->endItem, 0, 0));
    this->setLine($line);
}
# [3]

# [4]
sub paint
{
    my ($painter) = @_;
    if (this->startItem->collidesWithItem(this->endItem)) {
        return;
    }

    my $myPen = this->pen();
    $myPen->setColor(Qt::Color(this->myColor));
    my $arrowSize = 20;
    $painter->setPen($myPen);
    $painter->setBrush(Qt::Brush(this->myColor));
# [4] //! [5]

    my $centerLine = Qt::LineF(this->startItem->pos(), this->endItem->pos());
    my $endPolygon = Qt::PolygonF(this->endItem->polygon());
    my $p1 = $endPolygon->[0] + this->endItem->pos();
    my $p2;
    my $intersectPoint = Qt::PointF();
    my $polyLine;
    for (my $i = 1; $i < scalar @{$endPolygon}; ++$i) {
        $p2 = $endPolygon->[$i] + this->endItem->pos();
        $polyLine = Qt::LineF($p1, $p2);
        my $intersectType =
            $polyLine->intersect($centerLine, $intersectPoint);
        if ($intersectType == Qt::LineF::BoundedIntersection()) {
            last;
        }
        $p1 = $p2;
    }

    this->setLine(Qt::LineF($intersectPoint, this->startItem->pos()));
# [5] //! [6]

    my $angle = acos(this->line()->dx() / this->line()->length());
    if (this->line()->dy() >= 0) {
        $angle = ($Pi * 2) - $angle;
    }

    my $arrowP1 = this->line()->p1() + Qt::PointF(sin($angle + $Pi / 3) * $arrowSize,
            cos($angle + $Pi / 3) * $arrowSize);
    my $arrowP2 = this->line()->p1() + Qt::PointF(sin($angle + $Pi - $Pi / 3) * $arrowSize,
            cos($angle + $Pi - $Pi / 3) * $arrowSize);

    this->{arrowHead} = Qt::PolygonF( [ this->line->p1(), $arrowP1, $arrowP2 ] );
# [6] //! [7]
    $painter->drawLine(this->line());
    $painter->drawPolygon(Qt::PolygonF(this->arrowHead));
    if (this->isSelected()) {
        $painter->setPen(Qt::Pen(Qt::Brush(this->myColor), 1, Qt::DashLine()));
        my $myLine = this->line();
        $myLine->translate(0, 4.0);
        $painter->drawLine($myLine);
        $myLine->translate(0,-8.0);
        $painter->drawLine($myLine);
    }
}
# [7]

1;
