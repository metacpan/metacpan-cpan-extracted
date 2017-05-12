package Parallel::Async::Task;
use 5.008005;
use strict;
use warnings;

use Try::Tiny;
use Storable ();
use File::Spec;
use POSIX ":sys_wait_h";
use Time::HiRes ();

(my $TMPDIR_BASENAME = __PACKAGE__) =~ s!::!-!g;

our $WANTARRAY;
our $EXIT_CODE;

our $WAIT_INTERVAL = 0.1 * 1000 * 1000;

use Class::Accessor::Lite ro => [qw/parent_pid child_pid/];
use Parallel::Async::Chain;

sub new {
    my ($class, %args) = @_;
    return bless +{
        %args,
        parent_pid     => $$,
        clild_pid      => undef,
        already_run_fg => 0,
    } => $class;
}

sub recv :method {
    my ($self, @args) = @_;

    local $WANTARRAY = wantarray;

    $self->run(@args);
    $self->_wait();

    my $ret = $self->read_child_result();
    return $WANTARRAY ? @$ret : $ret->[0];
}

sub as_anyevent_child {
    my ($self, $cb, @args) = @_;

    local $WANTARRAY = 1;

    $self->run(@args);

    require AnyEvent;
    return AnyEvent->child(
        pid => $self->{child_pid},
        cb  => sub {
            my ($pid, $status) = @_;

            my $ret = $self->read_child_result();
            return $cb->($pid, $status, $WANTARRAY ? @$ret : $ret->[0]);
        }
    );
}

sub run {
    my ($self, @args) = @_;
    die 'this task already run.' if $self->{already_run_fg};

    my $pid = fork;
    die $! unless defined $pid;

    $self->{already_run_fg} = 1;
    if ($pid == 0) {## child
        $self->{child_pid} = $$;
        return $self->_run_on_child(@args);
    }
    else {## parent
        $self->{child_pid} = $pid;
        return $self->_run_on_parent(@args);
    }
}

sub daemonize {
    my ($self, @args) = @_;

    my $orig = $self->{code};
    local $self->{code} = sub {
        my $pid = fork;
        die $! unless defined $pid;

        if ($pid == 0) {## child
            $orig->(@args);
            exit 0;
        }
        else {## parent
            return $pid;
        }
    };

    return $self->recv();
}

sub _run_on_parent {
    my $self = shift;
    return $self->{child_pid};
}

sub _run_on_child {
    my ($self, @args) = @_;

    local $EXIT_CODE = 0;

    my $orig = $self->{code};
    my $ret = try {
        my @ret;

        # context proxy
        if ($WANTARRAY) {
            @ret = $orig->(@args);
        }
        elsif (defined $WANTARRAY) {
            $ret[0] = $orig->(@args);
        }
        else {
            $orig->(@args);
        }

        return [0, undef, \@ret];
    }
    catch {
        $EXIT_CODE = 255     if !$EXIT_CODE; # last resort
        $EXIT_CODE = $? >> 8 if $? >> 8;     # child exit status
        $EXIT_CODE = $!      if $!;          # errno
        return [1, $_, undef];
    };

    $self->_write_storable_data($ret);

    CORE::exit($EXIT_CODE);
}

sub join :method {
    my $self = shift;
    return Parallel::Async::Chain->join($self, @_);
}

sub _wait {
    my $self = shift;

    my $pid = $self->{parent_pid};
    while ($self->{child_pid} != $pid) {
        $pid = waitpid(-1, WNOHANG);
        Time::HiRes::usleep($WAIT_INTERVAL);
        last if $pid == -1;
    }
}

sub _gen_storable_tempfile_path {
    my $self = shift;
    return File::Spec->catfile(File::Spec->tmpdir, join('-', $TMPDIR_BASENAME, $self->{parent_pid}, $self->{child_pid}) . '.txt');
}

