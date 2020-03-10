package Mojolicious::Plugin::Minion::Overview::Controller::API::Metrics::Jobs;
use Mojo::Base 'Mojolicious::Controller';

=head2 runtime

Show runtime metrics for a job

=cut

sub runtime {
    my $self = shift;
    
    my $runtime = $self->app->minion_overview
        ->date($self->session('minion_overview_date'))
        ->job_runtime_metrics($self->param('job'));

    my $finished = $runtime->grep(sub { $_->{ state } eq 'finished' });
    my $failed = $runtime->grep(sub { $_->{ state } eq 'failed' });

    return $self->render(json => {
        finished    => $finished,
        failed      => $failed,
    });
}

=head2 throughput

Show throughput metrics for a job

=cut

sub throughput {
    my $self = shift;

    my $throughput = $self->app->minion_overview
        ->date($self->session('minion_overview_date'))
        ->job_throughput_metrics($self->param('job'));

    my $finished = $throughput->grep(sub { $_->{ state } eq 'finished' });
    my $failed = $throughput->grep(sub { $_->{ state } eq 'failed' });

    return $self->render(json => {
        finished    => $finished,
        failed      => $failed,
    });
}

1;
