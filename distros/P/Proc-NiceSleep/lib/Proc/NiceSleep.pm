package Proc::NiceSleep; 

#############################################################################
# Proc::NiceSleep - intelligent sleeping library
#
# Copyright (c) 2002-2018 Josh Rabinowitz, licensed the same as
# perl itself, see COPYRIGHT below
#
# see full pod perldocs below after __END__  or via perldoc NiceSleep.pm
#
#############################################################################

use 5.004;	# tested this far back and up to 5.10.0
use strict;	# please
#use warnings;	# doesn't exist in 5.004

require Exporter;
#use AutoLoader qw(AUTOLOAD);	# we don't use this yet

# We do 'use vars' like this so we can work nicely in old versions of perl
use vars qw($VERSION);

$VERSION = '0.91';

# these are 'public'
use vars qw ( %EXPORT_TAGS @EXPORT_OK @ISA );

@ISA = qw(Exporter);

# This allows declaration	use Proc::NiceSleep ':all';
%EXPORT_TAGS = ( 'all' => [ qw(
	nice maybe_sleep max_load sleep_factor min_run_time min_sleep_time 
	over_load_min_sleep_time over_load_sleep_drift
	load_function
	maybesleep maxload sleepfactor minruntime minsleeptime
	yield
) ] );

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

# these are private. 
use vars qw ( $_sleepfactor $_minruntime $_minsleeptime $_maxload 
		$_over_load_minsleeptime $_over_load_sleep_drift
		$_totalsleeptime $_lastsleeptime $_lastmaybesleeptime $_lastloadchecktime 
		$_numtimesslept $_numtimesmaybesleepcalled $_numtimesloadchecked
		@_lastloadavgs $_starttime
		$_havetimehires $_havetimehires $_havesetpriority 
		$_haveprocprocesstable $_havesyscpuload $_havebsdresource
		$_loadfunction); 
# variables prefixed by _ are intended to be private, here we explain them
#$_lastsleeptime;	# the last time we slept, from time()
#$_lastloadchecktime;	# the last time we checked load()
#@_lastloadavgs;	# the values from _GetCpuLoad last time we checked
#$_starttime;			# the time we finished init()
#$_sleepfactor;	# 1.0 means to sleep 1.0 times as long as we 'run'
				# 0.0 means don't sleep based on fraction of tmie
#$_minruntime;	# how long we run before considering yielding
#$_minsleeptime;	# minimum time to sleep, if we do
#$_maxload;		# the maximum 1-minute avg system load we yield at,
				# if supported and Sys::CpuLoad works
#					# does not include time sleeping in maybe_sleep()
#$_totalsleeptime;	# how long we slept in maybe_sleep(), 
#						# in apparent wallclock seconds
#$_havetimehires;		# do we have Time::HiRes ?
#$_haveprocprocesstable;	# do we have Proc::ProcessTable?
#$_havesyscpuload;			# do we have Sys::CpuLoad?
#$_havesetpriority;		# do we have a setpriority() call?

# all through we use Time::HiRes or built-in versions of
# time() and sleep(), and get microsecond res ... or not.

#############################################################################
# Preloaded methods go here.
#############################################################################

# nice() this renices the process, like /bin/nice, if it can.
# if passed an integer parameter (between -20 to 20 inclusive)
#   it attempts to set the priority and returns the priority 
#   it tried to set the process to.
# if called without a parameter, returns what it thinks its priority is
# does not work on win32 (always should return 0); use maybe_sleep() ! :)
sub nice {
	unless (defined($_lastsleeptime)) { init(); }	# autoinit on first use
	my $param = shift;
	# 'man setpriority' on rh7.2: The setpriority call returns 0 if there 
	# is no error, or -1 if there is.
		# even though man page says the above, setpriority(0,0,5) returns 1
		# on RH7.2
	if (defined($param)) {
		$param = int($param);	# pass me an int, holmes
		if ($_havesetpriority && setpriority(0,0,$param) != -1) {
			return $param;
		} else {
			return 0;
		} 
	} 
	return ($_havesetpriority ? getpriority(0,0) : 0); 
	# no param, return what we think the nice value is.
} 

