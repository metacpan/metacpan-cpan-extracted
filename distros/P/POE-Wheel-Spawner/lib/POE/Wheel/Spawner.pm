package POE::Wheel::Spawner;

use 5.006;
use strict;
use warnings;

use fields qw/
    pool_size
    stop_if_done
    workload
    _workers_sig_count
    /;

use POE qw/
    Wheel::Run
    Filter::Reference
    /;

use version;

=head1 NAME

POE::Wheel::Spawner - A simple subprocess spawner

=head1 DESCRIPTION

POE::Wheel::Spawner starts on L<run|/run(%arg)> only one subprocess for the L<workload|/new(%arg)>. Until number of subprocesses does not exceed L<pool_size|/new(%arg)> each subprocess can L<spawn|/spawn($pid)> another one.

=head1 VERSION

Version v0.03.1

=cut

$POE::Wheel::Spawner::VERSION = version->declare("0.03.1");

=head1 SYNOPSIS

    use POE::Wheel::Spawner;

    my $foo = POE::Wheel::Spawner->new(
                pool_size => 2,
                stop_if_done => 1,
                workload => sub { _workload() }
        );

    $foo->run();

    sub _workload {

        # request for a new sibling
        $foo->spawn($$);

        # ...
    }

=head1 SUBROUTINES/METHODS

=head2 new(%arg)

Arguments:

=over

=item

pool_size

the number of maximal parallel executed C<workload>

=item

stop_if_done

stop after all C<pool_size> pid's are exited.

run endless if !C<stop_if_done>

=item

workload

CODE reference to be executed

=back

=cut

sub new {
    my POE::Wheel::Spawner $self = shift;
    my (%opts) = @_;
    unless (ref($self)) {
        $self = fields::new($self);
    }

    if (defined($opts{pool_size})) {
        $opts{pool_size} =~ /^\d+$/
            || die "'pool_size' property expects a positive integer value";
    }

    $self->{pool_size} = int(delete($opts{pool_size}) || 0);

    $self->{stop_if_done}       = delete($opts{stop_if_done});
    $self->{workload}           = delete($opts{workload});
    $self->{_workers_sig_count} = 0;

    %opts && warn sprintf("ignore unsupported properties '%s'", keys(%opts));

    return $self;
} ## end sub new

=head2 run(%arg)

optional C<%arg> arguments for L<POE::Session>:

=over

=item

debug

default 0

=item

trace

default 0

=back

create a L<POE::Session>

run L<POE::Kernel>

=cut

sub run {
    my ($self, %arg) = @_;

    ref($self->{workload}) eq 'CODE'
        || die "work_method is not a code reference";

    POE::Session->create(
        options => { debug => $arg{debug} || 0, trace => $arg{trace} || 0 },
        object_states => [
            $self => {
                _start     => '_handle_start',
                _next      => '_handle_start',
                _sig_child => '_handle_sig_child',
                _done      => '_handle_done',
                _stderr    => '_handle_stderr',
                _stdout    => '_handle_stdout',
            }
        ]
    );

    POE::Kernel->run();
} ## end sub run

=head2 spawn($pid)

request to spawn

=cut

sub spawn {
    my ($self, $pid) = @_;
    my $filter = POE::Filter::Reference->new();
    my $output = $filter->put([{ busy_worker_pid => $pid }]);

    print @$output;
} ## end sub spawn

#=head2 _handle_start
#
#handle C<_start> and C<_next> events defined in POE::Session, which is initialized in C<run>.
#
#start execution of C<workload> by C<pool_size> parallel running pids
#
#=cut

sub _handle_start {
    my ($self, $kernel, $heap) = @_[OBJECT, KERNEL, HEAP];

    my $pids_count = scalar(keys(%{ $heap->{worker_by_pid} }));
    ($pids_count >= $self->{pool_size}) && return;

    my $w = POE::Wheel::Run->new(
        Program => sub { &{ $self->{workload} } },
        StdoutFilter => POE::Filter::Reference->new(),
        StdoutEvent  => "_stdout",
        StderrEvent  => "_stderr",
        CloseEvent   => "_done",
    );

    $heap->{worker_by_pid}->{ $w->PID } = $w;
    $kernel->sig_child($w->PID, "_sig_child");
} ## end sub _handle_start

#=head2 _handle_sig_child
#
#Clear heap. Trigger '_next' if !stop_if_done and currently no child is busy
#
#=cut

sub _handle_sig_child {
    my ($self, $kernel, $heap, $pid, $exit_val)
        = @_[OBJECT, KERNEL, HEAP, ARG1, ARG2];

    ++$self->{_workers_sig_count};

    my $child = delete $heap->{worker_by_pid}{$pid};
    unless ($child) {
        POE::Kernel::_die("no child pid: $pid");
    }

    delete $heap->{busy_worker_pid}->{$pid};

    if ($self->{stop_if_done}) {
        ($self->{_workers_sig_count} >= $self->{pool_size}) && return;
    }
    else {
        (scalar(keys(%{ $heap->{busy_worker_pid} })))
            || $kernel->yield("_next");
    }
} ## end sub _handle_sig_child

#=head2 _handle_done
#
#is not implemented yet
#
#=cut

sub _handle_done { }

#=head2 _handle_stderr
#
#provide STDERR to POE::Kernel::_warn
#
#=cut

sub _handle_stderr {
    my ($self, $input, $wheel_id) = @_[OBJECT, ARG0, ARG1];
    POE::Kernel::_warn("wheel $wheel_id STDERR: $input");
}

#=head2 _handle_stdout
#
#evaluate from child to stdout printed result.
#
#trigger _next event if child asks - by using busy_worker_pid printed to stdout - for a sibling
#
#=cut

sub _handle_stdout {
    my ($self, $kernel, $heap, $result) = @_[OBJECT, KERNEL, HEAP, ARG0];
    if (ref($result) eq 'HASH' && $result->{busy_worker_pid}) {
        $heap->{busy_worker_pid}->{ $result->{busy_worker_pid} } = 1;
        $kernel->yield("_next");
    }
} ## end sub _handle_stdout

1;    # End of POE::Wheel::Spawner

=head1 AUTHOR

Alexei Pastuchov E<lt>palik at cpan.orgE<gt>.

=head1 REPOSITORY

L<https://github.com/p-alik/POE-Wheel-Spawner.git>

=head1 LICENSE AND COPYRIGHT


Copyright 2014-2016 by Alexei Pastuchov E<lt>palik at cpan.orgE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
