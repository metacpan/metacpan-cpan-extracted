package Mojolicious::Plugin::Minion::Overview::Controller::FailedJobs;
use Mojo::Base 'Mojolicious::Controller';

sub search {
    my $self = shift;
    
    my $search = $self->app->minion_overview
        ->search($self->req->param('term'))
        ->tags($self->req->every_param('tags'))
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
