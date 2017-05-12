package Pangloss::Search::Filter::Category;

use base qw( Pangloss::Search::Filter::Base );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.5 $ '))[2];

sub applies_to {
    my $self = shift;
    my $term = shift;

    return unless $self->parent->concepts->exists( $term->concept );

    my $concept  = $self->parent->concepts->get( $term->concept );
    my $category = $concept->category || return;

    return grep { $category eq $_ } keys %{ $self->item_keys };
}

1;
