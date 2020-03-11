package Mojolicious::Plugin::Minion::Overview::Controller::API::Metrics::Workers;
use Mojo::Base 'Mojolicious::Controller';

=head2 waittime

Show waittime metrics for a worker

=cut

sub waittime {
    my $self = shift;
    
    my $waittime = $self->app->minion_overview
        ->date($self->session('minion_overview_date'))
        ->worker_waittime_metrics($self->param('worker'));

    return $self->render(json => $waittime);
}

=head2 throughput

Show throughput metrics for a worker

=cut

sub throughput {
    my $self = shift;

    my $throughput = $self->app->minion_overview
        ->date($self->session('minion_overview_date'))
        ->worker_throughput_metrics($self->param('worker'));

    my $finished = $throughput->grep(sub { $_->{ state } eq 'finished' });
    my $failed = $throughput->grep(sub { $_->{ state } eq 'failed' });

    return $self->render(json => {
        finished    => $finished,
        failed      => $failed,
    });
}

1;
