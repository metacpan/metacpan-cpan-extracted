package RenderArea;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use QtCore4::isa qw( Qt::Widget );
use QtCore4::slots
    setShape => ['int'],
    setPen => ['const QPen &'],
    setBrush => ['const QBrush &'],
    setAntialiased => ['bool'],
    setTransformed => ['bool'];

use constant {
    Line => 1,
    Points => 2,
    Polyline => 3,
    Polygon => 4,
    Rect => 5,
    RoundedRect => 6,
    Ellipse => 7,
    Arc => 8,
    Chord => 9,
    Pie => 10,
    Path => 11,
    Text => 12,
    Pixmap => 13
};

sub shape() {
    return this->{shape};
}

sub pen() {
    return this->{pen};
}

sub brush() {
    return this->{brush};
}

sub antialiased() {
    return this->{antialiased};
}

sub transformed() {
    return this->{transformed};
}

sub pixmap() {
    return this->{pixmap};
}

# [0]
sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->{shap}  = Polygon;
    this->{antialiase} = 0;
    this->{transformed} = 0;
    this->{pixmap} = Qt::Pixmap('images/qt-logo.png');

    this->setBackgroundRole(Qt::Palette::Base());
    this->setAutoFillBackground(1);
}
# [0]

# [1]
sub minimumSizeHint
{
    return Qt::Size(100, 100);
}
# [1]

# [2]
sub sizeHint
{
    return Qt::Size(400, 200);
}
# [2]

# [3]
sub setShape
{
    my ($shape) = @_;
    this->{shape} = $shape;
    this->update();
}
# [3]

# [4]
sub setPen
{
    my ($pen) = @_;
    this->{pen} = $pen;
    this->update();
}
# [4]

# [5]
sub setBrush
{
    my ($brush) = @_;
    this->{brush} = Qt::Brush($brush);
    this->update();
}
# [5]

# [6]
sub setAntialiased
{
    my ($antialiased) = @_;
    this->{antialiased} = $antialiased;
    this->update();
}
# [6]

# [7]
sub setTransformed
{
    my ($transformed) = @_;
    this->{transformed} = $transformed;
    this->update();
}
# [7]

my @points = (
    Qt::Point(10, 80),
    Qt::Point(20, 10),
    Qt::Point(80, 30),
    Qt::Point(90, 70)
);

# [8]
sub paintEvent
{

    my $rect = Qt::Rect(10, 20, 80, 60);

    my $path = Qt::PainterPath();
    $path->moveTo(20, 80);
    $path->lineTo(20, 30);
    $path->cubicTo(80, 0, 50, 50, 80, 80);

    my $startAngle = 20 * 16;
    my $arcLength = 120 * 16;
# [8]

# [9]
    my $painter = Qt::Painter(this);
    $painter->setPen(this->pen);
    $painter->setBrush(this->brush);
    if (this->antialiased) {
        $painter->setRenderHint(Qt::Painter::Antialiasing(), 1);
# [9]
        $painter->translate(+0.5, +0.5);
    }

# [10]
    for (my $x = 0; $x < this->width(); $x += 100) {
        for (my $y = 0; $y < this->height(); $y += 100) {
            $painter->save();
            $painter->translate($x, $y);
# [10] //! [11]
            if (this->transformed) {
                $painter->translate(50, 50);
                $painter->rotate(60.0);
                $painter->scale(0.6, 0.9);
                $painter->translate(-50, -50);
            }
# [11]

# [12]
            if (this->shape == Line) {
                $painter->drawLine($rect->bottomLeft(), $rect->topRight());
            }
            elsif (this->shape == Points) {
                $painter->drawPoints(Qt::Polygon(\@points));
            }
            elsif (this->shape == Polyline) {
                $painter->drawPolyline(Qt::Polygon(\@points));
            }
            elsif (this->shape == Polygon) {
                $painter->drawPolygon(Qt::Polygon(\@points));
            }
            elsif (this->shape == Rect) {
                $painter->drawRect($rect);
            }
            elsif (this->shape == RoundedRect) {
                $painter->drawRoundedRect($rect, 25, 25, Qt::RelativeSize());
            }
            elsif (this->shape == Ellipse) {
                $painter->drawEllipse($rect);
            }
            elsif (this->shape == Arc) {
                $painter->drawArc($rect, $startAngle, $arcLength);
            }
            elsif (this->shape == Chord) {
                $painter->drawChord($rect, $startAngle, $arcLength);
            }
            elsif (this->shape == Pie) {
                $painter->drawPie($rect, $startAngle, $arcLength);
            }
            elsif (this->shape == Path) {
                $painter->drawPath($path);
            }
            elsif (this->shape == Text) {
                $painter->drawText($rect, Qt::AlignCenter(), this->tr("Qt by\nNokia"));
            }
            elsif (this->shape == Pixmap) {
                $painter->drawPixmap(10, 10, pixmap);
            }
# [12] //! [13]
            $painter->restore();
        }
    }

    $painter->setPen(palette()->dark()->color());
    $painter->setBrush(Qt::NoBrush());
    $painter->drawRect(Qt::Rect(0, 0, width() - 1, height() - 1));
    $painter->end();
}
# [13]

1;
