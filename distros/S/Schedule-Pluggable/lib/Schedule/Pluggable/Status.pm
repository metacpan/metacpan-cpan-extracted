package Schedule::Pluggable::Status;
use Moose::Role;
use English;
use Fcntl qw(:DEFAULT :flock);
use Carp qw/ carp /;
use Data::Dumper;
use POSIX qw/ strftime /;
$Data::Dumper::Sortkeys = 1;

has status => ( is => 'rw',
                isa => 'HashRef',
                lazy => 1,
                reader => '_get_status',
                writer => '_set_status',
                builder => '_initialise_status',
            );

sub _initialise_status {
    my $self = shift;
    return {
               Jobs => {},
               TotalJobs => 0,
               TotalQueued => 0,
               TotalStarted => 0,
               TotalFinished => 0,
               TotalSucceeded => 0,
               TotalFailed => 0,
               Groups => {},
               Ready_to_Run => {},
               Ids => {},
               Pids => {},
            };
}

sub _update_status {
	my $self = shift;
    my $no = 1;
	my ($key, $params) = @_;
    my $status = $self->_get_status();
	my $job_name = $key->{name} ? $key->{name}
								: $status->{Ids}{$key->{id}};
#    warn Data::Dumper->Dump([$key, $params, $status->{Ids}],[qw/$key $params $status->{Ids}/]) unless $job_name;
    $job_name ||= "Job".$key->{id};
    return if $job_name eq 'MonitorJobs';
	foreach my $p (keys %{ $params } ) {
		$status->{Ids}{$params->{$p}} = $job_name if $p eq "Id";
		$status->{Queued}{$job_name} = $params->{$p} if $p eq "Queued";
		$status->{Pids}{$job_name} = $params->{$p} if $p eq "Pid";
		$status->{TotalQueued}++  if $p eq "Id"; 
		$status->{TotalStarted}++  if $p eq "timestarted";
        $status->{Running}{$job_name} = strftime('%d/%m/%Y %H:%M:%S', localtime(time())) if $p eq "timestarted";
		$status->{TotalFinished}++  if $p eq "timefinished";
#        print Data::Dumper->Dump([$status->{Running}], [qw/$status->{Running}/]);
        delete $status->{Running}{$job_name} if $p eq "timefinished";
        delete $status->{Queued}{$job_name} if $p eq "timestarted";
#        print Data::Dumper->Dump([$status->{Running}], [qw/$status->{Running}/]);
		if (ref $params->{$p} eq "ARRAY") {
			$status->{Jobs}{$job_name}{$p} ||= [];
			push(@{ $status->{Jobs}{$job_name}{$p} }, @{ $params->{$p} });
		}
		else {
			$status->{Jobs}{$job_name}{$p} = $params->{$p};
		}
	}

    my @jobs_to_queue = ();
	if (defined($params->{status})) {
		if ($params->{status} != 0) {
            $status->{TotalFailed}++;
            $status->{Jobs}{$job_name}{stderr} ||= [ pop(@{ $status->{Jobs}{$job_name}{stdout} }) ];
            $status->{Jobs}{$job_name}{stderr} ||= [];
			$status->{Failed}{$job_name} = { status => $params->{status},
                                             stderr => [ @{ $status->{Jobs}{$job_name}{stderr} } ] };
		}	
		else {
            $status->{TotalSucceeded}++;
            my @jobs = keys %{ $status->{Jobs} };
JOB:		foreach my $job (@jobs) {
				next JOB if $job eq $job_name;
				if ($status->{Jobs}{$job}{prerequisites}) {
					my %p = %{ $status->{Jobs}{$job}{prerequisites} };
                    if (exists ($p{$job_name} )) {
                        $status->{Jobs}{$job}{prerequisites}{$job_name} =  strftime('%d/%m/%Y %H:%M:%S', localtime(time()));
                        $status->{Jobs}{$job}{ pending_prerequisites }--;
                    }
                    if (!defined($status->{Jobs}{$job}{timestarted}) and
                           $status->{Jobs}{$job}{ pending_prerequisites } == 0) {

                        push(@jobs_to_queue, {name => $job, command => $status->{Jobs}{$job}{command} });
                    }
                    #$self->queue_jobs($status->{Jobs}{$job})  if $status->{Jobs}{$job}{ pending_prerequisites } == 0;
				}
			}
		}
	}
    $status->{LastUpdate} = strftime('%d/%m/%Y %H:%M:%S', localtime(time()));
    $self->_set_status($status);
    if (scalar(@jobs_to_queue) > 0) {
        $self->_queue_jobs(@jobs_to_queue);
    }
    if ($status->{TotalFailed} > 0 or $status->{TotalFinished} >= $status->{TotalJobs}) {
        system("touch ".$status->{EndOfScheduleFile});
    }
}
1;
__END__

=head1 NAME

Schedule::Pluggable::Status - Moose Role to provide methods to update the status when events occur

=head1 DESCRIPTION

Moose Role to add method to Schedule::Pluggable  to update the status when events occur - not runnable on it's own

=head1 METHODS

No public methods

=cut

