package Pangloss::Segment::Pager::SaveInSession;

use base qw( Pangloss::Segment::Pager::Session );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.1 $ '))[2];

sub dispatch {
    my $self  = shift;
    my $pager = $self->store->get('Pangloss::Search::Results::Pager') || return;
    $self->save_pager_in_session( $pager );
    return 1;
}

1;