# keep calling maybe_sleep() until maxsleep seconds have passed 
# or it doesn't need to sleep anymore.
# pass '0' for infinite yield
sub yield {
	my $maxsleep = shift || 0;
	my $t1 = time();
	my $sleeptime = 0;
	my $slept = 0;
	do  {
		$slept = maybe_sleep();
		$sleeptime += $slept;
	} while ($slept && (!$maxsleep || $sleeptime <= $maxsleep));
	return $sleeptime;
}

# checks to see if we should sleep.
# returns how long we think we slept if we did, 0 otherwise
sub maybe_sleep {	
	unless (defined($_lastsleeptime)) { init(); }	# autoinit on first use
	$_numtimesmaybesleepcalled++;
	my $t1 = ($_havetimehires ? Time::HiRes::time() : CORE::time());
	$_lastmaybesleeptime = $t1;
	my $timepassed = $t1 - $_lastsleeptime;
	my ($timetosleep, $timeslept) = (0, 0);
	if ($_minruntime && $timepassed < $_minruntime) { return 0; }
	if ($_sleepfactor) {
		if ($_totalsleeptime == 0) {
			$timetosleep = $_sleepfactor * $timepassed;
			#print "Debug1: timetosleep = $timetosleep\n";
		} else {
			my $totalruntime = $t1 - $_starttime - $_totalsleeptime;
				# we've actually seen $totalruntime be zero when there's no
				# Time::HiRes
			if ($totalruntime > 0) {	# avoid divide by zero below
				my $actualratio = $_totalsleeptime / $totalruntime;
				if ($actualratio < $_sleepfactor) {
					$timetosleep = 
						$_sleepfactor * $totalruntime - $_totalsleeptime;
				}
			}
			$timetosleep = 0 if ($timetosleep < 0);
			#print "Debug2: timetosleep = $timetosleep\n";
		}
	} 
	if ($_maxload && ($t1 - $_lastloadchecktime >= 0.5)) {
		# we only check the load a max of about once per half second
		my (@loads) = _GetCpuLoad();	# (1minavg, 5minavg, 15minavg)
		@_lastloadavgs = @loads;
		if ($loads[0] && $loads[0] > $_maxload) {	
			# sleep if load is too high
			my $drift = rand($_over_load_sleep_drift);
			$timetosleep = MAX( 
				$_over_load_minsleeptime    + $drift,
				4 * ($loads[0] - $_maxload) + $drift,	# diff between current load and max load
				$timetosleep, 
				$_minsleeptime,
			);	
		} 
	}
	if ($timetosleep) {	# we should sleep... snore....
		if ($_minsleeptime && $timetosleep < $_minsleeptime) {
			if ($timetosleep <= 0) { $timetosleep = 0; } # can't be neg
			$timetosleep = $_minsleeptime;
		}
		if($_havetimehires) {
			Time::HiRes::sleep($timetosleep);	# yield the system via sleep
		} else {
			$timetosleep = int($timetosleep + .5);	# round off.
			if ($timetosleep <= 0) { $timetosleep = 1; } # can't be neg or 0
			CORE::sleep($timetosleep);	# actually yield the system via sleep
		}
		my $t2 = ($_havetimehires ? Time::HiRes::time() : CORE::time());
		my $actualsleeptime = $t2 - $t1;
		$_totalsleeptime += $actualsleeptime;	# how long we slept
		$_lastsleeptime = $t2;					# record this
		$timeslept = $actualsleeptime;				# for return
		$_numtimesslept++;
	}
	return $timeslept;	# in case they wonder. this is how long we slept
}
# sets or gets, depending on whether it gets param or not
sub sleep_factor {
	unless (defined($_lastsleeptime)) { init(); }	# autoinit on first use
	my $param = shift;
	if (defined($param)) { 
		$param = 0 if ($param < 0);	# don't allow negative sleep_factor
		$_sleepfactor = $param; 
	} 
	else { return $_sleepfactor; }
} 
# sets or gets, depending on whether it gets param or not
sub min_sleep_time {
	unless (defined($_lastsleeptime)) { init(); }	# autoinit on first use
	my $param = shift;
	if (defined($param)) { 
		$param = 0 if ($param < 0);	# don't allow negative value
		$_minsleeptime = $param; 
	} 
	else { return $_minsleeptime; } 
}
# sets or gets, depending on whether it gets param or not
sub min_run_time {
	unless (defined($_lastsleeptime)) { init(); }	# autoinit on first use
	my $param = shift;
	if (defined($param)) { 
		$param = 0 if ($param < 0);	# don't allow negative value
		$_minruntime = $param; 
	} 
	else { return $_minruntime; } 
}
# sets or gets, depending on whether it gets param or not
sub max_load {
	unless (defined($_lastsleeptime)) { init(); }	# autoinit on first use
	my $param = shift;
	if (defined($param)) { 
		$param = 0 if ($param < 0);	# don't allow negative value
		$_maxload = $param; 
	} 
	else { return $_maxload; } 
}
# sets or gets, depending on whether it gets param or not
sub over_load_min_sleep_time {
	unless (defined($_lastsleeptime)) { init(); }	# autoinit on first use
	my $param = shift;
	if (defined($param)) { 
		$param = 0 if ($param < 0);	# don't allow negative value
		$_over_load_minsleeptime = $param; 
	} 
	else { return $_over_load_minsleeptime; } 
}
# sets or gets, depending on whether it gets param or not
sub over_load_sleep_drift {
	unless (defined($_lastsleeptime)) { init(); }	# autoinit on first use
	my $param = shift;
	if (defined($param)) { 
		$param = 0 if ($param < 0);	# don't allow negative value
		$_over_load_sleep_drift = $param; 
	} 
	else { return $_over_load_sleep_drift; } 
}
# returns a ref to a hash with data about the progress...
# for informational purposes only. return values subject to change.
sub Dump {
	unless (defined($_lastsleeptime)) { init(); }	# autoinit on first use
	my %hash = (
		#HAVE_TIME_HIRES => $_havetimehires,
		#HAVE_PROC_PROCESSTABLE => $_haveprocprocesstable,
		#HAVE_SYS_CPULOAD => $_havesyscpuload,
		#HAVE_SETPRIORITY => $_havesetpriority,
		LAST_LOAD_CHECK_TIME => dump_clock($_lastloadchecktime),
		LAST_LOAD_AVERAGES =>  join(" ", @_lastloadavgs),
		LAST_SLEEP_TIME => dump_clock($_lastsleeptime),
		LAST_MAYBE_SLEEP_TIME => dump_clock($_lastmaybesleeptime),
		MAX_LOAD => $_maxload,
		#LOAD_FUNCTION => $_loadfunction,
		MIN_RUN_TIME => $_minruntime,
		MIN_SLEEP_TIME => $_minsleeptime,
		SLEEP_FACTOR => $_sleepfactor,
		TOTAL_RUN_TIME => 
			(Proc::NiceSleep::time() - $_starttime - $_totalsleeptime),
		TOTAL_SLEEP_TIME => $_totalsleeptime,
		NUM_TIMES_SLEPT => $_numtimesslept,
		NUM_TIMES_LOAD_CHECKED => $_numtimesloadchecked,
		NUM_TIMES_MAYBE_SLEEP_CALLED => $_numtimesmaybesleepcalled,
		 # extra comma here is ok, cool!  
	);
	return \%hash;
}
# this is for informational purposes only. Data and its output subject to change
# written to remove dependence on Data::Dumper in our examples
sub DumpText { 
	# a convenient method to ascii-ify return of Dump() nicely for reporting.
	unless (defined($_lastsleeptime)) { init(); }	# autoinit on first use
	my $hashref = Dump();
	my $str = "";
	for my $e (sort keys(%$hashref)) {	# the entry name
		my $v = $$hashref{$e};	# the value
		if (!defined($v)) {
			$str .= sprintf("  %-28s: (undef)\n", $e); 
		} elsif ($v =~ /^([0-9.]+)$/ && (int($v) != $v) ) {
			$str .= sprintf("  %-28s: %1.3f\n", $e, $v);
		} else {
			$str .= sprintf("  %-28s: %s\n", $e, $v);
		}
	}
	return $str;	# returns a nice, ascii text page of the name/vals :)
}

