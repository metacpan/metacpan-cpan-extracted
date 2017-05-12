package Parallel::Async::Chain;
use 5.008005;
use strict;
use warnings;

use Class::Accessor::Lite rw => [qw/tasks/];
use POSIX ":sys_wait_h";
use Time::HiRes ();

sub join :method {
    my $self = shift;
    $self = bless +{ tasks => [] } => $self unless ref $self;

    push @{ $self->{tasks} } => @_;

    return $self;
}

sub recv :method {
    my ($self, @args) = @_;

    no warnings 'once';
    local $Parallel::Async::Task::WANTARRAY = 1;
    use warnings 'once';

    my @pids = $self->run(@args);
    $self->_wait(@pids);

    return $self->read_child_result();
}

sub run {
    my ($self, @args) = @_;
    return map { $_->run(@args) } @{ $self->{tasks} };
}

sub daemonize {
    my ($self, @args) = @_;
    return map { $_->daemonize(@args) } @{ $self->{tasks} };
}

sub _wait {
    my $self = shift;
    my %pids = map { $_ => 1 } @_;

    while (%pids) {
        my $pid = waitpid(-1, WNOHANG);
        last if $pid == -1;

        delete $pids{$pid} if exists $pids{$pid};
    }
    continue {
        no warnings 'once';
        Time::HiRes::usleep($Parallel::Async::Task::WAIT_INTERVAL);
    }
}

sub read_child_result {
    my $self = shift;
    return map { $_->read_child_result() } @{ $self->{tasks} };
}

sub reset :method {
    my $self = shift;
    $_->reset for @{ $self->{tasks} };
    return $self;
}

sub clone {
    my $self  = shift;
    my $class = ref $self;
    return $class->join(map { $_->clone } @{ $self->{tasks} });
}

1;
__END__

=encoding utf-8

=head1 NAME

Parallel::Async::Chain - task chain manager.

=head1 METHODS

=over

=item my @results = $chain->recv(@args)

Execute tasks on child processes and wait for receive return values.

    # create new task
    my $task_add = async {
        my ($x, $y) = @_;
        return $x + $y;
    };
    my $task_sub = async {
        my ($x, $y) = @_;
        return $x - $y;
    };
    my $task_times = async {
        my ($x, $y) = @_;
        return $x * $y;
    };

    my $chain = $task_add->join($task_sub)->join($task_times);
    my ($res_add, $res_sub, $res_times) = $chain->recv(10, 20);
    say $res_add->[0];   ##  30
    say $res_sub->[0];   ## -10
    say $res_times->[0]; ## 200

=item my @pids = $chain->run(@args)

Execute tasks on child processes.

    # create new task
    my $task_add = async {
        my ($x, $y) = @_;
        return $x + $y;
    };
    my $task_sub = async {
        my ($x, $y) = @_;
        return $x - $y;
    };
    my $task_times = async {
        my ($x, $y) = @_;
        return $x * $y;
    };

    my $chain = $task_add->join($task_sub)->join($task_times);
    my @pids = $chain->run(10, 20);

=item my @pids = $chain->daemonize(@args)

Execute tasks on daemonized processes.

    # create new task
    my $task_add = async {
        my ($x, $y) = @_;
        return $x + $y;
    };
    my $task_sub = async {
        my ($x, $y) = @_;
        return $x - $y;
    };
    my $task_times = async {
        my ($x, $y) = @_;
        return $x * $y;
    };

    my $chain = $task_add->join($task_sub)->join($task_times);
    my @pids = $chain->daemonize(10, 20);

=item $chain->join($task1, ...);

Join multiple tasks, like L<Parallel::Async::Task>#join.

=item $task->reset;

Reset the execution status of all tasks, like L<Parallel::Async::Task>#reset.

=item $task->clone;

Clone and reset the execution status of all tasks, like L<Parallel::Async::Task>#clone.

=back

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

