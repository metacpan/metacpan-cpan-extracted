package Proc::Fork::Control;

#
#    Copyright (C) 2014 Colin Faber
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation version 2 of the License.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
#        Original author: Colin Faber <cfaber@fpsn.net>
# Original creation date: 10/02/2014
#                Version: $Id: Control.pm,v 1.6 2015/12/14 16:38:54 cfaber Exp $
# 

# Version number - cvs automagically updated.
our $VERSION = $1 if('$Revision: 1.6 $' =~ /: ([\d\.]+) \$/);

use strict;
use POSIX ('WNOHANG','setsid');
use Time::HiRes 'usleep';

require Exporter;

# Exported routines
our @ISA = ('Exporter');
our @EXPORT = qw(
	cfork
	cfork_wait
	cfork_wait_pid
	cfork_init
	cfork_exit
	cfork_exit_code
	cfork_maxchildren
	cfork_errstr
	cfork_is_child
	cfork_has_children
	cfork_nonblocking
	cfork_daemonize
	cfork_sleep
	cfork_usleep
	cfork_ssleep
	cfork_active_children
	cfork_kill_children
	cfork_list_children
	cfork_child_dob
);

# Defaults
&cfork_init;

require 5.008;

$Proc::Fork::Control::VERSION = '$Revision: 1.6 $';

=head1 NAME

Proc::Fork::Control

=head1 DESCRIPTION

Proc::Fork::Control is a simple to use library which functions much the same way
as Proc::Fork. That said, Proc::Fork is not used, as fork() is accessed directly.

Proc::Fork::Control allows you to manage forks, control number of children
allowed, monitor children, control blocking and nonblocking states, etc.

=head1 SYNOPSIS

 #!/usr/bin/perl 
 use Proc::Fork::Control;
 use Fcntl ':flock';

 # Initialize the system allowing 25 forks per cfork() level
 cfork_init(25);

 for(my $i = 0; $i < 50; $i++){
	# Fork this if possible, if all avaliable fork slots are full
	# block until one becomes avaliable.
	cfork(sub {
		# Initialize for children
		cfork_init(2);

		for('A' .. 'Z'){
			cfork(sub {
				# Lock STDOUT for writing.
				flock(STDOUT, &LOCK_EX);

				# Print out a string.
				print STDOUT "Fork: $i: $_\n";
	
				# Unlock STDOUT.
				flock(STDOUT, &LOCK_UN);

				cfork_exit();
			});
		}

		# Wait for sub children to exit
		cfork_wait()

	});
 }

 # Wait until all forks have finished.
 cfork_wait();

=head1 METHODS

Note - because of the nature of forking within perl. I've against objectifying this library. Rather it uses direct function calls which are exported to the global namespace Below is a list of these calls and how to access them.

=head2 cfork(code, code, code)

Provide managed forking functions.

Returns nothing on error and sets the cfork_errstr error handler.

if cfork() is called with in an cfork()ed process the calling cfork() process will block until all children with in it die off.

=cut

sub cfork {
	_errstr();
	if(!$Proc::Fork::Control::HEAP->{max_children}){
		return _errstr("cfork_init() not set");
	}

	if(!defined $Proc::Fork::Control::HEAP->{children}){
		$Proc::Fork::Control::HEAP->{children} = 0;
	}

	if(!defined $Proc::Fork::Control::HEAP->{max_children}){
		$Proc::Fork::Control::HEAP->{max_children} = 0;
	}

	my ($i, $delay);
	while(1){
		my $cl =_cleanup();

		if($Proc::Fork::Control::HEAP->{children} < $Proc::Fork::Control::HEAP->{max_children}){
			last;
		}

		if($Proc::Fork::Control::HEAP->{children}){
			if($cl){
				# There are still children alive, and we've cleaned up at least 1 
				# child on the last iteration so don't delay at all.
				$i = 0;
				$delay = 0;
			} else {
				# There are still children alive, delay based on the number of interations
				# Minimum delay time (in micro seconds)
				$delay ||= 5;

				# iterator for delay multiplication.
				$i++;

				$delay = $delay * $i;

				# Maximum delay value
				$delay = ($delay > 5000 ? 5000 : $delay);

				# sleep for a while..
				cfork_usleep($delay);
			}
		}
        }

	if($Proc::Fork::Control::HEAP->{is_child}){
		$Proc::Fork::Control::HEAP->{has_children} = 1;
	}

	my $pid = fork;
	if($pid < 0){
		return _errstr('fork failed: ' . $!);
	} elsif($pid){
		# This probably should use CLOCK_MONOTONIC time here, but it's not a big deal.
		$Proc::Fork::Control::HEAP->{cidlist}->{$pid} = time();
		$Proc::Fork::Control::HEAP->{children}++;        
	} else {
		cfork_init();
		$Proc::Fork::Control::HEAP->{is_child} = 1;
		$SIG{PIPE} = 'IGNORE';
		for my $code (@_){
			if(ref($code) eq 'CODE'){
				&{ $code };            
			}               
		}

		cfork_exit(2);
 	} 

	# Wait for children to finish (if nonblocking
	cfork_wait();

	# Return our PID for further use.
	return $pid;
} 

