package Pangloss::Segment::Pager::GetFromSession;

use base qw( Pangloss::Segment::Pager::Session );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.1 $ '))[2];

sub dispatch {
    my $self = shift;
    return $self->get_pager_from_session;
}

1;
