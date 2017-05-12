package POE::Component::ProcTerminator::Batch;
use strict;
use warnings;
use Proc::Terminator;
use Moo;

extends 'Proc::Terminator::Batch';
has timer_id => (is => 'rw');
has failure_callback => (
    is => 'ro',
    isa => sub { ref $_[0] eq 'CODE'
        or die "Failure callback should be a CODE reference" }
);
has cleanup_flags => ( is => 'rw', default => 0 );

package POE::Component::ProcTerminator;
use warnings;
use strict;
use POE::Sugar::Attributes;
use POE;
use POE::Session;
use Proc::Terminator;
use base qw(POE::Sugar::Attributes Exporter);
use Class::Struct;
use Time::HiRes qw(time);
use POSIX qw(:signal_h);

our @EXPORT;
our $DefaultSession = "proc_terminator";

use Constant::Generate [qw(
    SIGKILL_LAST
    SIGKILL_ONLY
    CLEANUP_BLOCK
)], -type => 'bit', -export => 1, -prefix => 'PROCTERMf_';

struct
    'POE::Component::ProcTerminator::SessionInfo' =>
    [
        # hash of 'batches', indexed by their timer IDs
        batches => '*%',
        
        # default options
        defaults => '*%'
        
    ];
    
our $VERSION = 0.03;


sub spawn {
    my ($cls,%options) = @_;
    my $alias = delete $options{Alias};
    $alias ||= $DefaultSession;

    my $inline_states =
        POE::Sugar::Attributes->inline_states(__PACKAGE__, $alias);
    
    my $sessinfo = POE::Component::ProcTerminator::SessionInfo->new();
    $sessinfo->defaults(\%options);
    POE::Session->create(
        inline_states => $inline_states,
        heap => $sessinfo
    );
}

sub _do_terminate :Event(terminate)
{
    my ($sessinfo,$pids,$options) = @_[HEAP, ARG0..ARG2];
    $options ||= {};
    $options = { %{ $sessinfo->defaults }, %$options };
    
    $options->{cleanup_flags} ||= 0;
    
    if (delete $options->{max_wait}) {
        warn "max_wait does not make sense in POE::Component::ProcTerminator";
    }
    my $batch = POE::Component::ProcTerminator::Batch->with_pids(
        $pids,
        max_wait => 0,
        %$options
    );
    $batch->begin_time(time);
    my $ret = $batch->loop_once;
    if ($ret) {
        my $new_aid =$_[KERNEL]->delay_set(
            _grace_next => $batch->grace_period,
            $batch
        );
        $batch->timer_id($new_aid);
    } elsif ((!defined $ret) && $batch->failure_callback) {
        $batch->failure_callback->($batch);
    }
}

sub _grace_next :Event {
    my ($sessinfo,$batch) = @_[HEAP,ARG0];
    my $ret = $batch->loop_once();
    if ($ret) {
        my $new_aid = $_[KERNEL]->delay_set(
            $_[STATE],
            $batch->grace_period,
            $batch,
        );
        $batch->timer_id($new_aid);
        
    } else {
        if ( (!defined $ret) && $batch->failure_callback ) {
            $batch->failure_callback->($batch);
        }
        delete $sessinfo->batches->{$batch->timer_id};
    }
}


sub _unknown :Event(_default)
{
    my ($event,$args) = @_[ARG0,ARG1];    
    warn "Unhandled Event '$event'";
}


