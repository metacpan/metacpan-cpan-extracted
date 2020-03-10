package Mojolicious::Plugin::Minion::Overview::Controller::Metrics;
use Mojo::Base 'Mojolicious::Controller';

=head2 search

Show a list of unique jobs and finished/failed stats

=cut

sub search {
    my $self = shift;
    
    my $search = $self->app->minion_overview
        ->date($self->session('minion_overview_date'))
        ->search($self->req->param('term'))
        ->page($self->param('page') || 1)
        ->unique_jobs();

    return $self->render('minion_overview/metrics/search',
        jobs    => $search->{ results },
        query   => $search->{ query },
    );
}

1;
