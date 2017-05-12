package Pangloss::Segment::Search;

use base qw( OpenFrame::WebApp::Segment::Session );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.3 $ '))[2];

sub dispatch {
    my $self     = shift;
    my $app      = $self->store->get('Pangloss::Application') || return;
    my $srequest = $self->store->get('Pangloss::Search::Request') || return;
    my $pager    = $self->store->get('Pangloss::Search::Results::Pager');
    my $view     = $self->store->get('Pangloss::Application::View');

    $view = $app->searcher->search_terms( $srequest, $pager, $view );

    $self->emit( "storing pager: $view->{search_results_pager}" );
    $self->store->set( $view->{search_results_pager} );

    return $view;
}

1;
