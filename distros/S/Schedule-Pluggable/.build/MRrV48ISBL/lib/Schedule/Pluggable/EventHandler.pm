package Schedule::Pluggable::EventHandler;

use Moose::Role;
use Carp;
#use IO::Prompt;
use Data::Dumper;
use POSIX qw/ strftime /;
$Data::Dumper::Sortkeys = 1;
has EventsPlugins => ( is        => 'rw',
                       isa       => 'ArrayRef',
                       reader  => '_get_EventsPlugins',
                       default   => sub { return [ qw/DefaultEventHandler/ ] },
                    );

before BUILD => sub {
    my $self = shift;
	$self->load_plugins( @{ $self->_get_EventsPlugins } );
};

sub worker_manager_start {
    my $self = shift;
    $self->event_handler(Event => 'ManagerStart');
}
sub worker_manager_stop {
    my $self = shift;
    $self->event_handler(Event => 'ManagerStop');
}
# Called with the return value when a job ends
sub sig_child {
    my $self = shift;
    my ( $id, $return_value ) = @_;
    my $status = $self->_get_status();
    my $job_name = $status->{Ids}{$id};
	my $command = $status->{Jobs}{$job_name}{command};
    if ($return_value == 0) {
        $self->event_handler(Event       => 'JobSucceeded',
                             JobName    => $job_name,
							 Command	=> $command,
                             Stderr => $status->{Jobs}{ $job_name }{stderr},
                             Stdout => $status->{Jobs}{ $job_name }{stdout},
                         );
    } 
    else {
        $status->{Jobs}{$job_name}{stderr} ||= [ pop(@{ $status->{Jobs}{$job_name}{stdout} }) ];
        $self->event_handler( Event => 'JobFailed',
                             JobName => $job_name,
							 Command => $command,
                             ReturnValue => $return_value,
                             Stderr => $status->{Jobs}{ $job_name }{stderr},
                             Stdout => $status->{Jobs}{ $job_name }{stdout},
                         );
    }
    $self->_update_status({ name => $job_name }, { status => $return_value, } );
}
sub max_workers_reached {
    my $self = shift;
    $self->event_handler( Event => 'MaxJobsReached');
}
sub worker_stdout {
    my $self = shift;
    my ( $stdout, $job ) = @_;
    $self->_update_status({ id => $job->ID }, { stdout  => [ $stdout ] });
    $self->event_handler(Event    => 'JobStdout',
                        JobName => $job->{name},
                        Command => $job->{command},
                        Stdout  => $stdout,
                    );
}
sub worker_stderr {
    my $self = shift;
    my ( $stderr, $job ) = @_;
    $stderr =~ s! at\s+\S+POE/Wheel/Run.pm\s+line\s+\d+.!!;

    $self->_update_status({ id => $job->ID }, { stderr  => [ $stderr ] });
    $self->event_handler(Event    => 'JobStderr', 
                        JobName => $job->{name},
                        Command => $job->{command},
                        Stderr  => $stderr,
                        );
}
sub worker_done {
    my $self = shift;
    my ( $job ) = @_;

    $self->_update_status({ id => $job->ID }, { timefinished => strftime("%d/%m/%Y %H:%M:%S", localtime(time)) });
    $self->event_handler(Event    => 'JobDone', 
                        JobName => $job->name,
                        Command => $job->command,
                    ) ;
}
sub worker_started {
    my $self = shift;

    my ( $job ) = @_;

    $self->_update_status({ name => $job->name }, { Id => $job->ID, Pid => $job->PID, timestarted => strftime("%d/%m/%Y %H:%M:%S", localtime(time)) });
    $self->event_handler(Event    => 'JobStarted',
                        JobName => $job->{name},
                        Command => $job->{command},
                    );

}
sub sig_INT {
    my $self = shift;
    print "Sig INT!\n";
    my $status = $self->_get_status();
    my $running = $self->has_workers;
    if ($running > 1) {
        foreach my $j (keys %{ $status->{Running} }) {
            my %job = %{ $status->{Jobs}{$j} };
            print join(" ", @job{ qw/Id Pid name command timestarted/} ), "\n";
        }
    }
    exit(0);
}
sub sig_BUS {
    confess("sig_BUS\n".Data::Dumper->Dump([\@_],[qw/@_/]));
}
sub sig_SEGV {
    confess("sig_SEGV\n".Data::Dumper->Dump([\@_],[qw/@_/]));
}
sub event_handler {
    my $self = shift;
}
1;
__END__

=head1 NAME

Schedule::Pluggable::EventHandler - Moose Role to handle the interface to MooseX::Workers by providing the methods which get called

=head1 DESCRIPTION

Moose Role to handle the interface to MooseX::Workers by providing the methods which get called when events occur - not runnable on it's own

=head1 METHODS - none of which are for public use

=over

=item worker_manager_start  - called when the worker manager starts up

=item worker_manager_stop   - called when the worker manager shuts down

=item max_workers_reached   - called when a job is queued when the number of jobs already running is equal to the maximum specified

=item sig_child             - called when a job ends supplying the return code 

=item worker_stdout         - called whenever a job sends some output to standard output

=item worker_stderr         - called whenever a job sends some output to standard error

=item worker_started        - called when a job starts up

=item worker_done           - called when a job finishes

=item sig_INT               - called when the interupt signal (control-c) is recieved

=item event_handler			- A stub method designed for Event Handler Plugins to process after

=item sig_BUS           - called when a Bus error signal is recieved - causes schedule to abort

=item sig_SEGV          - called when a segmentation violation signal is received - causes schedule to abort

=back

=cut

