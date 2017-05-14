package RobotPart;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::GraphicsItem );

sub pixmap() {
    return this->{pixmap};
}

sub color() {
    return this->{color};
}

sub dragOver() {
    return this->{dragOver};
}

package RobotHead;

use QtCore4::isa qw( RobotPart );
use constant {
    Type => Qt::GraphicsItem::UserType() + 1
};


package RobotTorso;

use QtCore4::isa qw( RobotPart );

package RobotLimb;

use QtCore4::isa qw( RobotPart );

package RobotPart;

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{color} = Qt::Color(Qt::lightGray());
    this->{dragOver} = 0;
    this->setAcceptDrops(1);
}

sub dragEnterEvent
{
    my ($event) = @_;
    if ($event->mimeData()->hasColor()
        || (this->isa('RobotHead') && $event->mimeData()->hasImage())) {
        $event->setAccepted(1);
        this->{dragOver} = 1;
        this->update();
    } else {
        $event->setAccepted(0);
    }
}

sub dragLeaveEvent
{
    this->{dragOver} = 0;
    this->update();
}

sub dropEvent
{
    my ($event) = @_;
    this->{dragOver} = 0;
    if ($event->mimeData()->hasColor()) {
        this->{color} = $event->mimeData()->colorData()->value();
    }
    elsif (event->mimeData()->hasImage()) {
        this->{pixmap} = $event->mimeData()->imageData()->value();
    }
    this->update();
}

package RobotHead;

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{pixmap} = Qt::Pixmap();
}

sub boundingRect
{
    return Qt::RectF(-15, -50, 30, 50);
}

sub paint
{
    my ($painter) = @_;
    if (this->pixmap->isNull()) {
        $painter->setBrush(this->dragOver ? Qt::Brush(this->color->light(130)) : Qt::Brush(this->color));
        $painter->drawRoundedRect(-10, -30, 20, 30, 25, 25, Qt::RelativeSize());
        $painter->setBrush(Qt::Brush(Qt::white()));
        $painter->drawEllipse(-7, -3 - 20, 7, 7);
        $painter->drawEllipse(0, -3 - 20, 7, 7);
        $painter->setBrush(Qt::Brush(Qt::black()));
        $painter->drawEllipse(-5, -1 - 20, 2, 2);
        $painter->drawEllipse(2, -1 - 20, 2, 2);
        $painter->setPen(Qt::Pen(Qt::Brush(Qt::Color(Qt::black())), 2));
        $painter->setBrush(Qt::NoBrush());
        $painter->drawArc(-6, -2 - 20, 12, 15, 190 * 16, 160 * 16);
    } else {
        $painter->scale(.2272, .2824);
        $painter->drawPixmap(Qt::PointF(-15 * 4.4, -50 * 3.54), this->pixmap);
    }
}

sub type
{
    return Type;
}

package RobotTorso;

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
}

sub boundingRect
{
    return Qt::RectF(-30, -20, 60, 60);
}

sub paint
{
    my ($painter) = @_;
 
    $painter->setBrush(this->dragOver ? Qt::Brush(this->color->light(130)) : Qt::Brush(this->color));
    $painter->drawRoundedRect(-20, -20, 40, 60, 25, 25, Qt::RelativeSize());
    $painter->drawEllipse(-25, -20, 20, 20);
    $painter->drawEllipse(5, -20, 20, 20);
    $painter->drawEllipse(-20, 22, 20, 20);
    $painter->drawEllipse(0, 22, 20, 20);
}

package RobotLimb;

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
}

sub boundingRect
{
    return Qt::RectF(-5, -5, 40, 10);
}

sub paint
{
    my ($painter) = @_;

    $painter->setBrush(this->dragOver ? Qt::Brush(this->color->light(130)) : Qt::Brush(this->color));
    $painter->drawRoundedRect(this->boundingRect(), 50, 50, Qt::RelativeSize());
    $painter->drawEllipse(-5, -5, 10, 10);
}

package Robot;

use QtCore4::isa qw( RobotPart );
use RobotTorso;
use RobotHead;
use RobotLimb;

sub timeLine() {
    return this->{timeLine};
}


