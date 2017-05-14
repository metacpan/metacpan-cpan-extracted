package SplashItem;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::GraphicsWidget );
use QtCore4::slots
    setValue => ['qreal'];

sub timeLine() {
    return this->{timeLine};
}

sub text() {
    return this->{text};
}

sub opacity() {
    return this->{opacity};
}

sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW( $parent );
    this->{opacity} = 1.0;

    
    this->{timeLine} = Qt::TimeLine(350);
    timeLine->setCurveShape(Qt::TimeLine::EaseInCurve());
    this->connect(timeLine, SIGNAL 'valueChanged(qreal)', this, SLOT 'setValue(qreal)');

    this->{text} = this->tr('Welcome to the Pad Navigator Example. You can use the' .
              ' keyboard arrows to navigate the icons, and press enter' .
              ' to activate an item. Please press any key to continue.');
    resize(400, 175);
}

sub paint
{
    my ($painter) = @_;
    $painter->setOpacity(opacity);
    $painter->setPen(Qt::Pen(Qt::Brush(Qt::Color(Qt::black())), 2));
    $painter->setBrush(Qt::Brush(Qt::Color(245, 245, 255, 220)));
    $painter->setClipRect(rect());
    $painter->drawRoundRect(3, -100 + 3, 400 - 6, 250 - 6);

    my $textRect = rect()->adjusted(10, 10, -10, -10);
    my $flags = Qt::AlignTop() | Qt::AlignLeft() | Qt::TextWordWrap();

    my $font = Qt::Font();
    $font->setPixelSize(18);
    $painter->setPen(Qt::black());
    $painter->setFont($font);
    $painter->drawText($textRect, $flags, text);
}

sub keyPressEvent
{
    if (timeLine->state() == Qt::TimeLine::NotRunning()) {
        timeLine->start();
    }
}

sub setValue
{
    my ($value) = @_;
    this->{opacity} = 1 - $value;
    setPos(x(), scene()->sceneRect()->top() - rect()->height() * $value);
    if ($value == 1) {
        hide();
    }
}

1;
