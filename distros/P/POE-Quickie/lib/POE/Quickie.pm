package POE::Quickie;
BEGIN {
  $POE::Quickie::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $POE::Quickie::VERSION = '0.18';
}

use strict;
use warnings FATAL => 'all';
use Carp 'croak';
use POE;
use POE::Filter::Stream;
use POE::Wheel::Run;

require Exporter;
use base 'Exporter';
our @EXPORT      = qw(quickie_run quickie quickie_merged quickie_tee quickie_tee_merged);
our @EXPORT_OK   = @EXPORT;
our %EXPORT_TAGS = (ALL => [@EXPORT]);

our %OBJECTS;

sub new {
    my ($package, %args) = @_;

    my $parent_id = $poe_kernel->get_active_session->ID;
    if (my $self = $OBJECTS{$parent_id}) {
        return $self;
    }

    my $self = bless \%args, $package;
    $self->{parent_id} = $parent_id;
    $OBJECTS{$parent_id} = $self;

    return $self;
}

sub _create_session {
    my ($self) = @_;

    POE::Session->create(
        object_states => [
            $self => [qw(
                _start
                _stop
                _exception
                _create_wheel
                _child_signal
                _child_timeout
                _child_stdin
                _child_stdout
                _child_stderr
                _killall
            )],
        ],
        options => {
            ($self->{debug}   ? (debug   => 1) : ()),
            ($self->{default} ? (default => 1) : ()),
            ($self->{trace}   ? (trace   => 1) : ()),
        },
    );

    return;
}

sub _start {
    my ($kernel, $session, $self) = @_[KERNEL, SESSION, OBJECT];

    my $session_id = $session->ID;
    $self->{session_id} = $session_id;
    $kernel->sig(DIE => '_exception');
    return;
}

sub _stop {
    my $self = $_[OBJECT];
    delete $self->{session_id};
    return;
}

sub run {
    my ($self, %args) = @_;
    $self = POE::Quickie->new() if ref $self ne 'POE::Quickie';

    croak 'Program parameter not supplied' if !defined $args{Program};

    if ($args{AltFork} && ref $args{Program}) {
        croak 'Program must be a string when AltFork is enabled';
    }

    if ($args{AltFork} && $^O eq 'Win32') {
        croak 'AltFork does not currently work on Win32';
    }

    $self->_create_session() if !defined $self->{session_id};

    my ($exception, $wheel)
        = $poe_kernel->call($self->{session_id}, '_create_wheel', \%args);

    # propagate possible exception from POE::Wheel::Run->new()
    croak $exception if $exception;

    return $wheel->PID;
}

sub _create_wheel {
    my ($kernel, $self, $args) = @_[KERNEL, OBJECT, ARG0];

    my %data;
    for my $arg (qw(AltFork Timeout Input Program Context ProgramArgs
            StdoutEvent StderrEvent ExitEvent ResultEvent Tee Merged)) {
        next if !exists $args->{$arg};
        $data{$arg} = delete $args->{$arg};
    }

    if ($data{AltFork}) {
        my @inc = map { +'-I' => $_ } @INC;
        $data{Program} = [$^X, @inc, '-e', $data{Program}];
    }

    my $wheel;
    eval {
        $wheel = POE::Wheel::Run->new(
            StdinFilter => POE::Filter::Stream->new(),
            StdinEvent  => '_child_stdin',
            StdoutEvent => '_child_stdout',
            StderrEvent => '_child_stderr',
            Program     => $data{Program},
            (defined $data{ProgramArgs}
                ? (ProgramArgs => $data{ProgramArgs})
                : ()
            ),
            ($^O ne 'Win32'
                ? (CloseOnCall => 1)
                : ()
            ),
            %$args,
        );
    };

    if ($@) {
        chomp $@;
        return $@;
    }

    $data{obj} = $wheel;
    $data{extra_args} = $args;
    $self->{wheels}{$wheel->ID} = \%data;

    if (defined $data{Input}) {
        $wheel->put($data{Input});
    }
    else {
        $wheel->shutdown_stdin();
    }

    if ($data{Timeout}) {
        $data{alrm} =
            $kernel->delay_set('_child_timeout', $data{Timeout}, $wheel->ID);
    }

    $kernel->sig_child($wheel->PID, '_child_signal');

    return (undef, $wheel);
}