# if called with param, sets the load
sub load_function {
	unless (defined($_lastsleeptime)) { init(); }	# autoinit on first use
	if (@_) { 
		$_loadfunction = shift; 
	} else { return $_loadfunction; }
}

# time() and sleep() are so test programs don't have to test for Time::HiRes
# they do hi-res if possible. They are also shown used in example.pl, 
# but are not documented as public... should they be, kind reader?
sub time  { ($_havetimehires ? Time::HiRes::time()    : CORE::time());    }
sub sleep { ($_havetimehires ? Time::HiRes::sleep(@_) : CORE::sleep(@_)); }

#############################################################################
#  THESE ARE FOR TEMPORARY REVERSE SUPPORT. Soon we'll give warnings, 
# eventually we'll remove them
#############################################################################
sub	maybesleep { return maybe_sleep(@_); }
sub maxload { return max_load(@_); }
sub sleepfactor { return sleep_factor(@_); }
sub minruntime { return min_run_time(@_); }
sub minsleeptime { return min_sleep_time(@_); }

#############################################################################
#  THINGS AFTER HERE (until perldocs) ARE PRIVATE METHODS !!!
#############################################################################
sub dump_clock { return (($_[0]) ? scalar(localtime($_[0])) : 0); }
sub MAX { my $max = shift; for(@_) { $max = $_ if $_ > $max; } return $max; } 

