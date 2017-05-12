package Parallel::QueueWorker;

use v5.12;
use Parallel::ForkManager;
use YAML::Any qw(LoadFile);
use Moose;

our $VERSION = eval '0.001';

has work => (   isa => 'CodeRef',   is  => 'rw', required => 1 , default => sub{ sub{} });
has before_work => (   isa => 'CodeRef',   is  => 'rw', default => sub{ sub{} });
has prepare_queue => (   isa => 'CodeRef',   is  => 'rw', default => sub{ sub{} });

has worker_id => (   isa => 'Str',   is  => 'ro', default => 'jobworker');

has quiet => (   isa => 'Bool',   is  => 'rw', default => 0);

has tap => (   isa => 'Bool',   is  => 'ro', default => 0);

has max_workers => (
    isa => 'Int',
    is  => 'ro',
    lazy_build => 1,
);

sub _build_max_workers {
    my ($self) = @_;
    $self->config->{$self->worker_id}->{max_workers} || 10;
}

has config_file => (
    isa => 'Str',
    is  => 'rw', 
    trigger => sub {
        my ($self,$new,$old) = @_;
        $self->config($self->_build_config) if defined $old and $new ne $old;
    },
);

has config => (
    isa => 'HashRef',
    is  => 'rw',
    lazy_build => 1,
);

sub _build_config {
    my ($self) = @_;
    my $file = $self->config_file;
    return ($file && -e $file) ? LoadFile($file):{};
}

has pm => (
    isa => 'Parallel::ForkManager',
    is  => 'ro',
    lazy_build => 1,
);

sub _build_pm {
    my ($self) = @_;
    Parallel::ForkManager->new($self->max_workers);
}

has job_queue => (
    traits  => ['Array'],
    isa     => 'ArrayRef[Item]',
    is  => 'ro',
    default => sub {[]},
    handles => {
        add_job => 'push',
        next_job => 'pop',
        job_count => 'count',
    },
);

has is_master => (   isa => 'Bool',   is  => 'rw', default => 1);

sub fork_work {
    my ($self,$work_code,$before_work_code) = @_;
    $self->say("process jobs ...");
    while (my $job = $self->next_job) {
        $self->pm->start and next;
        # in worker
        $self->is_master(0);
        $before_work_code->($self);
        $work_code->($self,$job);
        $self->pm->finish;
    }
    $self->say("queued jobs done.");
}

sub say {
    my $self = shift;
    return if $self->quiet;
    print '# ' if $self->tap;
    say $self->is_master? "master " : "worker ","$$ >> ",@_;
}

sub run {
    my ($self) = @_;
    $| = 1;
    $self->say("start to process...");
    my $total = 0;
    my $pm = $self->pm;
    my ($work_code,$before_work_code,$prepare_queue_code) = @$self{qw(work before_work prepare_queue)};
    while (my $cnt = $prepare_queue_code->($self)) {
        $self->say("$cnt jobs queued.");
        $total += $cnt;
        $self->fork_work($work_code,$before_work_code) if @{$self->job_queue};
        $self->say("total $total jobs done,now. <<") unless $total % 2000;
    }
    $self->fork_work($work_code,$before_work_code) if @{$self->job_queue};
    $self->say("Waiting for workers done ...");
    $pm->wait_all_children;  
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Parallel::QueueWorker - Simple worker support do jobs in parallel processes.

=head1 SYNOPSIS

    use Parallel::QueueWorker;
    my $worker = Parallel::QueueWorker->new(
        # config file will load
        configfile => "$FindBin::Bin/../etc/app.yml",
        # callback/handler
        # loop to prepare job queue
        prepare_queue => sub {
            my ($self) = @_;
            $self->add_job({_id => $_ }) for (0..99);
            $self->{done} = 1 unless $self->{done};
            # if you return non-zero , the prepare_queue will loop next,
            unless ($self->{done}) {
                $self->{done} = 1;
                return 100;
            }
            # this will flag no jobs queued anymore and break prepare_queue loop.
            # but, not, this is invoke again!
            return 0;
        },
        # before call work will run this. 
        before_work = sub {
            my ($self);
            # If you want to open resource,like socket,dbi, should in here.
        },
        # work code
        work => sub {
            my ($self,$job) = @_;
            $self->say("job id:",$job->{_id});
        },
    );

=head1 DESCRIPTION

=head1 METHODS

=head1 run

    $worker->run;

Start to process jobs , it will wait until all queued jobs done.

=head2 add_job($job)

    # add job to queue
    $worker->add_job({_id => 3,foo => 'bar'});

Add job to the internal job queue. You should call this on prepare_queue callback.

=head2 before_work(CodeRref)

Callback will invoke before call work.

=head2 work(CodeRref)

    work prototype => sub { my ($self,$job ) }

Your work code, this code will fork and parallel running to process job.

=head2 prepare_queue(CodeRref)

The code to feed jobs into queue. If return non-zero, this code will invoke again after work,
until it return 0, so you can make the code loop run or just once.

=head2 say

A helpful function to output message handy, additional master or worker PID.

    $self->say('hello');
    # in master, output,xxxx meant master PID
    master xxxx >> hello
    # in worker, output,xxxx meant worker(childen process) PID
    worker xxxx >> hello

=head2 fork_work

Internal, fork workers and process queued jobs until jobs all done.

=head2 run

    $worker->run;

Start to run, its will call prepare_queue code, if any job is queued, then fork workers to
process them in parallel.


=head1 AUTHOR

Night Sailer(Pan Fan) < nightsailer{at}gmail dot com >

=head1 COPYRIGHT

copyright nightsailer.com

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.