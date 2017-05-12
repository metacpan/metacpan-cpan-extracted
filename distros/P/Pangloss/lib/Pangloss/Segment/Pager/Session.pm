package Pangloss::Segment::Pager::Session;

use base qw( OpenFrame::WebApp::Segment::Session );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.1 $ '))[2];

our $KEY = 'search_pager';

sub get_pager_from_session {
    my $self    = shift;
    my $session = $self->get_session_from_store || return;
    return $session->get( $KEY );
}

sub save_pager_in_session {
    my $self    = shift;
    my $pager   = shift;
    my $session = $self->get_session_from_store || return;

    $session->set( $KEY, $pager );

    return $self;
}

1;
