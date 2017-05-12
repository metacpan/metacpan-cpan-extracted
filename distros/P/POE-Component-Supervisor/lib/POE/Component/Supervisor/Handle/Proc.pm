use strict;
use warnings;
package POE::Component::Supervisor::Handle::Proc;

our $VERSION = '0.09';

use MooseX::POE 0.210;
use POSIX qw(WIFSIGNALED WIFEXITED WEXITSTATUS WTERMSIG);
use POE::Wheel::Run;
use Time::HiRes qw(time);
use Scalar::Util ();
use namespace::autoclean;

with qw(
    POE::Component::Supervisor::Handle
    POE::Component::Supervisor::LogDispatch
);

has wheel_parameters => (
    isa => "HashRef",
    is  => "ro",
    auto_deref => 1,
    default => sub { +{ } },
);

has enable_nested_poe => (
    isa => "Bool",
    is  => "ro",
    default => 1,
);

has start_nested_poe => (
    isa => "Bool",
    is  => "ro",
    default => 1,
);

has [map { "std${_}_callback" } qw(out err in)] => (
    isa => "CodeRef",
    is  => "rw",
    required => 0,
);

has program => (
    isa => 'ArrayRef|CodeRef',
    is  => "ro",
    required => 1,
);

has until_term => (
    isa => "Num|Undef",
    is  => "ro",
    default => 0.1,
);

has until_kill => (
    isa => "Num|Undef",
    is  => "ro",
    default => 10,
);

has wait_for => (
    isa => "Num|Undef",
    is  => "ro",
    lazy => 1,
    predicate => "has_wait_for",
    default => sub {
        my $self = shift;
        5 + ( $self->until_kill || $self->until_term || 0 );
    },
);

has _wheel => (
    isa => "POE::Wheel::Run",
    is  => "rw",
    init_arg => undef,
    clearer  => "_clear_wheel",
);

has pid => (
    isa => "Int",
    is  => "ro",
    init_arg => undef,
    writer => "_pid",
);

has exited => (
    isa => "Int",
    is  => "rw",
    init_arg  => undef,
    required  => 0,
    predicate => "has_exited",
    writer    => "_exited",
);

has exite_code => (
    isa => "Int",
    is  => "rw",
    init_arg  => undef,
    required  => 0,
    predicate => "has_exit_code",
    writer    => "_exit_code",
);

has exit_signal => (
    isa => "Int",
    is  => "rw",
    init_arg  => undef,
    required  => 0,
    predicate => "has_exit_signal",
    writer    => "_exit_signal",
);

sub STOP {
    $_[OBJECT]->logger->debug("stopping child handle session $_[SESSION]");
}

sub START {
    my ( $self, $kernel ) = @_[OBJECT, KERNEL];

    $kernel->refcount_increment( $self->get_session_id, __PACKAGE__ );

    my $program = $self->_wrapped_program;

    my $wheel = POE::Wheel::Run->new(
        StderrEvent => "stderr",
        StdoutEvent => "stdout",
        StdinEvent  => "stdin",
        $self->wheel_parameters,
        Program => $program,
    );

    my $pid = $wheel->PID;

    $self->_wheel($wheel);
    $self->_pid($pid);

    $self->notify_spawn( pid => $pid );

    $kernel->sig_child( $wheel->PID, "child_exit" );
}

sub _wrapped_program {
    my ( $self, $program ) = @_;

    $program ||= $self->program;

    if ( ref($program) eq 'CODE' ) {
        if ( $self->enable_nested_poe ) {
            my $also_start = $self->start_nested_poe;
            return sub {
                my @args = @_;

                $poe_kernel->stop;

                $program->(@args);

                $poe_kernel->run if $also_start;
            },
        }
    }

    return $program;
}

foreach my $event (qw(stdout stderr stdin)) {
    my $cb_name = "${event}_callback";
    event $event => sub {
        if ( my $cb = $_[OBJECT]->$cb_name ) {
            $cb->(@_);
        }
    };
}

event child_exit => sub {
    my ( $self, $exit ) = @_[OBJECT, ARG2];

    my $exit_code     = WIFEXITED($exit)   ? WEXITSTATUS($exit) : undef;
    my $exit_signal   = WIFSIGNALED($exit) ? WTERMSIG($exit)    : undef;

    $self->_exited($exit);
    $self->_exit_code($exit_code)     if defined $exit_code;
    $self->_exit_signal($exit_signal) if defined($exit_signal);

    $self->logger->info("child exited with status " . ($exit_code || "undef") . " ($exit), notifying supervisor");

    $self->notify_stop(
        pid         => $self->pid,
        exit        => $exit,
        exit_code   => $exit_code,
        exit_signal => $exit_signal,
    );

    $self->call("_cleanup");

};

event _cleanup => sub {
    my ( $self, $kernel ) = @_[OBJECT, KERNEL];

    if ( my $wheel = $self->_wheel ) {
       $wheel->shutdown_stdin;
       $self->_clear_wheel;
    }

    $kernel->alarm_remove_all();

    $kernel->refcount_decrement( $self->get_session_id, __PACKAGE__ );
};

sub stop {
    my $self = shift;

    $self->call("_stop_child");
}

event _stop_child => sub {
    my ( $self, $kernel, $heap ) = @_[OBJECT, KERNEL, HEAP];

    $self->call("_close_stdin");

    my $now = time;

    my ( $until_term, $until_kill ) = ( $self->until_term, $self->until_kill );

    my $start_term = defined($until_term) && $now + $until_term;
    my $start_kill = defined($until_kill) && $now + $until_kill;

    my $give_up    = $self->has_wait_for   && $now + $self->wait_for;

    $kernel->alarm_set( _term_loop    => $start_term, $start_kill || $give_up ) if $start_term;

    $kernel->alarm_set( _kill_loop    => $start_kill, $give_up ) if $start_kill;

    $kernel->alarm_set( _couldnt_kill => $give_up ) if $give_up;
};

