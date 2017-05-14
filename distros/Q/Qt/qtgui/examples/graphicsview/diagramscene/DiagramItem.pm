package DiagramItem;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use Arrow;
use List::MoreUtils qw( firstidx );

# [0]
use QtCore4::isa qw( Qt::GraphicsPolygonItem );

use constant {
    Type => Qt::GraphicsPolygonItem::UserType() + 15,
    Step => 0,
    Conditional => 1,
    StartEnd => 2,
    Io => 3
};

sub diagramType()
    { return this->{myDiagramType}; }
sub polygon()
    { return this->{myPolygon}; }
sub type()
    { return Type;}

sub myContextMenu() {
    return this->{myContextMenu};
}

sub arrows() {
    return this->{arrows};
}

# [0]
sub NEW
{
    my ($class, $diagramType, $contextMenu, $parent, $scene) = @_;

    $class->SUPER::NEW($parent, $scene);
    this->{myDiagramType} = $diagramType;
    this->{myContextMenu} = $contextMenu;

    this->{myPolygon} = Qt::PolygonF();

    my $path = Qt::PainterPath();
    if ( $diagramType == StartEnd ) {
        $path->moveTo(200, 50);
        $path->arcTo(150, 0, 50, 50, 0, 90);
        $path->arcTo(50, 0, 50, 50, 90, 90);
        $path->arcTo(50, 50, 50, 50, 180, 90);
        $path->arcTo(150, 50, 50, 50, 270, 90);
        $path->lineTo(200, 25);
        this->{myPolygon} = $path->toFillPolygon();
    }
    elsif ( $diagramType == Conditional ) {
        #this->{myPolygon} << Qt::PointF(-100, 0) << Qt::PointF(0, 100)
                  #<< Qt::PointF(100, 0) << Qt::PointF(0, -100)
                  #<< Qt::PointF(-100, 0);
        this->{myPolygon} = Qt::PolygonF( [
            Qt::PointF(-100, 0), 
            Qt::PointF(0, 100), 
            Qt::PointF(100, 0), 
            Qt::PointF(0, -100), 
            Qt::PointF(-100, 0),
        ] );
    }
    elsif ( $diagramType == Step ) {
        #this->{myPolygon} << Qt::PointF(-100, -100) << Qt::PointF(100, -100)
                  #<< Qt::PointF(100, 100) << Qt::PointF(-100, 100)
                  #<< Qt::PointF(-100, -100);
        this->{myPolygon} = Qt::PolygonF( [
            Qt::PointF(-100, -100), 
            Qt::PointF(100, -100), 
            Qt::PointF(100, 100), 
            Qt::PointF(-100, 100), 
            Qt::PointF(-100, -100),
        ] );
    }
    else {
        #this->{myPolygon} << Qt::PointF(-120, -80) << Qt::PointF(-70, 80)
                  #<< Qt::PointF(120, 80) << Qt::PointF(70, -80)
                  #<< Qt::PointF(-120, -80);
        this->{myPolygon} = Qt::PolygonF( [
            Qt::PointF(-120, -80), 
            Qt::PointF(-70, 80), 
            Qt::PointF(120, 80), 
            Qt::PointF(70, -80), 
            Qt::PointF(-120, -80),
        ] );
    }
    this->setPolygon(this->{myPolygon});
    this->setFlag(Qt::GraphicsItem::ItemIsMovable(), 1);
    this->setFlag(Qt::GraphicsItem::ItemIsSelectable(), 1);
    this->{arrows} = [];
}
# [0]

# [1]
sub removeArrow
{
    my ($arrow) = @_;
    my $index = firstidx { $_ == $arrow } @{this->arrows};

    if ($index != -1) {
        splice @{this->arrows}, $index, 1;
    }
}
# [1]

# [2]
sub removeArrows
{
    foreach my $arrow ( @{this->arrows} ) {
        $arrow->startItem()->removeArrow($arrow);
        $arrow->endItem()->removeArrow($arrow);
        this->scene()->removeItem($arrow);
    }
}
# [2]

# [3]
sub addArrow
{
    my ($arrow) = @_;
    push @{this->{arrows}}, $arrow;
}
# [3]

# [4]
sub image
{
    my $pixmap = Qt::Pixmap(250, 250);
    $pixmap->fill(Qt::Color(Qt::transparent()));
    my $painter = Qt::Painter($pixmap);
    $painter->setPen(Qt::Pen(Qt::Brush(Qt::black()), 8));
    $painter->translate(125, 125);
    $painter->drawPolyline(this->{myPolygon});

    return $pixmap;
}
# [4]

# [5]
sub contextMenuEvent
{
    my ($event) = @_;
    this->scene()->clearSelection();
    this->setSelected(1);
    this->myContextMenu->exec($event->screenPos());
}
# [5]

# [6]
sub itemChange
{
    my ($change, $value) = @_;
    if ($change == Qt::GraphicsItem::ItemPositionChange()) {
        foreach my $arrow ( @{this->arrows} ) {
            $arrow->updatePosition();
        }
    }

    return $value;
}
# [6]

1;