sub init {		# intended to be private
	# try to load Time::HiRes and ProcessTable

	eval{ require Time::HiRes };
	if ($@) { $_havetimehires = 0; } else { $_havetimehires = 1; }
	# eval alone can't seem to import sleep() and time() from Time::HiRes.
	# 'use Time::HiRes qw(sleep time);' from here doesn't seem to get 
	# sleep() and time() imported outside this function, either.

	#eval{require Proc::ProcessTable; };  # we don't use this.... yet.
	#if ($@) { $_haveprocprocesstable = 0 } else { $_haveprocprocesstable = 1 }

	eval{
		require Sys::CpuLoad; 
		my @l=Sys::CpuLoad::load(); 
		die unless (@l > 2 && defined($l[0]) && $l[0] =~ /^\s*[0-9]*\.?[0-9]+$/);
	};  
	if ($@) { $_havesyscpuload = 0 } else { $_havesyscpuload = 1 }

	eval{ my $pri=getpriority(0,0); setpriority(0,0,$pri); };  
		# check for setpriority() and setpriority() with a (hopefully) no-op
	if ($@) { $_havesetpriority = 0 } else { $_havesetpriority = 1 }

	eval{ require BSD::Resource; };
	if ($@) { $_havebsdresource = 0; } else { $_havebsdresource = 1; }

	$_sleepfactor = 0.1; # the default
	$_minruntime = 0.0;	
		# can be meaningfully this short if we have Time::HiRes
	$_minsleeptime = 0;	# no 'minimum' time to sleep by default
	$_over_load_minsleeptime = 3.5;	# 4 was default from v0.77
	$_over_load_sleep_drift = 1;
	$_maxload = 0;		# 0 means don't watch loads
	$_loadfunction = undef;		# reset this too
	@_lastloadavgs = (0,0,0);
	Proc::NiceSleep::reset_all();
}

sub reset_all { 
	$_numtimesslept = 0;
	$_numtimesmaybesleepcalled = 0;
	$_numtimesloadchecked = 0;
	$_totalsleeptime = 0;
	$_lastloadchecktime = 0;
	$_lastmaybesleeptime = 0;
	$_lastsleeptime = 
		$_starttime = Proc::NiceSleep::time();
}

# Invariant(): attempt to check that the vars are self-consistent.
# returns 1 if OK, 0 if object 'bad'. Not intended to be called often
sub Invariant {	# intended to be private.  Used in tests
	unless (defined($_lastsleeptime)) { init(); }	# autoinit on first use
	# check obvious things:
	# can we load a method/func from each mod we loaded?
	if ($_havetimehires) { 	# this will die if we can't load func
		my $t = Time::HiRes::time(); 
		Time::HiRes::sleep(0.0001);
	}
	if ($_havesyscpuload) { 	# this will die if we can't load func
		my @l = Sys::CpuLoad::load();
	} 
	# if we think we have Time::HiRes, is time() fractional? Inverse?
	# we used to test that we did or didn't get fractional times, but
	# it turns out that just cause you have Time::HiRes doesn't mean you
	# get fractional times and sleeps.
	if ($_havetimehires) { # could still be integer-based 
		#my ($t1, $t2) = (time(), time());	# at least ONE shouldn't be int
		#return 0 if ($t1 == int($t1) && $t2 == int($t2));
	} else {
		# we assume no version of perl has a sub-second time() in CORE (!)
		my ($t1, $t2) = (CORE::time(), CORE::time());	# both should be ints
		return 1 if ($t1 != int($t1) || $t2 != int($t2));
		# but really, even if times are floating point, everything is probably ok
	}
	return 1;	# that's all we test... seems ok!
}