sub _clean_all :Stop {
    my $sessinfo = $_[HEAP];
    
    # iterate through all the batches. Figure out which ones should
    # be killed immediately
    my $remaining_batch = Proc::Terminator::Batch->with_pids([]);
    my $counter = 0;
    
    while (my ($aid,$batch) = each %{$sessinfo->batches}) {
        if ($batch->cleanup_flags & PROCTERMf_SIGKILL_ONLY) {
            $batch->cleanup_flags(0);
            kill (SIGKILL, $batch->pid);
            $_[KERNEL]->alarm_remove($batch->timer_id);            
        } elsif ($batch->cleanup_flags & PROCTERMf_SIGKILL_LAST) {
            while (my ($pid,$ctx) = each %{$batch->procs}) {
                if ($ctx->siglist->[$#{$ctx->siglist}] != SIGKILL) {
                    push @{$ctx->siglist}, SIGKILL;
                }
            }
        }
        
        delete $sessinfo->batches->{$aid};
        
        if (($batch->cleanup_flags & PROCTERMf_CLEANUP_BLOCK) == 0) {
            $batch->loop_once();
        } else {
            # cleanup..
            @{$remaining_batch->procs}{keys %{$batch->procs}} =
                values %{$batch->procs};
        }
    }
    
    if (%{$remaining_batch->procs}) {
        $remaining_batch->max_wait(5); # configurable maybe?
        $remaining_batch->begin_time(time);
        while ($remaining_batch->loop_once) {
            sleep(0.25);
        }
    }
    
    # ensure the final signal is indeed sent..
    while (my ($pid,$ctx) = each %{$remaining_batch->procs}) {
        my $sig = pop @{$ctx->siglist};
        if ($sig) {
            kill ($sig, $ctx->pid);
        }
    }
}

1;

__END__

=head1 NAME

POE::Component::ProcTerminator - Safely and easily kill runaway processes

=head1 DESCRIPTION

This is a POE component wrapping the functionality of L<Proc::Terminator>, but
using POE's timers and event loop instead of the built-in (and obviously blocking)
sleep-based loop.

=head1 SYNOPSIS

Set up the component..

    POE::Component::ProcTerminator->spawn(Alias => "proc_terminator");
    
Later, in your code..

    $_[KERNEL]->call(proc_terminator =>
                    terminate =>
                    $a_pid,
                    {
                        siglist => [ SIGINT, SIGTERM, SIGKILL ]
                    });
                    
And that's all!


=head1 DESCRIPTION

Semantics here are identical to that specified in L<Proc::Terminator>. This
manpage describes feature specific to the POE component

=head2 spawn(Alias => "a name", %options..)

If the C<Alias> parameter is missing, then it will spawn the default session,
called C<proc_terminator>

Further options are taken as defaults to be used for subsequent calls to
L</terminate>


=head2 $kernel->post($alias, terminate => $pid, { other => options })

Instruct the component to begin trying to kill C<$pid>, where C<$pid> can either
be a single PID, or an array reference of PIDs.

The second argument may be an optional hashref of options, accepting the same
kinds of things that L<Proc::Terminator>'s C<proc_terminate> does.

The more relevant options are

=over

=item siglist

A list of signals which will be used to kill off the process. Signals are
tried in succession, until the process is either dead or there are no more signals
left in the list. The defaults exist in C<@Proc::Terminator::DefaultSignalOrder>

=item grace_period

An interval (in seconds) to wait between shifting the signal list (specified in
C<siglist>). In the world of POE, this effectively means how often the timer
event will be called.

=back

Some additional options:

=over

=item failure_callback

If for whatever reason C<Proc::Terminator> is unable to kill your process, this
callback will be invoked with a C<Proc::Terminator::Batch> as its sole argument.
See L<Proc::Terminator> for documentation on that object.

=item cleanup_flags

Control the behavior of C<POE::Component::ProcTerminator> when the session
terminates prematurely (e.g. the kernel is being shut down, or some other exceptional
terminal condition has occured).

The default behavior is to not do anything.

This value is one or more of the following flags, OR'd together (these are
sub constants, exported to your namespace).

=over 2

=item PROCTERMf_CLEANUP_BLOCK

This instructs the cleanup handler to block and loop for this batch, as
L<Proc::Terminator> does in the synchronous API. The maximum time each batch
can block is 5 seconds (though this might be configurable).

=item PROCTERMf_SIGKILL_LAST

If C<SIGKILL> was not in the original list of signals to send to the process,
then push it to the end of the signal-to-send stack. This only makes sense
with the C<PROCTERMf_CLEANUP_BLOCK>

=item PROCTERMf_SIGKILL_ONLY

Blindly sends a C<SIGKILL> to the remaining processes. It does not make sense to
use this flag with the other flags.

=back

=back

=head2 NOTES

When POE shuts down and the component is about to stop, it will call an iteration
of the loop (hopefully killing it). In the future I might want to do something like
either invoke a 'real' Proc::Terminate session (with a reasonable time limit) or
nuke them all with C<SIGKILL>. Dunno?

=head1 SEE ALSO

L<Proc::Terminator>

=head1 AUTHOR & COPYRIGHT

Copyright (C) 2012 M. Nunberg

You may use and distribute this software under the same terms and conditions as
Perl itself.