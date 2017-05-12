package Pangloss::Segment::SearchRequest::GetFromSession;

use base qw( Pangloss::Segment::SearchRequest::Session );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.1 $ '))[2];

sub dispatch {
    my $self = shift;
    return $self->get_srequest_from_session;
}

1;