# on some machines, Sys::CpuLoad won't get the load, but it's still 
# possible to fetch. So we try harder.
sub _GetCpuLoad { 
	unless (defined($_lastsleeptime)) { init(); }	# autoinit on first use
	$_numtimesloadchecked++;
	$_lastloadchecktime = Proc::NiceSleep::time();
	if ($_loadfunction) {		# use the load function if we can 
		my (@L) = &${_loadfunction}();
		return @L if @L;
	}
	my @loads = (0,0,0);
	if ($_havesyscpuload) {
		@loads = Sys::CpuLoad::load();
	} 
	if ($loads[0] == 0) {	# either the load is that low, or Sys::CpuLoad::load() is
							# just returning (0,0,0) as it does on OSX 10.3 as of 11/2004

		local( %ENV );		# for taint safety
		@ENV{qw(PATH BASH_ENV)} = ( "/usr/bin:/bin",  ""); 

		open(UPTIME, "/usr/bin/uptime |") || return @loads; 
		my $out = <UPTIME>;		# read one line.
		chomp($out);
		close(UPTIME) || return @loads;	# this could fail if pipe didn't work
		if ($out && $out =~ /([0-9.]+)\s+([0-9.]+)\s+([0-9.]+)\s*$/) {
			@loads = ($1, $2, $3); 
		}
	} 
	return @loads;
}

# Autoload methods go after =cut, and are processed by the autosplit program.
# we have none ... yet.
#############################################################################
1;

__END__

# Below is documentation for Proc::NiceSleep 

=head1 NAME

Proc::NiceSleep - yield system in an intelligent fashion

=head1 SYNOPSIS

  use Proc::NiceSleep qw( :all ); 
  nice(5);              # lower our priority, if our OS supports it 
  max_load(1.1);        # max load we allow, if GetCpuLoad can find loads
  sleep_factor(.5);     # sleep 50% as long as we run
  min_run_time(2);      # run at least 2 seconds without sleep
  while($somecondition) {
    #dosomething();
    $slept = maybe_sleep(); # sleep some amount of time if needed 
  }

=head1 DESCRIPTION

Proc::NiceSleep defines subroutines to allow a process to yield 
use of the system according to a configured policy.  

Proc::NiceSleep is intended for use in situations where the 
operating system does not support priorities, or where using the 
operating system's built-in priorities does not yield the system 
sufficiently. 

By default Proc::NiceSleep expects to yield the process for 
one tenth the amount of time that process runs. 
This is expressed by the default Sleep Factor of 0.10 and can be 
set via sleep_factor( $n ).

Proc::NiceSleep can also be configured to attempt to keep the 
average system load below a certain threshhold through use of the
max_load() function.

A convenient nice() function, which acts much like the shell 
command and executable of the same name, is also provided 
for easy, platform independent access to your system's 
priorities (if available). 

If Proc::NiceSleep autodetects the presence of the Time::HiRes 
module (and your operating system supports it) then timing and yielding
operations will occur with sub-second granularity.
If not, no warning or error will be issued but Proc::NiceSleep operations 
will occur with a granularity of about one second. Sys::CpuLoad must
be found for max_load() to have any effect.

The following functions can be imported from this module.

=over 4

=item maybe_sleep ()

Checks to see if this process should yield use of the system by
issuing some kind of sleep at this point, and if so, does so 
for an appropriate amount of time.  Returns 0 if no sleep was 
performed, otherwise returns the amount of seconds maybe_sleep() 
actually slept for.

=item maybe_sleep ( $maxsleeptime )

Calls maybe_sleep() until it returns 0 or $maxsleeptime has passed. 
Returns the sum of the times maybe_sleep() slept.  

=item max_load ( $max_load )

