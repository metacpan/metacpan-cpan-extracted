package Pangloss::Search::Filter::Concept;

use base qw( Pangloss::Search::Filter::Base );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.4 $ '))[2];

sub applies_to {
    my $self    = shift;
    my $concept = shift->concept;
    return grep { $concept eq $_ } keys %{ $self->item_keys };
}

1;
