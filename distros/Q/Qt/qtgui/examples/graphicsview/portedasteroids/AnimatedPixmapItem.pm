package AnimatedPixmapItem;

use strict;
use warnings;
use QtCore4;
use QtGui4;
use QtCore4::isa qw( Qt::GraphicsItem );

sub frame
{
    return this->{currentFrame};
}

sub frameCount
{
    return scalar @{this->{frames}};
}
sub image
{
    my ($frame) = @_;
    return scalar @{this->{frames}} == 0 ? Qt::Pixmap() : this->{frames}->[$frame % scalar @{this->{frames}}]->{pixmap};
}

sub setVelocity
{
    my ($xvel, $yvel) = @_;
    this->{vx} = $xvel;
    this->{vy} = $yvel;
}

sub xVelocity
{
    return this->{vx};
}

sub yVelocity
{
    return this->{vy};
}

#struct Frame {
    #Qt::Pixmap pixmap;
    #Qt::PainterPath shape;
    #Qt::RectF boundingRect;
#};
    
sub currentFrame() {
    return this->{currentFrame};
}

sub frames() {
    return this->{frames};
}

sub vx() {
    return this->{vx};
}

sub vy() {
    return this->{vy};
}

sub NEW
{
    my ($class, $animation, $scene) = @_;
    $class->SUPER::NEW(undef, $scene);
    this->{vx} = 0;
    this->{vy} = 0;
    this->{currentFrame} = 0;
    this->{frames} = [];
    for (my $i = 0; $i < scalar @{$animation}; ++$i) {
        my $pixmap = $animation->[$i];
        my $frame = {
            pixmap => $pixmap,
            shape => Qt::PainterPath(),
            boundingRect => Qt::RectF($pixmap->rect())
        };
        push @{this->{frames}}, $frame;
    }
}

sub setFrame
{
    my ($frame) = @_;
    if (scalar @{frames()}) {
        prepareGeometryChange();
        this->{currentFrame} = $frame % scalar @{frames()};
    }
}

sub advance
{
    my ($phase) = @_;
    if ($phase == 1) {
        moveBy(vx, vy);
    }
}

sub boundingRect
{
    return frames()->[currentFrame]->{boundingRect};
}

sub shape
{
    my $f = frames()->[currentFrame];
    if ($f->{shape}->isEmpty()) {
        my $path = Qt::PainterPath();
        $path->addRegion(Qt::Region($f->{pixmap}->createHeuristicMask()));
        $f->{shape} = $path;
    }
    return $f->{shape};
}

sub paint
{
    my ($painter) = @_;
    $painter->drawPixmap(0, 0, frames->[currentFrame]->{pixmap});
}

1;