=head2 cfork_nonblocking(BOOL)

Set the cfork() behavior to nonblocking mode if <BOOL> is true, This will result in the fork returning right away rather than waiting for any possible children to die.

Also, cfork_nonblocking() should always be turned off after the bit of code you want to run, runs.

=item EXAMPLE

 cfork_nonblocking(0);

 cfork(sub {
	do some work;
 });

 cfork_nonblocking(1);

=cut

sub cfork_nonblocking {
	$Proc::Fork::Control::HEAP->{nonblocking} = $_[0];
}

=head2 cfork_is_child()

Return true if called with in a forked enviroment, otherwise return false.

=cut

sub cfork_is_child {
	return $Proc::Fork::Control::HEAP->{is_child};
}

=head2 cfork_has_children()

Return true if children exist with in a forked enviroment.

=cut

sub cfork_has_children {
	return $Proc::Fork::Control::HEAP->{has_children};
}

=head2 cfork_errstr()

Return the last error message.

=cut

sub cfork_errstr {
	my ($err) = @_;
	$Proc::Fork::Control::errstr = $err if $err;
	return $Proc::Fork::Control::errstr;
}

sub _errstr {
	my ($err) = @_;
	cfork_errstr($err);
	return;
}

=head2 cfork_init(children)

Initialize the CHLD reaper with a maximum number of <children>

This should be called prior to any cfork() calls

=cut

sub cfork_init {
	my $ic = $Proc::Fork::Control::HEAP->{is_child};

	$Proc::Fork::Control::HEAP = {};
	$Proc::Fork::Control::HEAP->{children} = 0;
	$Proc::Fork::Control::HEAP->{cidlist}  = {};
	$Proc::Fork::Control::HEAP->{is_child} = ($ic ? 1 : 0);

	$SIG{CHLD} = \&Proc::Fork::Control::_sigchld if !$ic;

	if($_[0]){
		$Proc::Fork::Control::HEAP->{max_children} = $_[0];
	}
}

=head2 cfork_exit(int)

Exit a process cleanly and set an exit code.

Normally this can be easily handled with $? however, in some cases $? is not reliably delivered.

Once called, drop to END {} block and terminate.

=cut

sub cfork_exit {
	my ($exit) = @_;
	$Proc::Fork::Control::HEAP->{exit} = $exit;
	exit($exit);
}

=head2 cfork_exit_code()

Returns the last known cfork_exit() code.

=cut

sub cfork_exit_code {
	return $Proc::Fork::Control::HEAP->{exit};
}

=head2 cfork_maxchildren(int)

Set/Reset the maximum number of children allowed.

=cut

sub cfork_maxchildren {
	$Proc::Fork::Control::HEAP->{max_children} = $_[0] if $_[0];
}

=head2 cfork_wait()

Block until all cfork() children have died off unless cfork_nonblocking() is enabled.

=cut

