package Schedule::LongSteps;
$Schedule::LongSteps::VERSION = '0.023';
# ABSTRACT: Manage long term processes over arbitrary large spans of time.

use Moose;

=head1 NAME

Schedule::LongSteps - Manage long term processes over arbitrary large spans of time.


=head1 ABSTRACT

=for html <a href="https://travis-ci.org/skinnyjeans/Schedule-LongSteps"><img src="https://travis-ci.org/skinnyjeans/Schedule-LongSteps.svg?branch=dynamo"></a>

This attempts to solve the problem of defining and running a set of potentially conditional steps accross an arbitrary long timespan.

An example of such a process would be: "After an order has been started, if more than one hour, send an email reminder every 2 days until the order is finished. Give up after a month"". You get the idea.

Such a process is usually a pain to implement and this is an attempt to provide a framework so it would make writing and testing such a process as easy as writing and testing a good old Class.

=head1 INCOMPATIBLE CHANGES

From 0.013

The API of Storage has changed between 0.012 and 0.013. If you've written your own storage, you
will want to manage that. If not, then don't worry about it.

=head1 CONCEPTS

=head2 Process

A Process represents a set of logically linked steps that need to run over a long span of times (hours, months, even years..). It persists in a Storage.

At the logical level, the persistant Process has the following attributes (See L<Schedule::LongSteps::Storage::DBIxClass> for a comprehensive list):

- what. Which step should it run next.

- run_at. A L<DateTime> at which this next step should be run. This allows running a step far in the future.

- status. Is the step running, or paused or is the process terminated.

- state. The persistant state of your application. This should be a pure Perl hash (JSONable).

Users (you) implement their business process as a subclass of L<Schedule::LongSteps::Process>. Such subclasses can have contextual properties
as Moose properties that will have to be supplied by the L<Schedule::LongSteps> management methods.

=head2 Steps

A step is simply a subroutine in a process class that runs some business code. It always returns either a new step to be run
or a final step marker.

=head2 Storage

A storage provides the backend to persist processes. Build a Schedule::LongSteps with a storage instance.

See section PERSISTANCE for a list of available storage classes.

=head2 Manager: Schedule::LongSteps

A L<Schedule::LongSteps> provides an entry point to all thing related to Schedule::LongSteps process management.
You should keep once instance of this in your application (well, one instance per process) as this is what you
are going to use to launch and manage processes.

=head1 QUICK START AND SYNOPSIS

First write a class to represent your long running set of steps

  package My::Application::MyLongProcess;

  use Moose;
  extends qw/Schedule::LongSteps::Process/;

  # Some contextual things.
  has 'thing' => ( is => 'ro', required => 1); # Some mandatory context provided by your application at each regular run.

  # The first step should be executed after the process is installed on the target.
  sub build_first_step{
    my ($self) = @_;
    return $self->new_step({ what => 'do_stuff1', run_at => DateTime->now() });
  }

  sub do_stuff1{
     my ($self) = @_;

      # The starting state
      my $state = $self->state();

      my $thing = $self->thing();

     .. Do some stuff and return the next step to execute ..

      return $self->new_step({ what => 'do_stuff2', run_at => DateTime->... , state => { some => 'jsonable', hash => 'ref'  ]  });
  }

  sub do_stuff2{
      my ($self, $step) = @_;

      $self->wait_for_steps('do_stuff1', 'do_stuff2' );

      .. Do some stuff and terminate the process or goto do_stuff1 ..

       if( ... ){
           return Schedule::LongSteps::Step->new({ what => 'do_stuff1', run_at => DateTime->... , state => { some jsonable structure } });
       }
       return $self->final_step({ state => { the => final, state => 1 }  }) ;
  }

  __PACKAGE__->meta->make_immutable();

Then in you main application do this once per 'target':

   my $dbic_storage = Schedule::LongSteps::Storage::DBIxClass->new(...);
   # Keep only ONE Instance of this in your application.
   my $longsteps = Schedule::LongSteps->new({ storage => $dbic_storage });
   ...

   $longsteps->instantiate_process('My::Application::MyProcess', { thing => 'whatever' }, { the => 'init', state => 1 });