event _close_stdin => sub {
    my ( $self, $kernel ) = @_[OBJECT, KERNEL];

    $self->logger->info("closing child stdin");

    if ( my $wheel = $self->_wheel ) {
       $wheel->shutdown_stdin;
    }
};

foreach my $sig (qw(term kill)) {
    my $SIG = uc($sig);

    my $event = "_${sig}_loop";

    event $event => sub {
        my ( $self, $kernel, $until, $iter ) = @_[OBJECT, KERNEL, ARG0 .. $#_];

        $iter ||= 0;
        my $delay = 2 ** $iter / 10; # exponential back off
        my $next_attempt = time() + $delay;

        if ( !defined($until) or $next_attempt < $until ) {
            $kernel->alarm_set( $event, $next_attempt, $until, $iter + 1 );
        } else {
            undef $delay;
        }

        $self->logger->info("sending SIG$SIG, attempt #" . ( $iter + 1) . ( $delay ? ", next attempt in $delay" : " (last attempt)" ));

        $self->_wheel->kill($SIG);
    };
}

event _couldnt_kill => sub {
    die "couldn't kill child";
};

sub is_running {
    my $self = shift;
    not $self->has_exited;
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=head1 NAME

POE::Component::Supervisor::Handle::Proc - A supervisor child handle for a POSIXish process.

=head1 VERSION

version 0.09

=head1 SYNOPSIS

    # created by POE::Component::Supervisor::Supervised::Proc

=head1 DESCRIPTION

These objects manage a real UNIX process (signalling, monitoring) within a
L<POE::Component::Supervisor>.

=head1 SIGNALLING

=for stopwords backoff durations

In order to kill a child process, first the child's standard input is closed,
then the C<TERM> signal is sent, and after a wait period the C<KILL> signal is
sent.

If the child has not died by the time the C<KILL> loop times out then an error
is thrown (this happens under weird OS scenarios and shouldn't happen
normally).

The attributes C<until_term>, C<until_kill> and C<wait_for> determine the
durations of these loops.

Initially inputs will be closed. Then, after C<until_term> seconds have passed
the C<TERM> sending loop will start, sending the C<TERM> signal with an
exponential backoff.

When C<until_kill> seconds have passed, from the time of the C<stop> method
being called, the C<TERM> loop will be stopped, and instead the C<KILL> signal
will be sent, also with an exponential backoff.

From the time of the C<stop> method being called the handle will wait for a
maximum of C<wait_for> seconds before giving up on the child process.

Any of these attributes may be set to C<undef> to disable their corresponding
behaviors (suppress sending of a certain signal, or wait indefinitely).

=head1 ATTRIBUTES

B<NOTE>: All the attributes are generally passed in by
L<POE::Component::Supervisor::Supervised::Proc>, the factory for this class.

They are documented here because that is where their behavior is defined.

L<POE::Component::Supervisor::Supervised::Proc> will borrow all the attributes
from this class that have an C<init_arg>, and as such they should be passed to
L<POE::Component::Supervisor::Supervised::Proc/new>, while this class is never
instantiated directly..

=over 4

=item until_term

The time to wait after closing inputs, and before sending the C<TERM> signal.
Defaults to one tenth of a second.

Set to C<undef> to disable sending the C<TERM> signal.

=item until_kill

The time to wait after closing inputs, and before sending the C<KILL> signal.
Defaults to 10 seconds.

Set to C<undef> to disable sending the C<KILL> signal.

=item wait_for

How long to keep sending exit signals for.

Defaults to

    5 + ( $self->until_kill || $self->until_term || 0 )

=item enable_nested_poe

Whether or not to call L<POE::Kernel/stop> in the child program, before the
callback. Only applies to code references.

This allows a nested POE kernel to be started in the forked environment without
needing to C<exec> a new program.

Defaults to true.

=item start_nested_poe

Whether or not to call L<POE::Kernel/run> in the child program, after the callback. Only applies to
code references.

Defaults to true.

=item program

A coderef or an array ref. Passed as the C<Program> parameter to the wheel, but
may be wrapped depending on the values of C<enable_nested_poe> and
C<start_nested_poe> if it's a code ref.

Required.

=item wheel_parameters

Additional parameters to pass to L<POE::Wheel::Run/new>.

=item stdin_callback

=item stdout_callback

=item stderr_callback

Callbacks to be fired when the corresponding L<POE::Wheel::Run> events are
handled.

This only affects the default event handlers, if you override those by passing
your own C<wheel_parameters> these callbacks will never take effect.

The arguments are passed through as is, see L<POE::Wheel::Run> for the details.

Not required.

=item pid

Read only attribute containing the process ID.

=item exited

=item exit_code

=item exit_signal

After the process has exited these read only attributes are filled in with the exit information.

C<exited> is the raw value of C<$?>, and C<exit_code> and C<exit_signal> are
the values of applying C<WEXITSTATUS> and C<WTERMSIG> to that value.

See L<POSIX> for details.

=item use_logger_singleton

Changes the default value of the original L<MooseX::LogDispatch> attribute to
true.

=back

=head1 METHODS

=over 4

=item new

Never called directly, but called by L<POE::Component::Supervisor::Supervised::Proc>.

=item stop

Stop the running process

=item is_running

Check whether or not the process is still running.

=back

=head1 EVENTS

All L<POE> events supported by this object are currently internal, and as such
the session corresponding to this object provides no useful L<POE> interface.

=cut
