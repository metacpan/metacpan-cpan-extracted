package Pangloss::Search::Filter::Translator;

use base qw( Pangloss::Search::Filter::Base );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.4 $ '))[2];

sub applies_to {
    my $self    = shift;
    my $creator = shift->creator;
    return grep { $creator eq $_ } keys %{ $self->item_keys };
}

1;
