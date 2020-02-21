package Mojolicious::Plugin::Minion::Overview::Controller::Jobs;
use Mojo::Base 'Mojolicious::Controller';

sub retry {
    my $self = shift;
    
    my $job = $self->app->minion_overview->job($self->param('id'));

    $job->retry;

    return $self->redirect_to('minion_overview.jobs.show', id => $job->id);
}

sub search {
    my $self = shift;
    
    my $search = $self->app->minion_overview
        ->search($self->req->param('term'))
        ->tags($self->req->every_param('tags'))
        ->page($self->param('page') || 1)
        ->jobs();

    return $self->render('minion_overview/jobs/search',
        title   => 'Recent Jobs',
        section => 'jobs',
        jobs    => $search->{ results },
        query   => $search->{ query },
    );
}

sub show {
    my $self = shift;
    
    my $job = $self->app->minion_overview->job($self->param('id'));

    my $search = my $query = $self->app->minion_overview
        ->where('parent_id', $job->id)
        ->tags($self->req->every_param('tags'))
        ->page($self->param('page') || 1)
        ->jobs();

    return $self->render('minion_overview/jobs/show',
        job         => $job,
        children    => $search->{ results },
        query       => $search->{ query },
    );
}

1;
