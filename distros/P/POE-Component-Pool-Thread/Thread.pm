package POE::Component::Pool::Thread;
# ----------------------------------------------------------------------------- 
# "THE BEER-WARE LICENSE" (Revision 43) borrowed from FreeBSD's jail.c: 
# <tag@cpan.org> wrote this file.  As long as you retain this notice you 
# can do whatever you want with this stuff. If we meet some day, and you think 
# this stuff is worth it, you can buy me a beer in return.   Scott S. McCoy 
# ----------------------------------------------------------------------------- 

use strict;
use warnings FATAL => "all";
 no warnings 'numeric'; # grep int hack
use threads;
use threads::shared;
use Thread::Semaphore;
use Thread::Queue;
use IO::Handle;
use POE qw( Pipe::OneWay Filter::Line Wheel::ReadWrite );
use Fcntl;

# Circumvent warnings...
BEGIN { run POE::Kernel }

*VERSION = \0.015;

use constant DEBUG => 0;

sub new {
    die __PACKAGE__, "->new() requires a balanced list" unless @_ % 2;

    my ($type, %opt) = @_;
    
    $opt{inline_states} ||= {};
    $opt{StartThreads}  ||= 0;
    $opt{MinFree}       ||= 2;
    $opt{MaxFree}       ||= 10;

    POE::Session->create    
    ( inline_states => {
        %{ $opt{inline_states} },

        _start => sub {
            my ($kernel, $heap) = @_[ KERNEL, HEAP ];

            $kernel->alias_set($opt{Name}) if $opt{Name};

            $heap->{queue} = [];

            my ($pipe_in, $pipe_out) = POE::Pipe::OneWay->new;
            $heap->{pipe_out} = $pipe_out;

            die "Unable to create pipe" 
            unless defined $pipe_in and defined $pipe_out;

            $heap->{wheel} = POE::Wheel::ReadWrite->new
                ( Handle      => $pipe_in,
                  InputEvent  => "-thread_talkback",
                  ErrorEvent  => "-thread_talkerror",
                );

            for (1 .. $opt{StartThreads}) {
                $kernel->call($_[SESSION], "-spawn_thread");
            }

            goto $opt{inline_states}{_start} if $opt{inline_states}{_start};
        },

        _stop => sub {
            my ($kernel, $heap) = @_[ KERNEL, HEAP ];

            DEBUG && warn "Joining all threads";
            for my $tid (keys %{ $heap->{thread} }) {
                $heap->{thread}{$tid}{iqueue}->enqueue("last");
                $heap->{thread}{$tid}{thread}->join;
            }

            goto $opt{inline_states}{_stop} if $opt{inline_states}{_stop};
        },

        _default => sub {
            die "_default caught state: ", $_[ARG0];
        },

        -thread_talkerror => sub { die $_[ARG0], $_[ARG2] },

        -thread_talkback => sub {
            my ($kernel, $heap, $input) = @_[ KERNEL, HEAP, ARG0 ];
            my ($tid, $command) = ($input =~ m/(\d+): (\w+)/);

            DEBUG and warn "Recieved: $input";

            # Depending upon the settings of perlvar's, its possible we may get
            # some garbage through here.
            if (defined $command) {
                if ($command eq "cleanup") {
                    $kernel->yield(-execute_cleanup => $tid);
                }
                elsif ($command eq "collect") {
                    $kernel->yield(-collect_garbage => $tid);
                }
            }
        },

        -collect_garbage => sub {
            DEBUG && warn "GC Called, thread exited";
            
            my ($kernel, $session, $heap, $tid) = 
                @_[ KERNEL, SESSION, HEAP, ARG0 ];

            my $tdsc = delete $heap->{thread}{$tid} or return;

            $tdsc->{thread}->join;

            unless ($kernel->refcount_decrement($session->ID, "thread")) {
                delete $heap->{wheel};
            }

            delete $tdsc->{$_} for keys %$tdsc;
        },

        -execute_cleanup => sub {
            my ($kernel, $session, $heap, $tid) = 
                @_[ KERNEL, SESSION, HEAP, ARG0 ];

            DEBUG && warn "GC Called, thread finished task";

            my $thread = $heap->{thread};
            my @free   = grep ${ $_->{semaphore} }, values %$thread;

            my $queue  = $heap->{queue};
            my $rqueue = $heap->{thread}{$tid}{rqueue};
            my $iqueue = $heap->{thread}{$tid}{iqueue};

            if ($rqueue->pending) {
                if ($opt{CallBack}) {
                    DEBUG && warn "Dispatching CallBack";
                    $opt{CallBack}->( @_[0..ARG0-1], @{$rqueue->dequeue} );
                }
            }

            if (@$queue) {
                my $args = &share([]);
                push @$args, @{ shift @$queue };

                $iqueue->enqueue($args);
            }
            elsif (@free > $opt{MaxFree}) {
                (shift @free)->{iqueue}->enqueue("last");
            }
        },

        -spawn_thread => sub {
            my ($kernel, $session, $heap) = @_[ KERNEL, SESSION, HEAP ];
            
            return if $opt{MaxThreads} == scalar keys %{ $heap->{thread} };
            DEBUG && warn "Spawning a new thread";

            my $semaphore   = Thread::Semaphore->new;
            my $iqueue      = Thread::Queue->new;
            my $rqueue      = Thread::Queue->new;
            my $pipe_out    = $heap->{pipe_out};
            my $queue       = $heap->{queue};

            my $thread      = threads->create
                ( \&thread_entry_point, 
                  $semaphore, 
                  $iqueue, 
                  $rqueue, 
                  fileno($pipe_out),
                  $opt{EntryPoint} );

            $kernel->refcount_increment($session->ID, "thread");

            $heap->{thread}{$thread->tid} = { 
                semaphore   => $semaphore,
                iqueue      => $iqueue,
                rqueue      => $rqueue,
                thread      => $thread,
                lifespan    => 0, # Not currently used
            };

            if (@$queue) {
                my $args = &share([]);
                push @$args, @{ shift @$queue };

                $iqueue->enqueue($args);
            }
        },

        run => sub {
            my ($kernel, $heap, @arg) = @_[ KERNEL, HEAP, ARG0 .. $#_ ];

            DEBUG && warn "Assigned a task";

            my $thread = $heap->{thread};
            my @free   = grep ${ $_->{semaphore} }, values %$thread;

            if (@free) {
                my $tdsc = shift @free;

                # Trickery so we can pass this through Thread::Queue;
                my $sharg = &share([]);

                # Just to be polite...
                lock $sharg;
                push @$sharg, @arg;

                DEBUG and warn "Enqueueing on ", $tdsc->{thread}->tid;

                $tdsc->{iqueue}->enqueue($sharg);
            }
            else {
                push @{ $heap->{queue} }, [ @arg ];
            }

            if (@free < $opt{MinFree}) {
                unless (scalar(keys %$thread) >= $opt{MaxThreads}) {
                    $kernel->yield("-spawn_thread");
                }
            }
        },

        shutdown => sub {
            my ($kernel, $heap) = @_[ KERNEL, HEAP ];

            $heap->{shutdown} = 1;
            $kernel->alias_remove($opt{Name});

            for my $thread (values %{ $heap->{thread} }) {
                $thread->{iqueue}->enqueue("last");
            }
        },
      },
    );
}

sub thread_entry_point {
    my ($semaphore, $iqueue, $rqueue, $pipe_fd, $task) = @_;

    my $pipe = IO::Handle->new_from_fd($pipe_fd, "a") or die $!;

    # XXX Hack
    my $code = $task;

    # Just incase
    local $\ = "\n";

    while (my $action = $iqueue->dequeue) {
        DEBUG and warn threads->self->tid, ": recieved action";
        $semaphore->down;

#       lock $action;

        unless (ref $action) {
            if ($action eq "last") {
                $$semaphore = -1;
                last;
            }
        }

        else { 
            my $arg = $action;
#           lock $arg;

            # Just incase...
            my $result = &share([]);
            push @$result, $code->(@$arg);

            DEBUG and warn threads->self->tid, ": Enqueuing result: @$result";
            $rqueue->enqueue($result);
        }

        DEBUG and warn threads->self->tid, ": Requesting cleanup";

        $pipe->print( threads->self->tid, ": cleanup" );
        $pipe->flush;

        $semaphore->up;
    }

    $pipe->print( threads->self->tid, ": collect" );
    $pipe->flush;
    DEBUG and warn threads->self->tid, ": Requesting Destruction";
}

1;

=head1 NAME

POE::Component::Pool::Thread - A POE Managed Boss/Worker threadpool.

=head1 SYNOPSIS

 use POE qw( Component::Pool::Thread );
 
 POE::Component::Pool::Thread->new
    ( MinFree       => 2,
      MaxFree       => 5,
      MaxThreads    => 15,
      StartThrneads => 5,
      Name          => "ThreadPool",
      EntryPoint    => \&thread_entry_point,
      CallBack      => \&result_handler,
      inline_states => {
          _start => sub {
               my ($kernel, $heap) = @_[ KERNEL, HEAP ];

               # We are inside the component session
               $kernel->yield(run => @arguements);

               $kernel->post(ThreadPool => run => @arguements);
          },
      }
    );

 sub thread_entry_point {
    my (@arguements) = @_;

    return 1;
 }

 sub result_handler {
    my ($kernel, $result) = @_[ KERNEL, ARG0 ];

    $result == 1;
 }

=head1 DESCRIPTION

This is an expand-on-demand thread pool managed through a POE session in a
manner that does not interfer with cooperative multitasking.  A single pipe is
created, each thread communicates its state to the main process through this
pipe.  No serialization occurs (these are threads, not child processes), so
execution is very fast.

=head1 RATIONALE

Cooperative Co-routine type programming isn't always available.  Some third
party software (dependant libraries and/or modules) and particular tasks block
processing weither you like it or not.

Creation of threads is alot of overhead, infact quite a bit more overhead under
the current implementation of ithreads than fork is.  Allocating these
resources before you need them is an obvious solution to this problem, if you
create the threads and re-use them, they're around when you need them without
the horrendously slow threads->create() method.

Communicating the results of a threads processing requires allowing it to exit.
This means you will require the overhead of threads->create() next time you
need to accomplish this task.  With a thread pool designed in this fasion, the
main thread itself has its own process loop.  The result of each iteration is
passed through a thread safe queue, allowing you to collect the results of a
threads execution without the thread exiting.

=head1 CONSTRUCTOR

=over 4

=item new MANY THINGS

The new constructor is the only package method available with this package.  It
creates a POE thread pool session which you describe in the following
arguements.

=over 4

=item EntryPoint CODE

This arguement describes the entry point of the thread and is required.  In the
actual implementation, this is not actually an entry point.  This is instead a
coderef the thread will call repeatedly.  The arguements of this subroutine
will be the arguements recieved by the controlling session.  In order to pass
references as arguements, each reference must be shared (L<threads::shared>).
Filehandles and blessed references cannot be shared.  You will have to
translate them yourself.  With file handles, you can pass simply the file
descriptor and reopen it in the child thread.  With blessed references, you can
pass the datastructure only, and rebless the reference in the thread.

=item CallBack CODE

This arguement descirbes the result handler, which is where the captured
results of a threads last execution are sent.  As with EntryPoint subroutine
arguements, any data structures you wish to pass through return results must be
explicitly shared (L<threads::shared>).

=item Name ALIAS

This arguement descirbes the default alias your threadpool session is given.

=item StartThreads INTEGER

This arguement describes the number of threads the component will create during
its "_start" state, or when the POE Session is being started.  This should be a
number greater than MinFree and less than or equal to MaxFree.

=item MaxThreads INTEGER

This arguement descirbes the maximum number of threads this component will
create for this task.  If the component is assigned more tasks than threads, it
will place the remaining tasks in an internal FIFO queue and assign them
threads as they complete their tasks.

=item MinFree INTEGER

This arguement sets the minimum number of free threads to maintain.  When the
component is assigned a new task, if there are less than this number of threads
available, it will yield a request to create a new thread at the components
convience.

=item MaxFree INTEGER

This arguement provides the maximum number of free threads to maintain.  Upon
completion of a task, this value is checked.  If there are more free threads
than this value available, the oldest thread is asked to shut down.

=back

=back

=head1 INLINE STATES

=over 4

=item run LIST

The run state assigns a task to one of the free threads in the pool, or appends
the task to the components internal FIFO if no threads are available and our
thread resources are exhausted.

=item shutdown

This state politely asks all threads to exit, deletes the wheel watching the
one way pipe threads are using to communicate, removes the session alias and
awaits a clean session shutdown.

=back

=head1 BUGS

Oh I'm pretty sure of it.  If you find some, let me know.

=head1 THANKS

Matt Cashner

Rocco Caputo

=head1 AUTHOR

Scott McCoy (tag@cpan.org)

=cut
