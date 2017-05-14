package DisplayWidget;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [DisplayWidget class definition]
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    setBackground => ['int'],
    setColor => ['const Qt::Color &'],
    setShape => ['int'];

use constant { House => 0, Car => 1 };
use constant { Sky => 0, Trees => 1, Road => 2 };
sub background() {
    return this->{background};
}

sub shapeColor() {
    return this->{shapeColor};
}

sub shape() {
    return this->{shape};
}

sub shapeMap() {
    return this->{shapeMap};
}

sub moon() {
    return this->{moon};
}

sub tree() {
    return this->{tree};
}
# [DisplayWidget class definition]

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    my $car = Qt::PainterPath();
    my $house = Qt::PainterPath();
    this->{tree} = Qt::PainterPath();
    this->{moon} = Qt::PainterPath();

    my $file = Qt::File('resources/shapes.dat');
    $file->open(Qt::File::ReadOnly());
    my $stream = Qt::DataStream($file);
    no warnings qw(void);
    $stream >> $car >> $house >> this->{tree} >> this->{moon};
    use warnings;
    $file->close();

    this->{shapeMap} = {
        Car() => $car,
        House() => $house
    };

    this->{background} = Sky;
    this->{shapeColor} = Qt::Color(Qt::darkYellow());
    this->{shape} = House;
}

# [paint event]
sub paintEvent
{
    my ($event) = @_;
    my $painter = Qt::Painter();
    $painter->begin(this);
    $painter->setRenderHint(Qt::Painter::Antialiasing());
    this->paint($painter);
    $painter->end();
}
# [paint event]

# [paint function]
sub paint
{
    my ($painter) = @_;
#[paint picture]
    $painter->setClipRect(Qt::Rect(0, 0, 200, 200));
    $painter->setPen(Qt::NoPen());

    if (this->background == Trees)
    {
        $painter->fillRect(Qt::Rect(0, 0, 200, 200), Qt::Color(Qt::darkGreen()));
        $painter->setBrush(Qt::Brush(Qt::Color(Qt::green())));
        $painter->setPen(Qt::black());
        for (my $y = -55, my $row = 0; $y < 200; $y += 50, ++$row) {
            my $xs;
            if ($row == 2 || $row == 3) {
                $xs = 150;
            }
            else {
                $xs = 50;
            }
            for (my $x = 0; $x < 200; $x += $xs) {
                $painter->save();
                $painter->translate($x, $y);
                $painter->drawPath(this->tree);
                $painter->restore();
            }
        }
    }
    elsif (this->background == Road) {
        $painter->fillRect(Qt::Rect(0, 0, 200, 200), Qt::Color(Qt::gray()));
        $painter->setPen(Qt::Pen(Qt::Brush(Qt::Color(Qt::white())), 4, Qt::DashLine()));
        $painter->drawLine(Qt::Line(0, 35, 200, 35));
        $painter->drawLine(Qt::Line(0, 165, 200, 165));
    }
    else {
        $painter->fillRect(Qt::Rect(0, 0, 200, 200), Qt::Color(Qt::darkBlue()));
        $painter->translate(145, 10);
        $painter->setBrush(Qt::Brush(Qt::Color(Qt::white())));
        $painter->drawPath(this->moon);
        $painter->translate(-145, -10);
    }

    $painter->setBrush(Qt::Brush(this->shapeColor));
    $painter->setPen(Qt::black());
    $painter->translate(100, 100);
    $painter->drawPath(this->shapeMap->{this->shape});
#[paint picture]
}
# [paint function]

sub color
{
    return this->shapeColor;
}

sub setBackground
{
    my ($background) = @_;
    this->{background} = $background;
    this->update();
}

sub setColor
{
    my ($color) = @_;
    this->{shapeColor} = $color;
    this->update();
}

sub setShape
{
    my ($shape) = @_;
    this->{shape} = $shape;
    this->update();
}

1;
