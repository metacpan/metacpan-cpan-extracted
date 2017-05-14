package StarRating;

use strict;
use warnings;
use QtCore4;
use QtGui4;

use constant {
    Editable => 0,
    ReadOnly => 1
};

use constant PaintingScaleFactor => 20;

sub new
{
    my ($starCount, $maxStarCount) = (1, 5);
    my ($class) = @_;
    $starCount = $_[1] if defined $_[1];
    $maxStarCount = $_[2] if defined $_[2];
    my $self = bless {}, $class;

    $self->{myStarCount} = $starCount;
    $self->{myMaxStarCount} = $maxStarCount;

    push @{$self->{starPolygon}}, Qt::PointF(1.0, 0.5);
    foreach my $i ( 1..4 ) {
        push @{$self->{starPolygon}}, Qt::PointF(0.5 + 0.5 * cos(0.8 * $i * 3.14),
                               0.5 + 0.5 * sin(0.8 * $i * 3.14));
    }

    push @{$self->{diamondPolygon}},
        Qt::PointF(0.4, 0.5),
        Qt::PointF(0.5, 0.4),
        Qt::PointF(0.6, 0.5),
        Qt::PointF(0.5, 0.6),
        Qt::PointF(0.4, 0.5);

    return $self;
}
# [0]

sub starCount
{
    my $self = shift;
    return $self->{myStarCount};
}

sub maxStarCount
{
    my $self = shift;
    return $self->{myMaxStarCount};
}

sub setStarCount
{
    my ($self, $starCount) = @_;
    $self->{myStarCount} = $starCount;
}

sub setMaxStarCount
{
    my ($self, $maxStarCount) = @_;
    $self->{myMaxStarCount} = $maxStarCount;
}

# [1]
sub sizeHint
{
    my $self = shift;
    return Qt::Size(
        $self->{myMaxStarCount} * PaintingScaleFactor,
        1 * PaintingScaleFactor
    );
}
# [1]

# [2]
sub paint
{
    my ($self, $painter, $rect, $palette, $mode) = @_;
    $painter->save();

    $painter->setRenderHint(Qt::Painter::Antialiasing(), 1);
    $painter->setPen(Qt::NoPen());

    if ($mode == Editable) {
        $painter->setBrush($palette->highlight());
    } else {
        $painter->setBrush($palette->foreground());
    }

    my $yOffset = ($rect->height() - PaintingScaleFactor) / 2;
    $painter->translate($rect->x(), $rect->y() + $yOffset);
    $painter->scale(PaintingScaleFactor, PaintingScaleFactor);

    foreach my $i ( 0..$self->{myMaxStarCount}-1 ) {
        if ($i < $self->{myStarCount}) {
            $painter->drawPolygon(Qt::PolygonF($self->{starPolygon}), Qt::WindingFill());
        } elsif ($mode == Editable) {
            $painter->drawPolygon(Qt::PolygonF($self->{diamondPolygon}), Qt::WindingFill());
        }
        $painter->translate(1.0, 0.0);
    }

    $painter->restore();
}
# [2]

1;
