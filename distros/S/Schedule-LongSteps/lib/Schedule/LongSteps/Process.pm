package Schedule::LongSteps::Process;
$Schedule::LongSteps::Process::VERSION = '0.020';
use Moose;
use Log::Any qw/$log/;

has 'longsteps' => ( is => 'ro', isa => 'Schedule::LongSteps' , required => 1);

has 'stored_process' => ( is => 'ro' );

=head1 NAME

Schedule::LongSteps::Process - A base class for all LongSteps processes.

=cut

=head2 state

Returns the current state (a HashRef JSONable data structure)
of this process.

=cut

sub state{
    my ($self) = @_;
    return $self->stored_process()->state();
}

=head2 new_step

Returns a new step from the given properties.

Usage examples:

  # In a process class.
  sub do_current_step{
     my ($self) = @_;
     return $this->new_step({ run_at => DateTime->... , what => 'do_nextstep' , state => { new => 'state' } });
  }

If you omit run_at, the process will not run again and stay in paused state until you go and set the run_at
time manually.

If you omit 'what', the next step to run will be the same as the current step.

If you omit 'state', the state just doesnt change.

=cut

sub new_step{
    my ($self, $step_properties) = @_;
    return $step_properties;
}

=head2 final_step

Returns a final step that will never run
from the given properies.

Usage:

    # In a Process class.
    sub do_last_thing{
       my ($self) = @_;
       return $self->final_step({ state => { the => 'final' , state => 1 } });
    }

If you omit 'state', the current state of the process just doesnt change and
the process terminates with the current state.

=cut

sub final_step{
    my ($self, $step_properties) = @_;
    defined( $step_properties ) or ( $step_properties = {} );

    return {
        %$step_properties,
        run_at => undef,
        status => 'terminated'
    };
}

=head2 wait_processes

Wait for the given process IDs and returns whatever the given
closure returns.

Usage:

   return $this->wait_process(
            [ $pid1 , $pid2 ],
            sub{
                ...
                return $this->new_step(...); # or whatever usual stuff
            }

If you skip the closure, this will just terminate $this process after the
given subprocesses have finished.

=cut

sub wait_processes{
    my ($self, $process_ids, $on_finish) = @_;
    defined( $process_ids ) or ( $process_ids = [] );
    defined( $on_finish ) or ( $on_finish = sub{ $self->final_step(); } );

    my @processes = map{ $self->longsteps()->find_process( $_ ) } @$process_ids;
    my @finished_processes = grep{ $_->status() eq 'terminated' } @processes;

    $log->debug(scalar(@finished_processes)." are finished");

    if( scalar( @processes ) == scalar( @finished_processes ) ){
        $log->debug("Calling on_finish");
        return $on_finish->( @finished_processes );
    }
    # Run at next tick
    $log->debug("Will wait a little bit more");
    return $self->new_step({ run_at => DateTime->now() });
}


=head2 revival_methods

Returns an array-ref of revive methods associated with the process.

=cut

sub revival_methods {
    my ($self) = @_;
    my @revival_methods = map {$_->name}grep {$_->name =~ /^revive_/} $self->meta->get_all_methods;
    return \@revival_methods;
}


__PACKAGE__->meta->make_immutable();

