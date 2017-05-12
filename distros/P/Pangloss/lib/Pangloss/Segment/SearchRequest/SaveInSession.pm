package Pangloss::Segment::SearchRequest::SaveInSession;

use base qw( Pangloss::Segment::SearchRequest::Session );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.2 $ '))[2];

sub dispatch {
    my $self     = shift;
    my $srequest = $self->store->get('Pangloss::Search::Request') || return;
    $self->save_srequest_in_session( $srequest );
    return 1;
}

1;
