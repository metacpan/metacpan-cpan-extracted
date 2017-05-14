package RenderArea;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    setFillRule => ['QFillRule'],
    setFillGradient => ['QColor &', 'QColor &'],
    setPenWidth => ['int'],
    setPenColor => ['QColor &'],
    setRotationAngle => ['int'];
# [0]

# [1]
sub path() {
    return this->{path};
}

sub fillColor1() {
    return this->{fillColor1};
}

sub fillColor2() {
    return this->{fillColor2};
}

sub penWidth() {
    return this->{penWidth};
}

sub penColor() {
    return this->{penColor};
}

sub rotationAngle() {
    return this->{rotationAngle};
}
# [1]

# [0]
sub NEW
{
    my ($class, $path, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{path} = $path;
    this->{penWidth} = 1;
    this->{rotationAngle} = 0;
    this->setBackgroundRole(Qt::Palette::Base());
}
# [0]

# [1]
sub minimumSizeHint
{
    return Qt::Size(50, 50);
}
# [1]

# [2]
sub sizeHint
{
    return Qt::Size(100, 100);
}
# [2]

# [3]
sub setFillRule
{
    my ($rule) = @_;
    this->path->setFillRule($rule);
    this->update();
}
# [3]

# [4]
sub setFillGradient
{
    my ($color1, $color2) = @_;
    this->{fillColor1} = $color1;
    this->{fillColor2} = $color2;
    this->update();
}
# [4]

# [5]
sub setPenWidth
{
    my ($width) = @_;
    this->{penWidth} = $width;
    this->update();
}
# [5]

# [6]
sub setPenColor
{
    my ($color) = @_;
    this->{penColor} = $color;
    this->update();
}
# [6]

# [7]
sub setRotationAngle
{
    my ($degrees) = @_;
    this->{rotationAngle} = $degrees;
    this->update();
}
# [7]

# [8]
sub paintEvent
{
    my $painter = Qt::Painter(this);
    $painter->setRenderHint(Qt::Painter::Antialiasing());
# [8] //! [9]
    $painter->scale(this->width() / 100.0, this->height() / 100.0);
    $painter->translate(50.0, 50.0);
    $painter->rotate(-(this->rotationAngle));
    $painter->translate(-50.0, -50.0);

# [9] //! [10]
    my $color = Qt::qVariantValue( this->penColor, 'Qt::Color' );
    $painter->setPen(Qt::Pen(Qt::Brush($color), this->penWidth, Qt::SolidLine(), Qt::RoundCap(),
                        Qt::RoundJoin()));
    my $gradient = Qt::LinearGradient(0, 0, 0, 100);
    my $fillColor1 = this->fillColor1->value();
    my $fillColor2 = this->fillColor2->value();
    $gradient->setColorAt(0.0, $fillColor1);
    $gradient->setColorAt(1.0, $fillColor2);
    $painter->setBrush(Qt::Brush($gradient));
    $painter->drawPath(this->path);
    $painter->end();
}
# [10]

1;
