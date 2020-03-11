package Mojolicious::Plugin::Minion::Overview::Controller::Metrics::Workers;
use Mojo::Base 'Mojolicious::Controller';

=head2 show

Show metrics for a worker

=cut

sub show {
    my $self = shift;
    
    my $worker = $self->app->minion_overview
        ->worker($self->param('worker'));

    my $waittime = $self->app->minion_overview
        ->date($self->session('minion_overview_date'))
        ->worker_waittime_metrics($self->param('worker'));

    my $throughput = $self->app->minion_overview
        ->date($self->session('minion_overview_date'))
        ->worker_throughput_metrics($self->param('worker'));

    return $self->render('minion_overview/metrics/workers/show',
        worker      => $worker,
        waittime    => $waittime,
        throughput  => $throughput,
    );
}

1;
