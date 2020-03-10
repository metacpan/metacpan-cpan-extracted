package Mojolicious::Plugin::Minion::Overview::Controller::FailedJobs;
use Mojo::Base 'Mojolicious::Controller';

=head2 search

Show failed jobs

=cut

sub search {
    my $self = shift;
    
    my $search = $self->app->minion_overview
        ->date($self->session('minion_overview_date'))
        ->search($self->req->param('term'))
        ->tags($self->req->every_param('tags'))
        ->when($self->req->param('worker'), 'worker')
        ->page($self->param('page') || 1)
        ->failed_jobs();

    return $self->render('minion_overview/jobs/search',
        title   => 'Failed Jobs',
        section => 'failed_jobs',
        jobs    => $search->{ results },
        query   => $search->{ query },
    );
}

1;
