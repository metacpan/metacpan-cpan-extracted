package Car;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtDBus4;
use QtCore4::isa qw( Qt::GraphicsItem );
use QtCore4::slots
    accelerate => [],
    decelerate => [],
    turnLeft => [],
    turnRight => [];

use QtCore4::signals
    crashed => [];

sub color() {
    return this->{color};
}

sub wheelsAngle() {
    return this->{wheelsAngle};
}

sub speed() {
    return this->{speed};
}

use constant Pi => 3.14159265358979323846264338327950288419717;

sub boundingRect
{
    return Qt::RectF(-35, -81, 70, 115);
}

sub NEW
{
    my ($class) = @_;
    $class->SUPER::NEW();
    this->{color} = Qt::Color(Qt::green());
    this->{wheelsAngle} = 0;
    this->{speed} = 0;
    this->setFlag(Qt::GraphicsItem::ItemIsMovable(), 1);
    this->setFlag(Qt::GraphicsItem::ItemIsFocusable(), 1);
}

sub accelerate
{
    if (this->speed < 10){
        ++this->{speed};
    }
}

sub decelerate
{
    if (this->speed < 10){
        --(this->{speed});
    }
}

sub turnLeft
{
    if (this->wheelsAngle > -30) {
        this->{wheelsAngle} -= 5;
    }
}

sub turnRight
{
    if (this->wheelsAngle < 30) {
       this->{wheelsAngle} += 5;
    }
}

sub paint
{
    my ($painter) = @_;

    $painter->setBrush(Qt::Brush(Qt::gray()));
    $painter->drawRect(-20, -58, 40, 2); # front axel
    $painter->drawRect(-20, 7, 40, 2); # rear axel

    $painter->setBrush(Qt::Brush(this->color));
    $painter->drawRect(-25, -79, 50, 10); # front wing

    $painter->drawEllipse(-25, -48, 50, 20); # side pods
    $painter->drawRect(-25, -38, 50, 35); # side pods
    $painter->drawRect(-5, 9, 10, 10); # back pod

    $painter->drawEllipse(-10, -81, 20, 100); # main body

    $painter->drawRect(-17, 19, 34, 15); # rear wing

    $painter->setBrush(Qt::Brush(Qt::black()));
    $painter->drawPie(-5, -51, 10, 15, 0, 180 * 16);
    $painter->drawRect(-5, -44, 10, 10); # cocpit

    $painter->save();
    $painter->translate(-20, -58);
    $painter->rotate(this->wheelsAngle);
    $painter->drawRect(-10, -7, 10, 15); # front left
    $painter->restore();

    $painter->save();
    $painter->translate(20, -58);
    $painter->rotate(this->wheelsAngle);
    $painter->drawRect(0, -7, 10, 15); # front left
    $painter->restore();

    $painter->drawRect(-30, 0, 12, 17); # rear left
    $painter->drawRect(19, 0, 12, 17);  # rear right
}

sub timerEvent
{
    my $axelDistance = 54;
    my $wheelsAngleRads = (this->wheelsAngle * Pi) / 180;
    my $turnDistance = cos($wheelsAngleRads) * $axelDistance * 2;
    my $turnRateRads = $wheelsAngleRads / $turnDistance;  # rough estimate
    my $turnRate = ($turnRateRads * 180) / Pi;
    my $rotation = this->speed * $turnRate;
    
    this->rotate($rotation);
    this->translate(0, -(this->speed));
    this->update();
}

1;
