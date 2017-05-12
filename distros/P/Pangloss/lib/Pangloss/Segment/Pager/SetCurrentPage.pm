package Pangloss::Segment::Pager::SetCurrentPage;

use base qw( Pipeline::Segment );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.2 $ '))[2];

sub dispatch {
    my $self    = shift;
    my $pager   = $self->store->get('Pangloss::Search::Results::Pager') || return;
    my $request = $self->store->get('OpenFrame::Request') || return;
    my $args    = $request->arguments || return;
    $self->emit( "setting current page to [$args->{page}]" ),
      $pager->page( $args->{page} )
	if $args->{page};
}

1;