sub _exception {
    my ($kernel, $self, $ex) = @_[KERNEL, OBJECT, ARG1];
    chomp $ex->{error_str};
    warn __PACKAGE__.": Event $ex->{event} in session "
        .$ex->{dest_session}->ID." raised exception:\n  $ex->{error_str}\n";
    $kernel->sig_handled();
    return;
}

sub _child_signal {
    my ($kernel, $self, $pid, $status) = @_[KERNEL, OBJECT, ARG1, ARG2];
    my $id = $self->_pid_to_id($pid);

    my $data = $self->{wheels}{$id};

    my $s = $status >> 8;
    if ($s != 0 && !exists $data->{ExitEvent}
            && !exists $data->{ResultEvent}) {
        warn "Child $pid exited with nonzero status $s\n";
    }

    $kernel->alarm_remove($data->{alrm}) if $data->{Timeout};
    if ($data->{lazy}) {
        $self->{lazy}{$id} = {
            merged => $data->{merged},
            stdout => $data->{stdout},
            stderr => $data->{stderr},
            status => $status,
        }
    }
    delete $self->{wheels}{$id};

    if (defined $data->{ExitEvent}) {
        $kernel->call(
            $self->{parent_id},
            $data->{ExitEvent},
            $status,
            $pid,
            (defined $data->{Context}
                ? $data->{Context}
                : ()),
        );
    }

    if (defined $data->{ResultEvent}) {
        $kernel->call(
            $self->{parent_id},
            $data->{ResultEvent},
            $pid,
            $data->{stdout},
            $data->{stderr},
            $data->{merged},
            $status,
            (defined $data->{Context}
                ? $data->{Context}
                : ()),
        );
    }

    return;
}

sub _child_timeout {
    my ($self, $id) = @_[OBJECT, ARG0];
    $self->{wheels}{$id}{obj}->kill();
    return;
}

sub _child_stdin {
    my ($self, $id) = @_[OBJECT, ARG0];
    $self->{wheels}{$id}{obj}->shutdown_stdin();
    return;
}

sub _child_stdout {
    my ($kernel, $self, $output, $id) = @_[KERNEL, OBJECT, ARG0, ARG1];

    my $data = $self->{wheels}{$id};

    if ($data->{lazy} || defined $data->{ResultEvent}) {
        push @{ $data->{merged} }, $output;
        push @{ $data->{stdout} }, $output;

        if ($data->{lazy}{Tee}) {
            print $output, "\n";
        }
    }
    elsif (!exists $data->{StdoutEvent}) {
        print "$output\n";
    }
    elsif (defined (my $event = $data->{StdoutEvent})) {
        my $context = $data->{Context};
        $kernel->call(
            $self->{parent_id},
            $event,
            $output,
            $data->{obj}->PID,
            (defined $context ? $context : ()),
        );
    }

    return;
}

sub _child_stderr {
    my ($kernel, $self, $error, $id) = @_[KERNEL, OBJECT, ARG0, ARG1];

    my $data = $self->{wheels}{$id};

    if ($data->{lazy} || defined $data->{ResultEvent}) {
        push @{ $data->{merged} }, $error;
        push @{ $data->{stderr} }, $error;

        if ($data->{lazy}{Tee}) {
            $data->{lazy}{Merged}
                ? print $error, "\n"
                : warn $error, "\n";
        }
    }
    elsif (!exists $data->{StderrEvent}) {
        warn "$error\n";
    }
    elsif (defined (my $event = $data->{StderrEvent})) {
        my $context = $data->{Context};
        $kernel->call(
            $self->{parent_id},
            $event,
            $error,
            $data->{obj}->PID,
            (defined $context ? $context : ()),
        );
    }

    return;
}

