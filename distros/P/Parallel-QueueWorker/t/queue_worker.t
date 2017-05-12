use v5.12;
use Test::More;
use_ok( 'Parallel::QueueWorker');

my $queued = 2;
my $worker = Parallel::QueueWorker->new(
    tap => 1,
    max_worker => 2,
    work => sub {
        my ($self,$job) = @_;
        fail('before_work') unless $self->{_c} == 1;
        fail('work should run on forked process') if $self->{last_work};
        fail('work must run on worker') if $self->is_master;
        $self->{last_work} = $self->{work};
    },
    prepare_queue => sub {
        my ($self) = @_;
        my $i = 0;
        if ($queued) {
            $self->add_job([$i++]) for (0..2);
            $queued--;
        }
        ok($self->is_master,'prepare_queue must run on master');
        $queued;
    },
    before_work => sub {
        my ($self) = @_;
        $self->{_c} = 0 unless $self->{_c};
        $self->{_c}++;
        $self->say($self->{_c});
        fail('before_work/must run on worker') if $self->is_master;
    },
);

$worker->run;

is($queued,0,'prepare_queue must loop');

done_testing;