Then regularly (in a cron, or a recurring callback):

   my $dbic_storage = Schedule::LongSteps::Storage::DBIxClass->new(...);
   # Keep only ONE instance of this in your application.
   my $longsteps = Schedule::LongSteps->new({ storage => $dbic_storage });
   ...

   $long_steps->run_due_steps({ thing => 'whatever' });

=head1 EXAMPLE

Look at L<https://github.com/jeteve/Schedule-LongSteps/blob/master/t/fullblown.t> for a full blown working
example.

=head1 PERSISTANCE

The persistance of processes is managed by a subclass of L<Schedule::LongSteps::Storage> that you should instantiate
and given to the constructor of L<Schedule::LongSteps>

Example:

   my $dbic_storage = Schedule::LongSteps::Storage::DBIxClass->new(...);
   my $longsteps = Schedule::LongSteps->new({ storage => $dbic_storage });
   ...

Out of the box, the following storage classes are available:

=over

=item L<Schedule::LongSteps::Storage::Memory>

Persist processes in memory. Not very useful, except for testing. This is the storage of choice to unit test your processes.

=item L<Schedule::LongSteps::Storage::AutoDBIx>

Persist processes in a relational DB (a $dbh from L<DBI>). This is the easiest thing to use if you want to persist processes in a database, without having
to worry about creating a DBIx::Class model yourself. We recommend you give this storage its own dbh connection, segregated from the rest
of your application.

=item L<Schedule::LongSteps::Storage::DBIxClass>

Persist processes in an existing L<DBIx::Class> schema. Note that although this makes a reasonable attempts not to interfer
with your own transactions, we recommend that you build a instance of your schema with a dedicated and segregated L<DBI> connection
just for this LongSteps purpose.

=item L<Schedule::LongSteps::Storage::DynamoDB>

Persist processes in a DynamoDB table in AWS. Please consider this Alpha. Give it a go and report any issue!

=back

=head1 COOKBOOK

=head2 WRITING A NEW PROCESS

See 'QUICK START AND SYNOPSIS'

=head2 INSTANTIATING A NEW PROCESS

See 'QUICK START AND SYNOPSIS'

=head2 RUNNING PROCESS STEPS

See 'QUICK START AND SYNOPSIS

=head2 BEING NOTIFIED OF ANY OF YOUR PROCESS ERROR

Use the property 'on_error' on the Schedule::LongStep manager:


  my $longsteps = Schedule::LongStep->new({ storage => ..,
                                            on_error => sub{
                                              my ( $stored_process , $error ) = @_;
                                              .. do stuff with: ..
                                              $error, # The original error. Not trimmed, and can be an object raised by
                                                      # the process.
                                              $stored_process->error(), # The stored error. A string that might be trimmed.
                                              $stored_process->process_class(),
                                              $stored_process->state(), etc...
                                            }
                                           });

Note that an error in your error handler itself will result in the output of
a pure Perl warning and an emmission of a 'critical' level L<Log::Any> log event.

=head2 INJECTING PARAMETERS IN YOUR PROCESSES

Of course each instance of your process will most probably need to
act on different pieces of application data. The one and only way to
give 'parameters' to your processes is to specify an initial state when
you instantiate a process:

  $longsteps->instantiate_process('My::App', { app => $app } , { work => 'on' , this => 'user_id' });

=head2 INJECTING CONTEXT IN YOUR PROCESSES

Let's say you hold an instance of your application object:

  my $app = ...;

And you want to use it in your processes:

  package MyProcess;
  ...
  has 'app' => (is => 'ro', isa => 'My::App', required => 1);

You can inject your $app instance in your processes at instantiation time:

  $longsteps->instantiate_process('My::App', { app => $app });

And also when running the due steps:

  $longsteps->run_due_steps({ app => $app });

The injected context should be stable over time. Do NOT use this to inject parameters. (See INJECTING PARAMETERS).


=head2 PROCESS WRITING

This package should  be expressive enough for you to implement business processes
as complex as those given as an example on this page: L<https://en.wikipedia.org/wiki/XPDL>

Proper support for XPDL is not implemented yet, but here is a list of recipes to implement
the most common process patterns:

=head3 MOVING TO A FINAL STATE

Simply do in your step 'do_last_stuff' implementation:

   sub do_last_stuff{
      my ($self) = @_;
      # Return final_step with the final state.
      return $self->final_step({ state => { the => 'final' , state => 1 } });
   }