sub cfork_wait {
	my ($to) = @_;
	return 1 if $Proc::Fork::Control::HEAP->{nonblocking};

	$to = time + $to if $to;

	my ($i, $delay);
	while(1){
		my $cl =_cleanup();

		if(!$Proc::Fork::Control::HEAP->{children}){
			last;
		} elsif($to && time >= $to){
			last;
		}

		if($Proc::Fork::Control::HEAP->{children}){
			if($cl){
				# There are still children alive, and we've cleaned up at least 1 
				# child on the last iteration so don't delay at all.
				$i = 0;
				$delay = 0;
			} else {
				# There are still children alive, delay based on the number of interations
				# Minimum delay time (in micro seconds)
				$delay ||= 5;

				# iterator for delay multiplication.
				$i++;

				$delay = $delay * $i;

				# Maximum delay value
				$delay = ($delay > 5000 ? 5000 : $delay);

				# sleep for a while..
				cfork_usleep($delay);
			}
		}
	}

	return 1;
}

=head2 cfork_wait_pid(PID, PID, PID, ..)

cfork_wait_pid() functions much like cfork_wait() with the exception that it expects a list of PID's and blocks until those PID's have died off.  Like cfork_wait(), cfork_wait_pid() will NOT block if cfork_nonblocking() mode is enabled.

=cut

sub cfork_wait_pid {
	my (@PID) = @_;

	return 1 if $Proc::Fork::Control::HEAP->{nonblocking};

	my $block;
	while(1){
		my @TPID;
		for(my $i = 0; $i < @PID; $i++){
			if(kill(undef, $PID[$i])){
				push @TPID, $PID[$i];
			}
		}

		@PID = (@TPID);

		last if !@PID;

		cfork_usleep(5000);
	}

	return 1;
}


=head2 cfork_active_children()

Return the total number of active children.

=cut

sub cfork_active_children {
	_cleanup();
	return ($Proc::Fork::Control::HEAP->{children} ? $Proc::Fork::Control::HEAP->{children} : 0);
}

=head2 cfork_daemonize(BOOL)

Daemonize the the calling script.

If <BOOL> is true write _ALL_ output to /dev/null.

If you have termination handling, i.e. %SIG and END {} block control, cfork_daemonize triggers exit signal 2. So... $? == 4

=cut

sub cfork_daemonize {
	my $q = $_[0];
	chdir('/') || die "Can't chdir to /: $!\n";
	if(!$q){
		open STDIN,  '/dev/null'   || die "Can't read /dev/null: $!\n";
		open STDOUT, '>/dev/null'  || die "Can't write to /dev/null: $!\n";
		open STDERR, '>&STDOUT'    || die "Can't dup stdout: $!";
	}

	defined(my $pid = fork) || die "Can't fork: $!\n";
	cfork_exit(4) if $pid;
	setsid || die "Can't start a new session: $!\n";
}

=head2 cfork_sleep(int)

Provides an alarm safe sleep() wrapper. Beacuse we sleep() with in this, ALRM will be issued with in the fork once the sleep cycle has completed. This function wraps sleep with in a while() block and tests to make sure that the seconds requested for the sleep were slept.

=cut

sub cfork_sleep {
	my $sleep = $_[0];
	return if $sleep !~ /^\d+$/;

	my $sleeper = 0;
	my $slept = 0;

	while(1){
		if($sleeper < 0 || $sleep <= 0){
			last;
		} elsif(!$sleeper) {
			$sleeper = $sleep;
		}

		my $remain = sleep( abs($sleeper) );

		if($remain ne $sleeper && $remain < $sleep){
			$slept += $remain;
			$sleeper = $sleeper - $remain;

			next;
		} else {
			last;
		}
	}

	return $slept;
}

=head2 cfork_usleep(int)

Provides an alarm safe Time::HiRes usleep() wrapper. Beacuse we sleep() with in this, ALRM will be issued with in the fork once the sleep cycle has completed. This function wraps sleep with in a while() block and tests to make sure that the seconds requested for the sleep were slept.

This function is only avaliable if Time::HiRes is avaliable otherwise it will simply return nothing at all.

=cut

