package RenderArea;

use strict;
use warnings;
use QtCore4;
use QtGui4;
# [0]
use constant {
    NoTransformation => 0,
    Translate => 1,
    Rotate => 2,
    Scale => 3
};
# [0]

# [1]
use QtCore4::isa qw( Qt::Widget );
# [1]

# [2]
sub operations() {
    return this->{operations};
}

sub shape() {
    return this->{shape};
}

sub xBoundingRect() {
    return this->{xBoundingRect};
}

sub yBoundingRect() {
    return this->{yBoundingRect};
}
# [2]

# [0]
sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    my $newFont = this->font();
    $newFont->setPixelSize(12);
    this->setFont($newFont);

    my $fontMetrics = Qt::FontMetrics($newFont);
    this->{xBoundingRect} = $fontMetrics->boundingRect(this->tr('x'));
    this->{yBoundingRect} = $fontMetrics->boundingRect(this->tr('y'));
    this->{operations} = [];
}
# [0]

# [1]
sub setOperations
{
    my ($operations) = @_;
    # Make sure to copy the array
    this->{operations} = [@{$operations}];
    this->update();
}
# [1]

# [2]
sub setShape
{
    my ($shape) = @_;
    this->{shape} = $shape;
    this->update();
}
# [2]

# [3]
sub minimumSizeHint
{
    return Qt::Size(182, 182);
}
# [3]

# [4]
sub sizeHint
{
    return Qt::Size(232, 232);
}
# [4]

# [5]
sub paintEvent
{
    my ($event) = @_;
    my $painter = Qt::Painter(this);
    $painter->setRenderHint(Qt::Painter::Antialiasing());
    $painter->fillRect($event->rect(), Qt::Brush(Qt::white()));

    $painter->translate(66, 66);
# [5]

# [6]
    $painter->save();
    this->transformPainter($painter);
    this->drawShape($painter);
    $painter->restore();
# [6]

# [7]
    this->drawOutline($painter);
# [7]

# [8]
    this->transformPainter($painter);
    this->drawCoordinates($painter);
    $painter->end();
}
# [8]

# [9]
sub drawCoordinates
{
    my ($painter) = @_;
    $painter->setPen(Qt::Color(Qt::red()));

    $painter->drawLine(0, 0, 50, 0);
    $painter->drawLine(48, -2, 50, 0);
    $painter->drawLine(48, 2, 50, 0);
    $painter->drawText(60 - this->xBoundingRect->width() / 2,
                     0 + this->xBoundingRect->height() / 2, this->tr('x'));

    $painter->drawLine(0, 0, 0, 50);
    $painter->drawLine(-2, 48, 0, 50);
    $painter->drawLine(2, 48, 0, 50);
    $painter->drawText(0 - this->yBoundingRect->width() / 2,
                     60 + this->yBoundingRect->height() / 2, this->tr('y'));
}
# [9]

# [10]
sub drawOutline
{
    my ($painter) = @_;
    $painter->setPen(Qt::darkGreen());
    $painter->setPen(Qt::DashLine());
    $painter->setBrush(Qt::NoBrush());
    $painter->drawRect(0, 0, 100, 100);
}
# [10]

# [11]
sub drawShape
{
    my ($painter) = @_;
    $painter->fillPath(this->shape, Qt::Brush(Qt::blue()));
}
# [11]

# [12]
sub transformPainter
{
    my ($painter) = @_;
    foreach my $operation( @{this->operations} ) {
        if ( $operation == Translate ) {
            $painter->translate(50, 50);
        }
        elsif ( $operation == Scale ) {
            $painter->scale(0.75, 0.75);
        }
        elsif ( $operation == Rotate ) {
            $painter->rotate(60);
        }
    }
}
# [12]

1;