sub _pid_to_id {
    my ($self, $pid) = @_;

    for my $id (keys %{ $self->{wheels} }) {
        return $id if $self->{wheels}{$id}{obj}->PID == $pid;
    }

    return;
}

sub killall {
    my $self = shift;
    $self = POE::Quickie->new() if ref $self ne 'POE::Quickie';
    $poe_kernel->call($self->{session_id}, '_killall', @_);
    return;
}

sub _killall {
    my ($kernel, $self, $signal) = @_[KERNEL, OBJECT, ARG0];

    $kernel->alarm_remove_all();

    for my $id (keys %{ $self->{wheels}}) {
        $self->{wheels}{$id}{obj}->kill($signal);
    }

    return;
}

sub processes {
    my ($self) = @_;
    $self = POE::Quickie->new() if ref $self ne 'POE::Quickie';

    my %wheels;
    for my $id (keys %{ $self->{wheels} }) {
        my $pid = $self->{wheels}{$id}{obj}->PID;
        $wheels{$pid} = $self->{wheels}{$id}{Context};
    }

    return \%wheels;
}

sub _lazy_run {
    my ($self, %args) = @_;

    my %run_args;
    if (@{ $args{RunArgs} } == 1 &&
        (!ref $args{RunArgs}[0] || ref ($args{RunArgs}[0]) =~ /^(?:ARRAY|CODE)$/)) {
        $run_args{Program} = $args{RunArgs}[0];
    }
    else {
        %run_args = @{ $args{RunArgs} };
    }

    my $pid = $self->run(
        %run_args,
        ExitEvent => undef,
        ($args{Tee} ? () : (StderrEvent => undef)),
        ($args{Tee} ? () : (StdoutEvent => undef)),
    );

    my $id = $self->_pid_to_id($pid);
    $self->{wheels}{$id}{lazy} = {
        Tee    => $args{Tee},
        Merged => $args{Merged},
    };

    my $parent_id = $poe_kernel->get_active_session->ID;
    $poe_kernel->refcount_increment($parent_id, __PACKAGE__);
    $poe_kernel->run_one_timeslice() while $self->{wheels}{$id};
    $poe_kernel->refcount_decrement($parent_id, __PACKAGE__);

    my $data = delete $self->{lazy}{$id};
    return $data->{merged}, $data->{status} if $args{Merged};
    return $data->{stdout}, $data->{stderr}, $data->{status};
}

sub quickie_run {
    my %args = @_;
    my $self = POE::Quickie->new();
    return $self->run(%args);
}

sub quickie {
    my @args = @_;
    my $self = POE::Quickie->new();

    return $self->_lazy_run(
        RunArgs => \@args
    );
}

sub quickie_tee {
    my @args = @_;
    my $self = POE::Quickie->new();
    return $self->_lazy_run(
        RunArgs => \@args,
        Tee     => 1,
    );
}

sub quickie_merged {
    my @args = @_;
    my $self = POE::Quickie->new();

    return $self->_lazy_run(
        RunArgs => \@args,
        Merged  => 1,
    );
}

sub quickie_tee_merged {
    my @args = @_;
    my $self = POE::Quickie->new();

    return $self->_lazy_run(
        RunArgs => \@args,
        Tee     => 1,
        Merged  => 1,
    );
}

1;

=encoding utf8

=head1 NAME

POE::Quickie - A lazy way to wrap blocking code and programs