=head3 DO SOMETHING ELSE IN X AMOUNT OF TIME

   sub do_stuff{
        ...
        # Do the things that have to be done NOW
        ...
        # And in two days, to this
        return $self->new_step({ what => 'do_stuff_later', run_at => DateTime->now()->add( days => 2 ) ,  state => { some => 'new one' }});
   }


=head3 DO SOMETHING CONDITIONALLY

   sub do_choose{
      if( ... ){
         return $self->new_step({ what => 'do_choice1', run_at => DateTime->now() });
      }
      return $self->new_step({ what => 'do_choice2', run_at => DateTime->now() });
   }

   sub do_choice1{...}
   sub do_choice2{...}

=head3 FORKING AND WAITING FOR PROCESSES


  sub do_fork{
     ...
     my $p1 = $self->longsteps->instantiate_process('AnotherProcessClass', \%build_args , \%initial_state );
     my $p2 = $self->longsteps->instantiate_process('YetAnotherProcessClass', \%build_args2 , \%initial_state2 );
     ...
     return $self->new_step({ what => 'do_join', run_at => DateTime->now() , { processes => [ $p1->id(), p2->id() ] } });
  }

  sub do_join{
     return $self->wait_processes( $self->state()->{processes}, sub{
          my ( @terminated_processes ) = @_;
          my $state1 = $terminated_processes[0]->state();
          my $state2 = $terminated_processes[1]->state();
          ...
          # And as usual:
          return $self->...
     });
  }

=head1 ATTRIBUTES

=over

=item storage

An instance of a subclass of L<Schedule::LongSteps::Storage>. See SYNOPSIS.

=item on_error

A callback called like $on_error->( $stored_process , $error ). See COOKBOOK for an example

=item error_limit

Maximum size of error message to log and store. Defaults to 2000 characters.

=back

=head1 METHODS

=head2 uuid

Returns a L<Data::UUID> from the storage.

=head2 run_due_processes

Runs all the due processes steps according to now(). All processes
are given the context to be built.

Usage:

 # No context given:
 $this->run_due_processes();

 # With 'thing' as context:
 $this->run_due_processes({ thing => ... });

Returns the number of processes run

=head2 instantiate_process

Instantiate a stored process from the given process class returns a new process that will have an ID.

Usage:

  $this->instantiate_process( 'MyProcessClass', { process_attribute1 => .. } , { initial => 'state' });

=head2 find_process

Shortcut to $self->storage->find_process( $pid );

=head2 load_process

Returns a loaded process for a given pid, or undef if there is no process
associated with the PID.

An optional hash ref context can also be passed in
and will be used to load the process, a blank context is used if not provided.

    if( my $loaded_process = $self->load_process( $pid , $context ) ){
       ...
    }

=head2 revive

Revive a longstep process to a given step within a Longstep process.

A context is required when the reviving process contains required attributes
and when setting a step to reviving step. If no step is given then the process
will revive on the failed process step, when setting a step that doesn't
require a context, use an empty hashref '{}'.

If you need to modify the state before reviving the longstep process, it is
recommended to have a revive step ("revive_do_broken_step") which modifies
the state as needed and returns a next_step to continue the process.

This method will confess on any issues.

    eval {
        $self->revive( $pid, $context, $method_to_revive_to );
    };

=head1 SEE ALSO

L<BPM::Engine> A business Process engine based on XPDL, in Alpha version since 2012 (at this time of writing)

=head1 Copyright and Acknowledgement

This code is released under the Perl5 Terms by Jerome Eteve (JETEVE), with the support of Broadbean Technologies Ltd.

See L<perlartistic>

=for HTML <a href="https://travis-ci.org/jeteve/Schedule-LongSteps"><img src="https://travis-ci.org/jeteve/Schedule-LongSteps.svg?branch=master"></a>

=cut

use Class::Load;
use DateTime;
use Log::Any qw/$log/;

use Schedule::LongSteps::Storage::Memory;

has 'storage' => ( is => 'ro', isa => 'Schedule::LongSteps::Storage', lazy_build => 1);

has 'on_error' => ( is => 'ro', isa => 'CodeRef', default => sub{ return sub{}; } );

has 'error_limit' => ( is => 'ro', isa => 'Int' , default => 2000 );

sub _build_storage{
    my ($self) = @_;
    $log->warn("No storage specified. Will use Memory storage");
    return Schedule::LongSteps::Storage::Memory->new();
}


