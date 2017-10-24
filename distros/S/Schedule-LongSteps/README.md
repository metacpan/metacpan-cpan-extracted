# NAME

Schedule::LongSteps - Manage long term processes over arbitrary large spans of time.

# ABSTRACT

<div>
    <a href="https://travis-ci.org/skinnyjeans/Schedule-LongSteps"><img src="https://travis-ci.org/skinnyjeans/Schedule-LongSteps.svg?branch=dynamo"></a>
</div>

This attempts to solve the problem of defining and running a set of potentially conditional steps accross an arbitrary long timespan.

An example of such a process would be: "After an order has been started, if more than one hour, send an email reminder every 2 days until the order is finished. Give up after a month"". You get the idea.

Such a process is usually a pain to implement and this is an attempt to provide a framework so it would make writing and testing such a process as easy as writing and testing a good old Class.

# INCOMPATIBLE CHANGES

From 0.013

The API of Storage has changed between 0.012 and 0.013. If you've written your own storage, you
will want to manage that. If not, then don't worry about it.

# CONCEPTS

## Process

A Process represents a set of logically linked steps that need to run over a long span of times (hours, months, even years..). It persists in a Storage.

At the logical level, the persistant Process has the following attributes (See [Schedule::LongSteps::Storage::DBIxClass](https://metacpan.org/pod/Schedule::LongSteps::Storage::DBIxClass) for a comprehensive list):

\- what. Which step should it run next.

\- run\_at. A [DateTime](https://metacpan.org/pod/DateTime) at which this next step should be run. This allows running a step far in the future.

\- status. Is the step running, or paused or is the process terminated.

\- state. The persistant state of your application. This should be a pure Perl hash (JSONable).

Users (you) implement their business process as a subclass of [Schedule::LongSteps::Process](https://metacpan.org/pod/Schedule::LongSteps::Process). Such subclasses can have contextual properties
as Moose properties that will have to be supplied by the [Schedule::LongSteps](https://metacpan.org/pod/Schedule::LongSteps) management methods.

## Steps

A step is simply a subroutine in a process class that runs some business code. It always returns either a new step to be run
or a final step marker.

## Storage

A storage provides the backend to persist processes. Build a Schedule::LongSteps with a storage instance.

See section PERSISTANCE for a list of available storage classes.

## Manager: Schedule::LongSteps

A [Schedule::LongSteps](https://metacpan.org/pod/Schedule::LongSteps) provides an entry point to all thing related to Schedule::LongSteps process management.
You should keep once instance of this in your application (well, one instance per process) as this is what you
are going to use to launch and manage processes.

# QUICK START AND SYNOPSIS

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

# EXAMPLE

Look at [https://github.com/jeteve/Schedule-LongSteps/blob/master/t/fullblown.t](https://github.com/jeteve/Schedule-LongSteps/blob/master/t/fullblown.t) for a full blown working
example.

# PERSISTANCE

The persistance of processes is managed by a subclass of [Schedule::LongSteps::Storage](https://metacpan.org/pod/Schedule::LongSteps::Storage) that you should instantiate
and given to the constructor of [Schedule::LongSteps](https://metacpan.org/pod/Schedule::LongSteps)

Example:

    my $dbic_storage = Schedule::LongSteps::Storage::DBIxClass->new(...);
    my $longsteps = Schedule::LongSteps->new({ storage => $dbic_storage });
    ...

Out of the box, the following storage classes are available:

- [Schedule::LongSteps::Storage::Memory](https://metacpan.org/pod/Schedule::LongSteps::Storage::Memory)

    Persist processes in memory. Not very useful, except for testing. This is the storage of choice to unit test your processes.

- [Schedule::LongSteps::Storage::AutoDBIx](https://metacpan.org/pod/Schedule::LongSteps::Storage::AutoDBIx)

    Persist processes in a relational DB (a $dbh from [DBI](https://metacpan.org/pod/DBI)). This is the easiest thing to use if you want to persist processes in a database, without having
    to worry about creating a DBIx::Class model yourself.

- [Schedule::LongSteps::Storage::DBIxClass](https://metacpan.org/pod/Schedule::LongSteps::Storage::DBIxClass)

    Persist processes in an existing [DBIx::Class](https://metacpan.org/pod/DBIx::Class) schema. Nice if you want to have only one instance of Schema in your application and if
    don't mind writing your own resultset.

- [Schedule::LongSteps::Storage::DynamoDB](https://metacpan.org/pod/Schedule::LongSteps::Storage::DynamoDB)

    Persist processes in a DynamoDB table in AWS. Please consider this Alpha. Give it a go and report any issue!

# COOKBOOK

## WRITING A NEW PROCESS

See 'QUICK START AND SYNOPSIS'

## INSTANTIATING A NEW PROCESS

See 'QUICK START AND SYNOPSIS'

## RUNNING PROCESS STEPS

See 'QUICK START AND SYNOPSIS

## BEING NOTIFIED OF ANY OF YOUR PROCESS ERROR

Use the property 'on\_error' on the Schedule::LongStep manager:

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
a pure Perl warning and an emmission of a 'critical' level [Log::Any](https://metacpan.org/pod/Log::Any) log event.

## INJECTING PARAMETERS IN YOUR PROCESSES

Of course each instance of your process will most probably need to
act on different pieces of application data. The one and only way to
give 'parameters' to your processes is to specify an initial state when
you instantiate a process:

    $longsteps->instantiate_process('My::App', { app => $app } , { work => 'on' , this => 'user_id' });

## INJECTING CONTEXT IN YOUR PROCESSES

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

## PROCESS WRITING

This package should  be expressive enough for you to implement business processes
as complex as those given as an example on this page: [https://en.wikipedia.org/wiki/XPDL](https://en.wikipedia.org/wiki/XPDL)

Proper support for XPDL is not implemented yet, but here is a list of recipes to implement
the most common process patterns:

### MOVING TO A FINAL STATE

Simply do in your step 'do\_last\_stuff' implementation:

    sub do_last_stuff{
       my ($self) = @_;
       # Return final_step with the final state.
       return $self->final_step({ state => { the => 'final' , state => 1 } });
    }

### DO SOMETHING ELSE IN X AMOUNT OF TIME

    sub do_stuff{
         ...
         # Do the things that have to be done NOW
         ...
         # And in two days, to this
         return $self->new_step({ what => 'do_stuff_later', run_at => DateTime->now()->add( days => 2 ) ,  state => { some => 'new one' }});
    }

### DO SOMETHING CONDITIONALLY

    sub do_choose{
       if( ... ){
          return $self->new_step({ what => 'do_choice1', run_at => DateTime->now() });
       }
       return $self->new_step({ what => 'do_choice2', run_at => DateTime->now() });
    }

    sub do_choice1{...}
    sub do_choice2{...}

### FORKING AND WAITING FOR PROCESSES

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

# ATTRIBUTES

- storage

    An instance of a subclass of [Schedule::LongSteps::Storage](https://metacpan.org/pod/Schedule::LongSteps::Storage). See SYNOPSIS.

- on\_error

    A callback called like $on\_error->( $stored\_process , $error ). See COOKBOOK for an example

- error\_limit

    Maximum size of error message to log and store. Defaults to 2000 characters.

# METHODS

## uuid

Returns a [Data::UUID](https://metacpan.org/pod/Data::UUID) from the storage.

## run\_due\_processes

Runs all the due processes steps according to now(). All processes
are given the context to be built.

Usage:

    # No context given:
    $this->run_due_processes();

    # With 'thing' as context:
    $this->run_due_processes({ thing => ... });

Returns the number of processes run

## instantiate\_process

Instantiate a stored process from the given process class returns a new process that will have an ID.

Usage:

    $this->instantiate_process( 'MyProcessClass', { process_attribute1 => .. } , { initial => 'state' });

## find\_process

Shortcut to $self->storage->find\_process( $pid );

## load\_process

Returns a loaded process for a given pid, or undef if there is no process
associated with the PID.

An optional hash ref context can also be passed in
and will be used to load the process, a blank context is used if not provided.

    if( my $loaded_process = $self->load_process( $pid , $context ) ){
       ...
    }

## revive

Revive a longstep process to a given step within a Longstep process.

A context is required when the reviving process contains required attributes
and when setting a step to reviving step. If no step is given then the process
will revive on the failed process step, when setting a step that doesn't
require a context, use an empty hashref '{}'.

If you need to modify the state before reviving the longstep process, it is
recommended to have a revive step ("revive\_do\_broken\_step") which modifies
the state as needed and returns a next\_step to continue the process.

This method will confess on any issues.

    eval {
        $self->revive( $pid, $context, $method_to_revive_to );
    };

# SEE ALSO

[BPM::Engine](https://metacpan.org/pod/BPM::Engine) A business Process engine based on XPDL, in Alpha version since 2012 (at this time of writing)

# Copyright and Acknowledgement

This code is released under the Perl5 Terms by Jerome Eteve (JETEVE), with the support of Broadbean Technologies Ltd.

See [perlartistic](https://metacpan.org/pod/perlartistic)