=head1 SYNOPSIS

 use POE::Quickie;

 sub event_handler {
     # the "I'll wait until it's finished" approach, which will block your
     # session until the command has finished
     my ($stdout, $stderr, $exit_status) = quickie('foo.pl');
     print $stdout;

     # the "keep me posted" approach, which will give you each line of output
     # as it is appears
     quickie_run(
         Program     => ['foo.pl', 'bar'],
         StdoutEvent => 'stdout',
         Context     => 'remember this',
     );

     # the "get back to me when it's done" approach, which will notify you
     # of the entire output when the command has finished
     quickie_run(
         Program     => ['foo.pl', 'bar'],
         Context     => 'remember this',
         ResultEvent => 'result',
     );
 }

 sub stdout {
     my ($output, $context) = @_[ARG0, ARG1];
     print "got output: '$output' in the context of '$context'\n";
 }

 sub result {
     my ($pid, $stdout, $stderr, $merged, $status, $context) = @_[ARG0..$#_];
     print "got all this output in the context of '$context':\n";
     print "$_\n" for @$stdout;
 }

=head1 DESCRIPTION

If you need nonblocking access to an external program, or want to execute
some blocking code in a separate process, but you don't want to write a
wrapper module or some L<POE::Wheel::Run|POE::Wheel::Run> boilerplate code,
then POE::Quickie can help. You just specify what you're interested in
(stdout, stderr, and/or exit code), and POE::Quickie will handle the rest in
a sensible way.

It has some convenience features, such as killing processes after a timeout,
and storing process-specific context information which will be delivered with
every event.

There is also an even lazier API which suspends the execution of your event
handler and gives control back to POE while your task is running, the same
way L<LWP::UserAgent::POE|LWP::UserAgent::POE> does. This is provided by the
L<C<quickie_*>|/FUNCTIONS> functions which are exported by default.

=head1 METHODS

=head2 C<new>

Constructs a POE::Quickie object. You only need to do this if you want to
specify any of the parameters below, since a POE::Quickie object will be
constructed automatically when it is needed. The rest of the methods can
be called on the object (C<< $object->run() >>) or as class methods
(C<< POE::Quickie->run() >>). You can safely let the object go out of scope;
POE::Quickie will continue to run your processes until they finish.

Takes 3 optional parameters: B<'debug'>, B<'default'>, and B<'trace'>. These
will be passed to the object's L<POE::Session|POE::Session> constructor. See
its documentation for details.

=head2 C<run>

This method spawns a new child process. It returns its process id.

You can either call it with a single argument (string, arrayref, or coderef),
which will used as the B<'Program'> argument, or you can supply the following
key-value pairs:

B<'Program'> (required), will be passed to directly to
L<POE::Wheel::Run|POE::Wheel::Run/new>'s constructor.

B<'ProgramArgs'> (optional), will be passed directly to
L<POE::Wheel::Run|POE::Wheel::Run/new>'s constructor.

B<'Input'> (optional), a string containing the input to the process. This
string, if provided, will be sent immediately to the child, and its stdin
will then be shut down. B<Note:> no processing will be done on the data
before it is sent. For instance, if you are executing a program which expects
line-based input, be sure to end your input with a newline.

B<'StdoutEvent'> (optional), the event for delivering lines from the
process' STDOUT. If you don't supply this, they will be printed to the main
process's STDOUT. To explicitly ignore them, set this to C<undef>.

B<'StderrEvent'> (optional), the event for delivering lines from the
process' STDERR. If you don't supply this, they will be printed to the main
process' STDERR. To explicitly ignore them, set this to C<undef>.

B<'ExitEvent'> (optional), the event to be called when the process has exited.
If you don't supply this, a warning indicating the exit code will be printed
if it is nonzero. To explicitly ignore it, set this to C<undef>.

B<'ResultEvent'> (optional), like 'ExitEvent', but it will also contain all
the stdout/stderr generated by the child process.

B<'Context'> (optional), a variable which will be sent back to you with every
event. If you pass a reference, that same reference will be delivered back
to you later (not a copy), so you can update it as you see fit.

B<'Timeout'> (optional), a timeout in seconds after which the process will
be forcibly L<killed|POE::Wheel::Run/kill> if it is still running. There is
no timeout by default.

B<'AltFork'> (optional), if true, a new instance of the active Perl
interpreter (L<C<$^X>|perlvar>) will be launched with B<'Program'> (which
must be a string) as the code argument (L<I<-e>|perlrun>), and the current
L<C<@INC>|perlvar> passed as include arguments (L<I<-I>|perlrun>). Default
is false.

All other arguments will be passed to POE::Wheel::Run's
L<C<new>|POE::Wheel::Run/new> method. Useful if you want to specify the
input/output filters and such.

=head2 C<killall>

This L<kills|POE::Wheel::Run/kill> all processes which POE::Quickie is
managing for your session. Takes one optional argument, a signal name (e.g.
B<'SIGTERM'>).

=head2 C<processes>

Returns a hash reference of all the currently running processes. The key
is the process id, and the value is the context variable, if any.

=head1 OUTPUT

The following events might get sent to your session. The names correspond
to the options to L<C<run>|/run>.

=head2 StdoutEvent

=over 4

=item C<ARG0>: the chunk of STDOUT generated by the process

=item C<ARG1>: the process id of the child process

=item C<ARG2>: the context variable, if any

=back

=head2 StderrEvent

=over 4

=item C<ARG0>: the chunk of STDERR generated by the process

=item C<ARG1>: the process id of the child process

=item C<ARG2>: the context variable, if any

=back

=head2 ExitEvent

=over 4

=item C<ARG0>: the exit code (L<C<$?>|perlvar>) of the child process

=item C<ARG1>: the process id of the child process

=item C<ARG2>: the context variable, if any

=head2 ResultEvent

=over 4

=item C<ARG0>: the process id of the child process

=item C<ARG1>: an array of every chunk of stdout generated by the child process

=item C<ARG2>: an array of every chunk of stderr generated by the child process

=item C<ARG3>: an array of the interleaved stdout and stderr chunks

=item C<ARG4>: the exit code (L<C<$?>|perlvar>) of the child process

=item C<ARG5>: the context variable, if any

=back

=back

=head1 FUNCTIONS

=head2 C<quickie_run>

Equivalent to C<< POE::Quickie->run() >>, provided as a convenience.

=head2 Blocking functions

The following functions are modeled after the ones provided by
L<Capture::Tiny|Capture::Tiny>. They will not return until the executed
process has exited. However,
L<C<run_one_timeslice>|POE::Kernel/run_one_timeslice> in POE::Kernel will be
called in the meantime, so the rest of your application will continue to run.

They all take the same arguments as the L<C<run>|/run> method, except for the
B<'*Event'> and B<'Context'> arguments.

B<Note:> Since these functions block, you must be careful not to call them in
event handlers which were executed with C<< $poe_kernel->call() >> by other
sessions, so you don't hold them up. A simple way to avoid that is to
C<yield()> or C<post()> a new event to your session and do it from there.

=head3 C<quickie>

Returns 3 values: the stdout, stderr, and exit code (L<C<$?>|perlvar>) of the
child process.

=head3 C<quickie_tee>

Returns 3 values: an array of all stdout chunks, an array of all stderr
chunks, and the exit code (L<C<$?>|perlvar>) of the child process. In addition,
it will echo the stdout/stderr to your process' stdout/stderr.

=head3 C<quickie_merged>

Returns 2 values: an array of interleaved stdout and stderr chunks, and the
exit code (L<C<$?>|perlvar>) of the child process. Beware that stdout and
stderr in the merged result are not guaranteed to be properly ordered due to
buffering.

=head3 C<quickie_tee_merged>

Returns 2 values: an array of interleaved stdout and stderr chunks, and the
exit code (L<C<$?>|perlvar>) of the child process. In addition, it will echo
the merged stdout & stderr to your process' stdout. Beware that stdout and
stderr in the merged result are not guaranteed to be properly ordered due to
buffering.

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Hinrik E<Ouml>rn SigurE<eth>sson

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