sub cfork_usleep {
	my $sleep = $_[0];

	my $sleeper = 0;
	my $slept = 0;

	while(1){
		if($sleeper < 0 || $sleep <= 0){
			last;
		} elsif(!$sleeper) {
			$sleeper = $sleep;
		}

		my $remain = usleep( abs($sleeper) );

		if($remain ne $sleeper && $remain < $sleep){
			$slept += $remain;
			$sleeper = $sleeper - $remain;

			next;
		} else {
			last;
		}
	}

	return $slept;
}

=head2 cfork_ssleep(int)

Preform an cfork_sleep() except rather than using standard sleep() (with interruption handling) use a select() call to sleep. This can be useful in environments where sleep() does not behave correctly, and a select() will block for the desired number of seconds properly.

=cut

sub cfork_ssleep {
	$Proc::Fork::Control::HEAP->{select_sleep} = 1;
	my $r = cfork_sleep(@_);
	$Proc::Fork::Control::HEAP->{select_sleep} = 0;
	return $r;
}

=head2 cfork_kill_children(SIGNAL)

Send all children (if any) this <SIGNAL>.

If the <SIGNAL> argument is omitted kill TERM will be used.

=cut

sub cfork_kill_children {
	my $sig = $_[0];
	_cleanup();
	if(!$sig){
		$sig = 'TERM';
	}

	if($Proc::Fork::Control::HEAP->{cidlist}){
		kill($sig, keys %{ $Proc::Fork::Control::HEAP->{cidlist} });
	}
}

=head2 cfork_list_children(BOOL)

Return a list of PID's currently running under this fork.

If BOOL is true a hash will be returned rather than a list.

=cut

sub cfork_list_children {
	my ($use_hash) = @_;
	_cleanup();

	if(!$Proc::Fork::Control::HEAP->{cidlist}){
		return;
	}

	if($use_hash){
		return (%{ $Proc::Fork::Control::HEAP->{cidlist} });
	} else {
		return keys %{ $Proc::Fork::Control::HEAP->{cidlist} };
	}
}

=head2 cfork_child_dob(PID)

Return the EPOCH Date of Birth for this childs <PID>

Returns 0 if no child exists under that PID for this fork.

=cut

sub cfork_child_dob {
	my $pid = $_[0];
	_cleanup();
	if($Proc::Fork::Control::HEAP->{cidlist}->{$pid}){
		return $Proc::Fork::Control::HEAP->{cidlist}->{$pid};
	} else {
		return;
	}
}

# Child handler
sub _sigchld {
	my $our;
	while((my $p = waitpid(-1, WNOHANG)) > 0){
		# Mark the process is done ONLY if it's one of our processes.
		if($Proc::Fork::Control::HEAP->{cidlist}->{$p}){
			$Proc::Fork::Control::HEAP->{cidlist}->{$p} = 0;
			$our = 1;
		}
	}

	# self reference only if it's one of our processes.
	if($our){
		$SIG{CHLD} = \&Proc::Fork::Control::_sigchld;
	}
}


# clean up lists - thanks to gmargo@perlmonks for this idea.
sub _cleanup {
	my $i = 0;
	my @dpid = grep { $Proc::Fork::Control::HEAP->{cidlist}->{$_} == 0 } keys %{ $Proc::Fork::Control::HEAP->{cidlist} };
	if(@dpid){
		for(@dpid){
			if(exists $Proc::Fork::Control::HEAP->{cidlist}->{$_}){
				delete $Proc::Fork::Control::HEAP->{cidlist}->{$_};
				$i++;

				$Proc::Fork::Control::HEAP->{children} -- if $Proc::Fork::Control::HEAP->{children};        
			}
		}
	}

	# Do some additional checks to see if these children are really alive.
	for(keys %{ $Proc::Fork::Control::HEAP->{cidlist} }){
		if(!kill(0, $_)){
			if(exists $Proc::Fork::Control::HEAP->{cidlist}->{$_}){
				delete $Proc::Fork::Control::HEAP->{cidlist}->{$_};
				$i++;

				$Proc::Fork::Control::HEAP->{children} -- if $Proc::Fork::Control::HEAP->{children};
			}
		}
	}

	return $i;
}

1;
