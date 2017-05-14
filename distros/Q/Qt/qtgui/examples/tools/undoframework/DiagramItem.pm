package DiagramItem;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::GraphicsPolygonItem );
use Qt::GlobalSpace qw( qrand );
use constant { Type => Qt::GraphicsPolygonItem::UserType() + 1 };
use constant { Box => 00, Triangle => 01 };

sub type { return Type; }

sub boxPolygon() {
    return this->{boxPolygon};
}

sub trianglePolygon() {
    return this->{trianglePolygon};
}

sub diagramType {
    return polygon() == boxPolygon ? Box : Triangle;
}

sub NEW
{

    my ($class, $diagramType, $item, $scene) = @_;
    $class->SUPER::NEW($item, $scene);
    this->{boxPolygon} = Qt::PolygonF();
    this->{trianglePolygon} = Qt::PolygonF();
    if ($diagramType == Box) {
        push @{boxPolygon()}, Qt::PointF(0, 0), Qt::PointF(0, 30), 
            Qt::PointF(30, 30), Qt::PointF(30, 0), Qt::PointF(0, 0);
        setPolygon(boxPolygon());
    } else {
        push @{trianglePolygon()}, Qt::PointF(15, 0), Qt::PointF(30, 30),
            Qt::PointF(0, 30), Qt::PointF(15, 0);
        setPolygon(trianglePolygon);
    }

    my $color = Qt::Color(qrand() % 256,
        qrand() % 256, qrand() % 256);
    my $brush = Qt::Brush($color);
    setBrush($brush);
    setFlag(Qt::GraphicsItem::ItemIsSelectable());
    setFlag(Qt::GraphicsItem::ItemIsMovable());
}

1;
