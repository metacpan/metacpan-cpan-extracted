package CircleWidget;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    nextAnimationFrame => [];

sub floatBased() {
    return this->{floatBased};
}

sub antialiased() {
    return this->{antialiased};
}

sub frameNo() {
    return this->{frameNo};
}
# [0]

# [0]
sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{floatBased} = 0;
    this->{antialiased} = 0;
    this->{frameNo} = 0;

    this->setBackgroundRole(Qt::Palette::Base());
    this->setSizePolicy(Qt::SizePolicy::Expanding(), Qt::SizePolicy::Expanding());
}
# [0]

# [1]
sub setFloatBased
{
    my ($floatBased) = @_;
    this->{floatBased} = $floatBased;
    this->update();
}
# [1]

# [2]
sub setAntialiased
{
    my ($antialiased) = @_;
    this->{antialiased} = $antialiased;
    this->update();
}
# [2]

# [3]
sub minimumSizeHint
{
    return Qt::Size(50, 50);
}
# [3]

# [4]
sub sizeHint
{
    return Qt::Size(180, 180);
}
# [4]

# [5]
sub nextAnimationFrame
{
    this->{frameNo}++;
    this->update();
}
# [5]

# [6]
sub paintEvent
{
    my $painter = Qt::Painter(this);
    $painter->setRenderHint(Qt::Painter::Antialiasing(), this->antialiased);
    $painter->translate(this->width() / 2, this->height() / 2);
# [6]

# [7]
    for (my $diameter = 0; $diameter < 256; $diameter += 9) {
        my $delta = abs((this->frameNo % 128) - $diameter / 2);
        my $alpha = 255 - ($delta * $delta) / 4 - $diameter;
# [7] //! [8]
        if ($alpha > 0) {
            $painter->setPen(Qt::Pen(Qt::Brush(Qt::Color(0, $diameter / 2, 127, $alpha)), 3));

            if (this->floatBased) {
                $painter->drawEllipse(Qt::RectF(-$diameter / 2.0, -$diameter / 2.0,
                                           $diameter, $diameter));
            } else {
                $painter->drawEllipse(Qt::Rect(-$diameter / 2, -$diameter / 2,
                                          $diameter, $diameter));
            }
        }
    }
    $painter->end();
}
# [8]

1;
