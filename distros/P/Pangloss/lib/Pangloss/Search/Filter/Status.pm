package Pangloss::Search::Filter::Status;

use base qw( Pangloss::Search::Filter::Base );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.6 $ '))[2];

sub applies_to {
    my $self = shift;
    my $code = shift->status->code;
    return grep { $code & $_ } keys %{ $self->item_keys };
}

1;
