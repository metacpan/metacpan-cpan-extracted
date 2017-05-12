package Parallel::Pvm::Scheduler;

use 5.008;
use strict;
use warnings;

use Parallel::Pvm 1.40;
;
require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Parallel::Pvm::Scheduler ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


# Preloaded methods go here.


=head1 NAME

Parallel::Pvm::Scheduler - Perl extension for distributing jobs through PVM

=head1 SYNOPSIS

  use Parallel::Pvm::Scheduler;
  my $prm = new Parallel::Pvm::Scheduler();

  # Create an array of tasks:
  $tasks[0][0] = "/myhome/program1";
  $tasks[0][1] = "program1 parameter 1";
  $tasks[0][2] = "program1 parameter 2";

  $tasks[1][0] = "/myhome/program2_noparameters";

  $tasks[2][0] = "/myhome/program1";
  $tasks[2][1] = "program1 parameter 1";
  
  # Submit the tasks
  for ($i = 0; $i < $taskcount; $i++)
  {
        $prm->submit("user-defined task description", $args[$i]);
  }

  # Wait for the tasks to complete
  $prm->recaptureHosts(1);


=head1 DESCRIPTION

Parallel-Pvm-Scheduler is a module designed to allow one to distribute a large
number of independent jobs across a cluster using PVM.  It first queries the number of
available machines in the cluster, then submits exactly 1 jobs per available machine.
When a job is finished, it recaptures the machine and submits the next job. It repeats
this until all the jobs are complete.

If all the available machines are used, it will wait until 1 becomes free before submitting
the next job, hence it will sleep until a task is complete.

=head2 EXPORT

None by default.

=head1 SEE ALSO

Parallel::Pvm perl module

=head1 AUTHOR

Ryan Golhar, E<lt>golharam@umdnj.edu<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Ryan Golhar

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

my $MSGTAG = 1;
my $MSGTASKEXIT = 999;

=head2 new

 Title   : new
 Usage   : my $prm = new Parallel::Pvm::Scheduler();
 Function: Creates and initialized a PVM resource manager
 Returns : Parallel::Pvm::Scheduler

=cut

sub new {
	my ($class, @args) = @_;
	my ($info,@CONF) = Parallel::Pvm::config;
	my $FREEHOSTS = scalar(@CONF);
	my %HOSTS;
	my @TID;
	my %TIDcmd;
	
	# Map host id to hostname and set busy flag to zero
	foreach my $node (@CONF) {
		my $hostid = $node->{'hi_tid'};

		$HOSTS{$hostid}{'name'} = $node->{'hi_name'};
		$HOSTS{$hostid}{'busy'} = 0;
	}
	
	my $self = {CONF => \@CONF, FREEHOSTS => $FREEHOSTS, HOSTS => \%HOSTS, TID => \@TID, TIDCMD => \%TIDcmd};
	bless $self;
	return $self;
}

sub DESTROY {
	Parallel::Pvm::exit;
}

=head2 getHostCount

 Title   : getHostCount
 Usage   : $hostcount = $prm->getHostCount();
 Function: Returns the number of hosts within the PVM
 Returns : integer

=cut

sub getHostCount
{
	my ($self) = @_;
	my $CONF = $self->{CONF};
	
	return scalar(@$CONF);
}

=head2 getFreeHostCount

 Title   : getFreeHostCount
 Usage   : $freehostcount = $prm->getFreeHostCount();
 Function: Returns the number of free hosts within the PVM
 Returns : integer

=cut

sub getFreeHostCount
{
	my ($self) = @_;
	my $FREEHOSTS = $self->{FREEHOSTS};

	return $FREEHOSTS;
}

=head2 submit

 Title   : submit
 Usage   : $prm->getFreeHostCount($taskdesc, @argv);
 Function: Submits a task contained with an argument vector
 Args    : $taskdesc is a taskdescription.  It can be anything set by the user
 	   @argv is an argument vector.  The first element is the program to execute
	   the remaining elements are the parameters to the program.  
 Notes   : To execute multiple programs in serial for a single task, make a perl script
 	   and submit the perl script as the task.
 
=cut

sub submit {
	my ($self, $text, @pvmargv) = @_;
	
	my $TID_ref = $self->{TID};
	my $TIDcmd_ref = $self->{TIDCMD};
	
	# If there are no free hosts, iterate through the taskids and 
	# determine which ones finished and free those hosts 
	while ($self->{FREEHOSTS} == 0) {
		recaptureHosts($self);

		# After checking and there still aren't any free hosts, 
		# sleep for 3 seconds, then try again
		if ($self->{FREEHOSTS} == 0) {
			sleep(3);
		}
	}
	
	# Find a free host and spawn on that host
	my $host = _allocateHost($self);
	my $info = Parallel::Pvm::spawn('pvmit', 1, PvmTaskHost, $host, \@pvmargv);
	if ($info <= 0) {
		print STDERR "Error: Could not spawn child: $info, @pvmargv\n";
		_deallocateHost($host);
	}
	push @$TID_ref, $info;			

	my $cmds = join(' ', @pvmargv);
	$TIDcmd_ref->{$info} = "$text\n$cmds";	

	print STDERR "Started $info on $host\n";			
}