sub uuid{
    my ($self) = @_;
    return $self->storage()->uuid();
}

sub run_due_processes{
    my ($self, $context) = @_;
    $context ||= {};

    my @stored_processes = $self->storage->prepare_due_processes();
    my $process_count = 0;
    foreach  my $stored_process ( @stored_processes ){
        my $process_method = $stored_process->what();

        $process_count++;

        my $new_step_properties = eval{
            $log->info( "Will do $process_method on process ID=".$stored_process->id() );
            my $process = $self->_load_stored_process($stored_process,$context);
            $process->$process_method();
        };
        if( my $original_err = $@ ){

            # Stringify the error, just in case its an object.
            my $err = $original_err.'';
            if( length( $err ) > $self->error_limit() ){
                $log->warn("Error too long. Trimming to ".$self->error_limit());
                $err = substr( $err , 0 , $self->error_limit() );
            }
            $log->error("Error running process ".$stored_process->process_class().':'.$stored_process->id().' :'.$err);
            $self->storage()->update_process( $stored_process, {
                status => 'terminated',
                error => $err,
                run_at => undef,
                run_id => undef,
            });

            eval{ $self->on_error()->( $stored_process , $original_err ); };
            if( my $on_error_error = $@ ){
                warn("Error handler triggered an error: $on_error_error");
                $log->critical("Error handler triggered an error: $on_error_error");
            }

            next;
        }

        $self->storage()->update_process( $stored_process, {
            status => 'paused',
            run_at => undef,
            run_id => undef,
            %{$new_step_properties}
        });
    }
    return $process_count;
}

sub instantiate_process{
    my ($self, $process_class, $build_args, $init_state ) = @_;

    defined( $build_args ) or ( $build_args = {} );
    defined( $init_state ) or ( $init_state = {} );

    Class::Load::load_class($process_class);
    unless( $process_class->isa('Schedule::LongSteps::Process') ){
        confess("Class '$process_class' is not an instance of 'Schedule::LongSteps::Process'");
    }
    my $process = $process_class->new( { longsteps => $self, %{ $build_args } } );
    my $step_props = $process->build_first_step();

    my $stored_process = $self->storage->create_process({
        process_class => $process_class,
        status => 'pending',
        state => $init_state,
        %{$step_props}
    });
    return $stored_process;
}

sub find_process{
    my ($self, $pid) = @_;
    return $self->storage()->find_process($pid);
}

sub load_process {
    my ( $self, $pid, $context ) = @_;
    $context ||= {};

    my $stored_process = $self->find_process($pid);
    return unless $stored_process;
    return $self->_load_stored_process( $stored_process, $context );
}

sub revive {
    my ( $self, $process_id, $context, $revive_to  ) = @_;
    $context ||= {};

    my $stored_process = $self->find_process($process_id);
    confess "There is no $process_id to revive" unless $stored_process;

    confess("$process_id does not have a status of 'terminated'") if ( $stored_process->status() ne "terminated" );

    # load the process and check if process have the method to revive_to
    # if revive $revive_to was not passed, used the function we failed on.
    # and check that also, just in case we attempt to revive on a method
    # that was previously removed.
    my $loaded_process = $self->_load_stored_process($stored_process, $context);

    $revive_to = $stored_process->what() unless $revive_to;

    # check to see if we able to revive
    confess "Unable revive $process_id to $revive_to" unless $loaded_process->can($revive_to);

    # Set the process up to be revived.
    my $now = DateTime->now();
    $stored_process->what($revive_to);
    $stored_process->error(undef);
    $stored_process->status("paused");
    $stored_process->run_at( $now );
    $self->storage()->update_process( $stored_process, {
        what => $revive_to,
        error => undef,
        status => "paused",
        run_at => $now
    });

    return 1;
}

# load_class may croak when trying to load a module you that is not in the INC
# so to be safe make sure you put this in an eval, and handle the errors
# appropriately
sub _load_stored_process {
    my ( $self, $stored_process, $context ) = @_;
    $context ||= {};

    Class::Load::load_class( $stored_process->process_class() );
    return $stored_process->process_class()->new(
        {
            longsteps      => $self,
            stored_process => $stored_process,
            %{$context}
        }
    );
}



__PACKAGE__->meta->make_immutable();
