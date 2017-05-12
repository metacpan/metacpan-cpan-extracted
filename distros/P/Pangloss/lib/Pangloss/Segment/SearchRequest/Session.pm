package Pangloss::Segment::SearchRequest::Session;

use base qw( OpenFrame::WebApp::Segment::Session );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.2 $ '))[2];

our $KEY = 'search_request';

sub get_srequest_from_session {
    my $self     = shift;
    my $session  = $self->get_session_from_store || return;
    return $session->get( $KEY );
}

sub save_srequest_in_session {
    my $self     = shift;
    my $srequest = shift;
    my $session  = $self->get_session_from_store || return;

    $session->set( $KEY, $srequest );

    return $self;
}

1;