Set or gets the maximum 1-minute average load allowed to occur 
before a sleep call will be issued by maybe_sleep(), depending 
on whether a parameter is passed or not.  The default value
of 0 disables this feature; setting the maximum load will only have 
an effect if Sys::CpuLoad is successfully loaded (or an alternate load
retrieval function is provided through load_function()).  This 
module will check the system load no more than about once per second.  
If both sleep_factor() and max_load() are used then maybe_sleep() 
will yield the system if either condition is met. 

=item sleep_factor ( $factor )

Sets or gets the sleep factor depending on whether a number is 
passed or not.  A sleep factor of 1 means to sleep an equal amount 
of time as we run, 2 means to sleep twice as long, and so on. The default
value is 0.1. If the sleep factor is set to zero, then this feature is
disabled. If both sleep_factor() and max_load() are used then maybe_sleep()
will yield the system if either condition is met.

=item nice ()

Sets or gets the priority of the process, as understood by the operating system.
If passed an integer, nice() attempts to set priority of the process to the 
value specified, and returns that value.  If no parameter is passed, 
nice() attempts to query the operating system for the priority of the 
process and return it.  If your OS doesn't support priorities then 
nice() will likely have no effect and always return 0.  

The exact nice() values returned and recognized, and their meanings 
to the system, are system dependent but usually range from about 
-20 (highest priority) to 20 (lowest priority, 'nicest').  

=item min_run_time ()

Sets or gets the minimum run time, in seconds, depending on whether 
a number is passed or not. The minumum run time is the least amount of time 
that Proc::NiceSleep will allow the process to run between sleeps. 
The default value is 0 seconds.

=item min_sleep_time ()

Sets or gets the minimum amount time, in seconds, that maybe_sleep() will
sleep for if it detects that a sleep is appropriate. The default it 0.

=item over_load_min_sleep_time ()

Sets or gets the minimum amount time, in seconds, that maybe_sleep() will
sleep when the load has gone above the max_load().  
The default is 3.5 seconds.

=item over_load_sleep_drift ()

Sets or gets the 'drift' in the amount time, that maybe_sleep() will
sleep when the load has gone above the value set with max_load().  
The actual amount of time chosen to sleep will be between
over_load_min_sleep_time()  and  
over_load_min_sleep_time() + ( 4 * (curload - targetload) * over_load_sleep_drift() ) 
seconds (that is, it will sleep longer as the system load goes up.)
The default is over_load_sleep_drift is 1.

=item load_function( \&function )

Sets or gets a reference to a function to be used by maybe_sleep()
that returns numbers that should be considered the 
1, 5, and 15-minute average system loads. (Only the 1-minute 
average is used). Set to undef (the default) to use your
system's load.

=item reset_all ()

Resets the internal statistics to act as if the process had just started.  

=item DumpText ()

Returns a string (intended for display) containing multiple lines 
with internal information about Proc::NiceSleep's runtime configuration 
and statistics. The format and contents of the returned string are 
intended for informational and debugging use and are subject to change.

=item Dump ()

Returns a reference to a hash with internal information about Proc::NiceSleep
configuration and statistics. The names and presence of the returned hash 
names and values are for informational and debugging purposes only and 
are subject to change. Modifying the returned hash will have no effect on 
the operation of Proc::NiceSleep.

=back

=head1 EXPORT

None by default.  

=head1 AUTHOR

Josh Rabinowitz, E<lt>Josh RabinowitzE<gt>

=head1 CAVEATS

The meanings of values accepted by nice() may vary between operating
systems (e.g. HP-UX). This problem is to be addressed in 
future revisions to this package; for now be advised that use of nice() 
is not necessarily portable.

Uncoordinated use of sleep() (and possibly of signal() and alarm()) in 
your perl program may cause your program to yield the system more or 
less than specified via Proc::NiceSleep policies.

=head1 SEE ALSO

L<Time::HiRes>, L<Sys::CpuLoad>

=head1 COPYRIGHT

Copyright (c) 2002-2012 Josh Rabinowitz.  All rights reserved. 
This program is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.  

=head1 ACKNOWLEDGEMENTS

Proc::NiceSleep is loosely modeled on Lincoln Stein's CGI.pm, and 
on D. Wegscheid and other's Time::HiRes.pm.  Thanks to Michael G Schwern, 
Terrence Brannon, and David Alban for their valuable input.

=head1 LINKS

	http://search.cpan.org/~joshr/  : CPAN home page
	http://joshr.com/src/           : my website

=cut

