package Edge;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use Node;
use QtCore4::isa qw( Qt::GraphicsItem );
use constant { Type => Qt::GraphicsItem::UserType() + 2 };
use Math::Trig qw(acos);
sub type() { return Type; }
    
sub dest() {
    return this->{dest};
}

sub sourcePoint() {
    return this->{sourcePoint};
}

sub destPoint() {
    return this->{destPoint};
}

sub arrowSize() {
    return this->{arrowSize};
}

use constant {
    Pi => 3.14159265358979323846264338327950288419717
};
use constant {
    TwoPi => 2.0 * Pi
};

sub NEW {
    my ($class, $sourceNode, $destNode) = @_;
    $class->SUPER::NEW();
    this->{arrowSize} = 10;
    this->setAcceptedMouseButtons(Qt::NoButton());
    this->{source} = $sourceNode;
    this->{dest} = $destNode;
    this->{source}->addEdge(this);
    this->{dest}->addEdge(this);
    this->adjust();
}

sub sourceNode
{
    return this->{source};
}

sub source
{
    return this->{source};
}

sub setSourceNode
{
    my ($node) = @_;
    this->{source} = $node;
    this->adjust();
}

sub destNode
{
    return this->{dest};
}

sub setDestNode
{
    my ($node) = @_;
    this->{dest} = $node;
    this->adjust();
}

sub adjust
{
    if (!this->source || !this->dest) {
        return;
    }

    my $line = Qt::LineF(this->mapFromItem(this->source, 1, 0), this->mapFromItem(this->dest, 0, 0));
    my $length = $line->length();

    this->prepareGeometryChange();

    if ($length > 20) {
        my $edgeOffset = Qt::PointF(($line->dx() * 10) / $length, ($line->dy() * 10) / $length);
        this->{sourcePoint} = $line->p1() + $edgeOffset;
        this->{destPoint} = $line->p2() - $edgeOffset;
    } else {
        this->{sourcePoint} = this->{destPoint} = $line->p1();
    }
}

sub boundingRect
{
    if (!this->source || !this->dest) {
        return Qt::RectF();
    }

    my $penWidth = 1;
    my $extra = ($penWidth + this->arrowSize) / 2.0;

    return Qt::RectF(this->sourcePoint, Qt::SizeF(this->destPoint->x() - this->sourcePoint->x(),
                                      this->destPoint->y() - this->sourcePoint->y()))
        ->normalized()
        ->adjusted(-$extra, -$extra, $extra, $extra);
}

sub paint
{
    my ($painter) = @_;
    if (!this->source || !this->dest) {
        return;
    }

    my $line = Qt::LineF(this->sourcePoint, this->destPoint);
    if (sprintf( '%02f', $line->length() ) == 0) {
        return;
    }

    # Draw the line itself
    $painter->setPen(Qt::Pen(Qt::Brush(Qt::Color(Qt::black())), 1, Qt::SolidLine(), Qt::RoundCap(), Qt::RoundJoin()));
    $painter->drawLine($line);

    # Draw the arrows
    my $angle = Math::Trig::acos($line->dx() / $line->length());
    if ($line->dy() >= 0) {
        $angle = TwoPi - $angle;
    }

    my $sourceArrowP1 = this->sourcePoint + Qt::PointF(sin($angle + Pi / 3) * this->arrowSize,
                                                  cos($angle + Pi / 3) * this->arrowSize);
    my $sourceArrowP2 = this->sourcePoint + Qt::PointF(sin($angle + Pi - Pi / 3) * this->arrowSize,
                                                  cos($angle + Pi - Pi / 3) * this->arrowSize);   
    my $destArrowP1 = this->destPoint + Qt::PointF(sin($angle - Pi / 3) * this->arrowSize,
                                              cos($angle - Pi / 3) * this->arrowSize);
    my $destArrowP2 = this->destPoint + Qt::PointF(sin($angle - Pi + Pi / 3) * this->arrowSize,
                                              cos($angle - Pi + Pi / 3) * this->arrowSize);

    $painter->setBrush(Qt::Brush(Qt::black()));
    $painter->drawPolygon(Qt::PolygonF([ $line->p1(), $sourceArrowP1, $sourceArrowP2 ]));
    $painter->drawPolygon(Qt::PolygonF([ $line->p2(), $destArrowP1, $destArrowP2 ]));
}

1;