sub NEW
{
    my ($class) = @_;
    $class->SUPER::NEW();
    my $torsoItem = RobotTorso(this);    
    my $headItem = RobotHead($torsoItem);
    my $upperLeftArmItem = RobotLimb($torsoItem);
    my $lowerLeftArmItem = RobotLimb($upperLeftArmItem);
    my $upperRightArmItem = RobotLimb($torsoItem);
    my $lowerRightArmItem = RobotLimb($upperRightArmItem);
    my $upperRightLegItem = RobotLimb($torsoItem);
    my $lowerRightLegItem = RobotLimb($upperRightLegItem);
    my $upperLeftLegItem = RobotLimb($torsoItem);
    my $lowerLeftLegItem = RobotLimb($upperLeftLegItem);
    
    $headItem->setPos(0, -18);
    $upperLeftArmItem->setPos(-15, -10);
    $lowerLeftArmItem->setPos(30, 0);
    $upperRightArmItem->setPos(15, -10);
    $lowerRightArmItem->setPos(30, 0);
    $upperRightLegItem->setPos(10, 32);
    $lowerRightLegItem->setPos(30, 0);
    $upperLeftLegItem->setPos(-10, 32);
    $lowerLeftLegItem->setPos(30, 0);

    this->{timeLine} = Qt::TimeLine();

    my $headAnimation = Qt::GraphicsItemAnimation();
    $headAnimation->setItem($headItem);
    $headAnimation->setTimeLine(this->timeLine);
    $headAnimation->setRotationAt(0, 20);
    $headAnimation->setRotationAt(1, -20);
    $headAnimation->setScaleAt(1, 1.1, 1.1);

    my $upperLeftArmAnimation = Qt::GraphicsItemAnimation();
    $upperLeftArmAnimation->setItem($upperLeftArmItem);
    $upperLeftArmAnimation->setTimeLine(this->timeLine);
    $upperLeftArmAnimation->setRotationAt(0, 190);
    $upperLeftArmAnimation->setRotationAt(1, 180);

    my $lowerLeftArmAnimation = Qt::GraphicsItemAnimation();
    $lowerLeftArmAnimation->setItem($lowerLeftArmItem);
    $lowerLeftArmAnimation->setTimeLine(this->timeLine);
    $lowerLeftArmAnimation->setRotationAt(0, 50);
    $lowerLeftArmAnimation->setRotationAt(1, 10);
    
    my $upperRightArmAnimation = Qt::GraphicsItemAnimation();
    $upperRightArmAnimation->setItem($upperRightArmItem);
    $upperRightArmAnimation->setTimeLine(this->timeLine);
    $upperRightArmAnimation->setRotationAt(0, 300);
    $upperRightArmAnimation->setRotationAt(1, 310);

    my $lowerRightArmAnimation = Qt::GraphicsItemAnimation();
    $lowerRightArmAnimation->setItem($lowerRightArmItem);
    $lowerRightArmAnimation->setTimeLine(this->timeLine);
    $lowerRightArmAnimation->setRotationAt(0, 0);
    $lowerRightArmAnimation->setRotationAt(1, -70);

    my $upperLeftLegAnimation = Qt::GraphicsItemAnimation();
    $upperLeftLegAnimation->setItem($upperLeftLegItem);
    $upperLeftLegAnimation->setTimeLine(this->timeLine);
    $upperLeftLegAnimation->setRotationAt(0, 150);
    $upperLeftLegAnimation->setRotationAt(1, 80);

    my $lowerLeftLegAnimation = Qt::GraphicsItemAnimation();
    $lowerLeftLegAnimation->setItem($lowerLeftLegItem);
    $lowerLeftLegAnimation->setTimeLine(this->timeLine);
    $lowerLeftLegAnimation->setRotationAt(0, 70);
    $lowerLeftLegAnimation->setRotationAt(1, 10);

    my $upperRightLegAnimation = Qt::GraphicsItemAnimation();
    $upperRightLegAnimation->setItem($upperRightLegItem);
    $upperRightLegAnimation->setTimeLine(this->timeLine);
    $upperRightLegAnimation->setRotationAt(0, 40);
    $upperRightLegAnimation->setRotationAt(1, 120);
    
    my $lowerRightLegAnimation = Qt::GraphicsItemAnimation();
    $lowerRightLegAnimation->setItem($lowerRightLegItem);
    $lowerRightLegAnimation->setTimeLine(this->timeLine);
    $lowerRightLegAnimation->setRotationAt(0, 10);
    $lowerRightLegAnimation->setRotationAt(1, 50);
    
    my $torsoAnimation = Qt::GraphicsItemAnimation();
    $torsoAnimation->setItem($torsoItem);
    $torsoAnimation->setTimeLine(this->timeLine);
    $torsoAnimation->setRotationAt(0, 5);
    $torsoAnimation->setRotationAt(1, -20);

    this->timeLine->setUpdateInterval(1000 / 25);
    this->timeLine->setCurveShape(Qt::TimeLine::SineCurve());
    this->timeLine->setLoopCount(0);
    this->timeLine->setDuration(2000);
    this->timeLine->start();
}

sub boundingRect
{
    return Qt::RectF();
}

sub paint
{
}

1;