sub _write_storable_data {
    my ($self, $data) = @_;

    my $storable_tempfile = $self->_gen_storable_tempfile_path();
    try {
        Storable::store($data, $storable_tempfile) or die 'faild store.';
    }
    catch {
        warn(qq|The storable module was unable to store the child's data structure to the temp file "$storable_tempfile":  | . join(', ', $_));
    };
}

sub _read_storable_data {
    my $self = shift;

    my $data;

    my $storable_tempfile = $self->_gen_storable_tempfile_path();
    if (-e $storable_tempfile) {
        try {
            $data = Storable::retrieve($storable_tempfile) or die 'faild retrieve.';
        }
        catch {
            warn(qq|The storable module was unable to retrieve the child's data structure from the temporary file "$storable_tempfile":  | . join(', ', $_));
        };

        # clean up after ourselves
        unlink $storable_tempfile;
    }

    return $data;
}

sub read_child_result {
    my $self = shift;
    my $data = $self->_read_storable_data() || [];

    if ($data->[0]) {## has error
        die $data->[1];
    }
    else {
        return $data->[2] || [];
    }
}

sub reset :method {
    my $self = shift;

    $self->{child_pid}      = undef;
    $self->{already_run_fg} = 0;

    return $self;
}

sub clone {
    my $self = shift;
    my $class = ref $self;
    return $class->new(%$self);
}

1;
__END__

=encoding utf-8

=head1 NAME

Parallel::Async::Task - task class for Parallel::Async.

=head1 METHODS

=over

=item $task = Parallel::Async::Task->new(\%args)

Creates a new Parallel::Async::Task instance.

    use Parallel::Async::Task;

    # create new task
    my $task = Parallel::Async::Task->new(code => sub {
        my $result = ...; ## do some task
        return $result;
    });

this code is same as

    use Parallel::Async;

    # create new task
    my $task = async {
        my $result = ...; ## do some task
        return $result;
    };

Arguments can be:

=over

=item * C<code>

CodeRef to run on child process.
This CodeRef can get arguments from C<recv> or C<as_anyevent_child> or C<run> method arguments.

=back

=item my @result = $task->recv(@args)

Execute task on child process and wait for receive return value.

    # create new task
    my $task = async {
        my ($x, $y) = @_;
        return $x + $y;
    };

    my $res = $task->recv(10, 20);
    say $res; # 30

=item my $watcher = $task->as_anyevent_child(@args)

Execute task on child process and receive return value with AnyEvent->child.
This feature required L<AnyEvent>.

    # create new task
    my $task = async {
        my ($x, $y) = @_;
        return $x + $y;
    };

    my $watcher; $watcher = $task->as_anyevent_child(sub {
        my ($pid, $status, $res) = @_;
        say $res; ## 30
        undef $watcher;
    }, 10, 20);

=item my $pid = $task->run(@args)

Execute task on child process.

    # create new task
    my $task = async {
        my ($url) = @_;
        post($url);
    };

    my $pid = $task->run($url);
    wait;

=item my $pid = $task->daemonize(@args)

Execute task on daemonized process.

    # create new task
    my $task = async {
        my ($url) = @_;
        post($url);
    };

    my $pid = $task->daemonize($url);

=item my $chain = $task->join($task1, ...);

Join multiple tasks.
Can be execute tasks in parallel by chained task.
See also L<Parallel::Async::Chain> for more usage.

=item $task->reset;

Reset the execution status of the task.
This feature is useful when you want to re-execute the same task.

    # create new task
    my $task = async {
        my ($x, $y) = @_;
        return $x + $y;
    };

    my $res = $task->recv(10, 20);
    say $res; # 30

    $res = $task->reset->recv(10, 30);
    say $res; # 40

=item $task->clone;

Clone and reset the execution status of the task.
This feature is useful when you want to execute same tasks in parallel.

    # create new task
    my $task = async {
        my ($x, $y) = @_;
        return $x + $y;
    };

    my @res = $task->join(map { $task->clone } 1..9)->recv(10, 30);

=back

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

