package StarEditor;

use strict;
use warnings;
use QtCore4;
use QtGui4;

use StarRating;

# [0]
use QtCore4::isa qw( Qt::Widget );

use QtCore4::signals
    editingFinished => [];

sub setStarRating
{
    my ($starRating) = @_;
    this->{myStarRating} = $starRating;
}

sub starRating {
    return this->{myStarRating}
}

# [0]
sub NEW
{
    my ($class, $parent) = @_;
    $class->SUPER::NEW($parent);
    this->setMouseTracking(1);
    this->setAutoFillBackground(1);
}
# [0]

sub sizeHint
{
    return this->{myStarRating}->sizeHint();
}

# [1]
sub paintEvent
{
    my $painter = Qt::Painter(this);
    this->{myStarRating}->paint($painter, this->rect(), this->palette(),
                       StarRating::Editable);
    $painter->end();
}
# [1]

# [2]
sub mouseMoveEvent
{
    my ($event) = @_;
    my $star = this->starAtPosition($event->x());

    if ($star != this->{myStarRating}->starCount() && $star != -1) {
        this->{myStarRating}->setStarCount($star);
        this->update();
    }
}
# [2]

# [3]
sub mouseReleaseEvent
{
    emit this->editingFinished();
}
# [3]

# [4]
sub starAtPosition
{
    my ($x) = @_;
    # C++ code does operation on ints.  Use sprintf '%d' to emulate this.
    my $star = sprintf( '%d',
               ($x / (this->{myStarRating}->sizeHint()->width()
                     / this->{myStarRating}->maxStarCount()))) + 1;
    if ($star <= 0 || $star > this->{myStarRating}->maxStarCount()) {
        return -1;
    }

    return $star;
}
# [4]

1;
