package Mouse;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::GraphicsItem );
use Math::Trig;

sub angle() {
    return this->{angle};
}

sub setAngle($) {
    return this->{angle} = shift;
}

sub speed() {
    return this->{speed};
}

sub setSpeed($) {
    return this->{speed} = shift;
}

sub mouseEyeDirection() {
    return this->{mouseEyeDirection};
}

sub setMouseEyeDirection($) {
    return this->{mouseEyeDirection} = shift;
}

sub color() {
    return this->{color};
}

sub setColor($) {
    return this->{color} = shift;
}

# [0]

my $Pi = 3.14159265358979323846264338327950288419717;
my $TwoPi = 2.0 * $Pi;
use constant { RAND_MAX => 2147483647 };

sub normalizeAngle
{
    my ($angle) = @_;
    while ($angle < 0) {
        $angle += $TwoPi;
    }
    while ($angle > $TwoPi) {
        $angle -= $TwoPi;
    }
    return $angle;
}

# [0]
sub NEW
{
    my ( $class ) = @_;
    $class->SUPER::NEW();
    this->setAngle(0);
    this->setSpeed(0);
    this->setMouseEyeDirection(0);
    this->setColor(Qt::Color(rand(RAND_MAX) % 256, rand(RAND_MAX) % 256, rand(RAND_MAX) % 256));
    this->setRotation(rand(RAND_MAX) % (360 * 16));
}
# [0]

# [1]
sub boundingRect
{
    my $adjust = 0.5;
    return Qt::RectF(-18 - $adjust, -22 - $adjust,
                  36 + $adjust, 60 + $adjust);
}
# [1]

# [2]
sub shape
{
    my $path = Qt::PainterPath();
    $path->addRect(-10, -20, 20, 40);
    return $path;
}
# [2]

# [3]
sub paint
{
    my ($painter) = @_;
    # Body
    $painter->setBrush(Qt::Brush(this->color));
    $painter->drawEllipse(-10, -20, 20, 40);

    # Eyes
    $painter->setBrush(Qt::white());
    $painter->drawEllipse(-10, -17, 8, 8);
    $painter->drawEllipse(2, -17, 8, 8);

    # Nose
    $painter->setBrush(Qt::black());
    $painter->drawEllipse(Qt::RectF(-2, -22, 4, 4));

    # Pupils
    $painter->drawEllipse(Qt::RectF(-8.0 + this->mouseEyeDirection, -17, 4, 4));
    $painter->drawEllipse(Qt::RectF(4.0 + this->mouseEyeDirection, -17, 4, 4));

    # Ears
    my $isColliding = this->scene()->collidingItems(this);
    $painter->setBrush(ref $isColliding eq 'ARRAY' && scalar @{$isColliding} == 0 ?
        Qt::Brush( Qt::darkYellow() ) :
        Qt::Brush( Qt::red()));
    $painter->drawEllipse(-17, -12, 16, 16);
    $painter->drawEllipse(1, -12, 16, 16);

    # Tail
    my $path = Qt::PainterPath(Qt::PointF(0, 20));
    $path->cubicTo(-5, 22, -5, 22, 0, 25);
    $path->cubicTo(5, 27, 5, 32, 0, 30);
    $path->cubicTo(-5, 32, -5, 42, 0, 35);
    $painter->setBrush(Qt::NoBrush());
    $painter->drawPath($path);
}
# [3]

# [4]
sub advance
{
    my ($step) = @_;
    if (!$step) {
        return;
    }

# [4]
    # Don't move too far away
# [5]
    my $lineToCenter = Qt::LineF(Qt::PointF(0, 0), this->mapFromScene(0, 0));
    if ($lineToCenter->length() > 150) {
        my $angleToCenter = acos($lineToCenter->dx() / $lineToCenter->length());
        if ($lineToCenter->dy() < 0) {
            $angleToCenter = $TwoPi - $angleToCenter;
        }
        $angleToCenter = normalizeAngle(($Pi - $angleToCenter) + $Pi / 2);

        if ($angleToCenter < $Pi && $angleToCenter > $Pi / 4) {
            # Rotate left
            this->{angle} += (this->angle < -$Pi / 2) ? 0.25 : -0.25;
        } elsif ($angleToCenter >= $Pi && $angleToCenter < ($Pi + $Pi / 2 + $Pi / 4)) {
            # Rotate right
            this->{angle} += (this->{angle} < $Pi / 2) ? 0.25 : -0.25;
        }
    } elsif (sin(this->angle) < 0) {
        this->{angle} += 0.25;
    } elsif (sin(this->angle) > 0) {
        this->{angle} -= 0.25;
# [5] #! [6]
    }
# [6]

    # Try not to crash with any other mice
# [7]
    my $pgon = Qt::PolygonF( [
        this->mapToScene(0, 0),
        this->mapToScene(-30, -50),
        this->mapToScene(30, -50)
    ] );
    my $dangerMice = this->scene->items( $pgon );

    foreach my $item ( @{$dangerMice} ) {
        if ($item == this) {
            next;
        }
        
        my $lineToMouse = Qt::LineF(Qt::PointF(0, 0), this->mapFromItem($item, 0, 0));
        my $angleToMouse = acos($lineToMouse->dx() / $lineToMouse->length());
        if ($lineToMouse->dy() < 0) {
            $angleToMouse = $TwoPi - $angleToMouse;
        }
        $angleToMouse = this->normalizeAngle(($Pi - $angleToMouse) + $Pi / 2);

        if ($angleToMouse >= 0 && $angleToMouse < $Pi / 2) {
            # Rotate right
            this->{angle} += 0.5;
        } elsif ($angleToMouse <= $TwoPi && $angleToMouse > ($TwoPi - $Pi / 2)) {
            # Rotate left
            this->{angle} -= 0.5;
# [7] #! [8]
        }
# [8] #! [9]
    }
# [9]

    # Add some random movement
# [10]
    if (scalar @{$dangerMice} > 1 && (rand(RAND_MAX) % 10) == 0) {
        if (rand(RAND_MAX) % 1) {
            this->{angle} += (rand(RAND_MAX) % 100) / 500.0;
        }
        else {
            this->{angle} -= (rand(RAND_MAX) % 100) / 500.0;
        }
    }
# [10]

# [11]
    this->{speed} += (-50 + rand(RAND_MAX) % 100) / 100.0;

    my $dx = sin(this->angle) * 10;
    this->{mouseEyeDirection} = (abs($dx / 5) < 1) ? 0 : $dx / 5;

    this->rotate($dx);
    this->setPos(this->mapToParent(0, -(3 + sin(this->speed) * 3)));
}
# [11]

1;