=head2 recaptureHosts

 Title   : recaptureHosts
 Usage   : $prm->recaptureHosts($block);
 Function: Checks tasks for completion and prints their output
 Args    : $block 
		= 0, then iterate through all the tasks and query for their completion.
			if done, free the machine
		= 1, then iterate through all tasks waiting for them to complete.  Does not
			return until the tasks are complete.
=cut

sub recaptureHosts {
	# If block == 1, then recapture all hosts and block when waiting
	# else recapture whatever is available and continue
	my ($self, $block) = @_;

	my $HOSTS_ref = $self->{HOSTS};
	my $TID_ref = $self->{TID};
	my $TIDcmd_ref = $self->{TIDCMD};
	my $CONF_ref = $self->{CONF};
	
	$block = 0 if (!defined($block));
		
	# Iterate through the taskid and check to see if its done
	# If its done, process and remove it
	my $arrayindex = 0;
	my $childtid;
	
	while ($arrayindex < scalar(@$TID_ref)) {
		$childtid = @$TID_ref[$arrayindex];
		
		if ($childtid < 0) {
			print STDERR "Error with PVM Task: $childtid\n";
		} else {
			my $bufid = Parallel::Pvm::probe($childtid, $MSGTAG);
			if ($bufid < 0) {
				print STDERR "There was an error probing on $childtid: $bufid!\n";
			} elsif ($bufid > 0) {
				my $hostid = Parallel::Pvm::tidtohost($childtid);
				print STDERR "Recieved message from $childtid on ".$HOSTS_ref->{$hostid}{'name'}."\n";			
			
				$bufid = Parallel::Pvm::recv($childtid, $MSGTAG);
				my $output = Parallel::Pvm::unpack;
				print "($childtid) ", $TIDcmd_ref->{$childtid}, "\n";
				print "$output\n" if (defined($output));

				_deallocateHost($self, $hostid);
				
				# remove this child taskid
				splice(@$TID_ref, $arrayindex, 1);
				delete($TIDcmd_ref->{$childtid});
				
				# we don't want to increment the arrayindex or else 
				# we'll skip over the next task id.
				next;	
			} else {
				# $bufid == 0
				# wait until this tasks completes
				if ($block == 1) {
					sleep(3);
					next;
				}
			}
		}
		$arrayindex++;
	}
	
	if ($block == 1) {
		if ($self->{FREEHOSTS} != scalar(@$CONF_ref)) {
			print STDERR "There was a problem reconciling freehosts with pvm configuration!!!\n";
			
			foreach my $node (@$CONF_ref) {
				my $hostid = $node->{'hi_tid'};
				my $hostname = $node->{'hi_name'};

				if ($HOSTS_ref->{$hostid}{'busy'} != 0) {
					print STDERR "$hostname is not free\n";
				}
			}
		}
	}
}

=head2 _allocateHost

 Title   : _allocateHost
 Function: Internal Function: Used to allocate which host runs the next task
=cut

sub _allocateHost {
	my ($self) = @_;
	my $HOSTS_ref = $self->{HOSTS};
	
	# Locate a free host, allocate it, return it.
	# First available algorithm
	foreach my $hostid (keys %$HOSTS_ref) {
	
		if ($HOSTS_ref->{$hostid}{'busy'} == 0) {
			my $hostname = $HOSTS_ref->{$hostid}{'name'};
			
			print STDERR "Allocating host $hostname\n";
			
			$HOSTS_ref->{$hostid}{'busy'} = 1;
			$self->{FREEHOSTS}--;			
		
			return $hostname;
		}
	}
	
	# if we get here, no hosts were free.
	die "Unable to locate free host!\n";
}

=head2 _deallocateHost

 Title   : _deallocateHost
 Function: Internal Function: Frees a host making it available for another task
=cut

sub _deallocateHost {
	my ($self, $hostid) = @_;
	my $HOSTS_ref = $self->{HOSTS};

	if ($HOSTS_ref->{$hostid}{'busy'} == 0) {
		die "Host not allocated: ". $HOSTS_ref->{$hostid}{'name'} ."!\n";
	}
	
	print STDERR "Deallocating host ". $HOSTS_ref->{$hostid}{'name'} ."\n";
	$HOSTS_ref->{$hostid}{'busy'} = 0;
	$self->{FREEHOSTS}++;
}

1;
__END__
