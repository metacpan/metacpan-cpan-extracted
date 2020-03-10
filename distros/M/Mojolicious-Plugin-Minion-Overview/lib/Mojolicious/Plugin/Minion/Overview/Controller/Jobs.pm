package Mojolicious::Plugin::Minion::Overview::Controller::Jobs;
use Mojo::Base 'Mojolicious::Controller';

=head2 retry

Retry a job

=cut

sub retry {
    my $self = shift;
    
    my $job = $self->app->minion_overview->job($self->param('id'));

    $job->retry;

    return $self->redirect_to('minion_overview.jobs.show', id => $job->id);
}

=head2 search

Show a list of jobs

=cut

sub search {
    my $self = shift;
    
    my $search = $self->app->minion_overview
        ->date($self->session('minion_overview_date'))
        ->search($self->req->param('term'))
        ->tags($self->req->every_param('tags'))
        ->when($self->req->param('worker'), 'worker')
        ->when($self->req->param('state'), 'state')
        ->page($self->param('page') || 1)
        ->jobs();

    return $self->render('minion_overview/jobs/search',
        title   => 'Recent Jobs',
        section => 'jobs',
        jobs    => $search->{ results },
        query   => $search->{ query },
    );
}

=head2 show

Show a job

=cut

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
