package Pangloss::Search::Filter::DateRange;

use base      qw( Pangloss::Search::Filter::Base );
use accessors qw( from to );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.4 $ '))[2];

sub key {
    my $self = shift;
    if (@_) { return $self->from(shift)->to(shift); }
    else    { return $self->from . ' - ' . $self->to; }
}

sub applies_to {
    my $self = shift;
    my $term = shift;
    my $date = $term->date;
    return $self->from <= $date && $date <= $self->to;
}

1;
