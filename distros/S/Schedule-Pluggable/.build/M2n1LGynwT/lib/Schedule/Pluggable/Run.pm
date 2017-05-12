package Schedule::Pluggable::Run;

use Moose::Role;
use FileHandle;
use Data::Dumper;
use Try::Tiny;
use POSIX qw/ tmpnam strftime/;
$Data::Dumper::Sortkeys = 1;

sub run_in_series {
	my $self = shift;

    my @jobs = ref $_[0] eq 'ARRAY' ? @{ $_[0] }
                                    : @_;
    my $job_no = 1;
    my $last_job = undef;
    foreach my $job (@jobs) {
        if (ref($job) eq 'HASH') {
            $job->{name} ||= "Job".$job_no++;
            delete $job->{dependencies} if $job->{dependencies};
            delete $job->{prerequisites} if $job->{prerequisites};
        }
        elsif (ref($job) eq 'ARRAY') {
            my $command = join(" ", @{ $job });
            $job = { name => "Job".$job_no++,
                     command => $command };
            
        }
        else {
            my $command = $job;
            $job = { name => "Job".$job_no++,
                     command => $command
                     };
        }
        $job->{prerequisites} = $last_job->{name} if $last_job;
        $last_job= { %{ $job } };
    }
    $self->run_schedule({ Jobs => [ @jobs ]});
}
sub run_in_parallel {
	my $self = shift;
    my @jobs = ref $_[0] eq 'ARRAY' ? @{ $_[0] }
                                    : @_;
    my $job_no = 1;

    foreach my $job (@jobs) {
        if (ref($job) eq 'HASH') {
            $job->{name} ||= "Job".$job_no++;
        }
        elsif (ref($job) eq 'ARRAY') {
            my $command = join(" ", @{ $job });
            $job = { name => "Job".$job_no++,
                     command => $command };
            
        }
        else {
            my $command = $job;
            $job = { name => "Job".$job_no++,
                     command => $command
                     };
        }
        delete $job->{dependencies}  if $job->{dependencies};
        delete $job->{prerequisites}  if $job->{prerequisites};
    }
    $self->run_schedule({ Jobs => [ @jobs ]});
}
sub run_schedule {
	my ($self, $params) = @_;
	my $status = $self->_validate_config($params);
#    warn Data::Dumper->Dump([$status],[qw/$status/]);
	my @jobs_ready_to_run =  sort { $a->{name} cmp $b->{name} } values %{ $status->{Ready_to_Run} };
    delete $status->{Ready_to_Run};
    $status->{EndOfScheduleFile} = POSIX::tmpnam();
	$self->_set_status($status);
    my ($id, $pid) = $self->enqueue( MooseX::Workers::Job->new(name => 'MonitorJobs', command => sub { _monitor_jobs($self); } ));
    $status->{Pids}{MonitorJobs} = $pid;
    $status->{Ids}{$id} = 'MonitorJobs';
	$self->_set_status($status);
	$self->_queue_jobs(@jobs_ready_to_run);
	POE::Kernel->run;
	$status = $self->_get_status;
    delete $status->{$_} foreach qw/ Queued Running TotalQueued TotalStarted Ids Pids Groups Config EndOfScheduleFile LastUpdate/;
	delete $status->{Jobs}{MonitorJobs};
    foreach my $k (qw/groups pending_prerequisites prerequisites Id Queued group/) {
        delete $status->{Jobs}{$_}{$k} foreach keys %{ $status->{Jobs} };
    }
    
	return $status->{TotalFailed}, $status;
}
sub _monitor_jobs {
    my $self = shift;
   my $status = $self->_get_status();
   my $tempfile = $status->{EndOfScheduleFile};
	while (1) {
        sleep(10);
       last if -f $tempfile;
    }
    unlink( $tempfile );
}
sub _queue_jobs {
	my ($self, @jobs) = @_;
	foreach my $job (@jobs) {
        if ($job->{params}) {
            if (ref $job->{params} eq 'ARRAY') {
                $job->{command} = join(" ", $job->{command}, @{ $job->{params} });
            }
            else {
                $job->{command} = join(" ", $job->{command}, $job->{params});
            }
        }
		my $j = MooseX::Workers::Job->new(
											name    => $job->{name},
											command => $job->{command}
										);
        $self->event_handler(Event    => 'JobQueued',
							 JobName => $job->{name},
							 Command => $job->{command},
						    );
        try {
            $self->enqueue( $j );
        }
        catch {
#            warn "oops - can't queue $job->{name} - $job->{command}: $_";
            my $error = $_;
            $error =~ s! at\s+\S+\s+line\s+\d+.!!;
            $self->event_handler(Event => 'JobFailed',
                                 JobName => $job->{name},
                                 Command => $job->{command},
                                 ReturnValue => -1,
                                 Stderr => "<$error>",
                             );

            $self->_update_status({name => $job->{name}},
                                  { 
                                    command => $job->{command},
                                    status => -1,
                                    stderr => "<$error>",
                                  });
            return;
        }
        finally {
            $self->_update_status({name => $job->{name}},
                                 {Queued => strftime('%d/%m/%Y %H:%M:%S', localtime(time())),
                                 }); 
        };
	}
}

1;
__END__

=head1 NAME

Schedule::Pluggable::Run - Moose Role to provide methods to run schedules

=head1 DESCRIPTION

Moose Role to add method to run schedules to Schedule::Pluggable - not runnable on it's own

=head1 METHODS

=over

=item run_in_series

Utility method to build a schedule where each job depends on the previous one and so they run in series

=item run_in_parallel

Utility method which removes any dependencies from a schedule causing all the jobs to run in parallel

=item run_schedule

The main method of this role - takes a schedule definition, validates and reformats it and then starts off the job manager to run them

=back 

=cut

