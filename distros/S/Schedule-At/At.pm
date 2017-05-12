package Schedule::At;

require 5.004;

# Copyright (c) 1997-2012 Jose A. Rodriguez. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

use vars qw($VERSION @ISA $TIME_FORMAT $SHELL);

$VERSION = '1.15';

$SHELL = '';


###############################################################################
# Load configuration for this OS
###############################################################################

use Config;

my @configs = split (/\./, "$Config{'osname'}");
while (@configs) {
	my $subName = 'AtCfg_' . join('_', @configs);
	$subName =~ s/[^\w\d]/_/g;

	eval "&$subName"; # Call configuration subroutine
	last if !$@; 

	pop @configs;
}

&AtCfg if $@; # Default configuration

###############################################################################
# Public subroutines
###############################################################################

$TIME_FORMAT = '%Q%H%M'; # Format for Date::Manip::DateUnix subroutine

$TAGID = '##### Please, do not remove this Schedule::At TAG: ';

sub add {
	my %params = @_;

	my $command = $AT{($params{FILE} ? 'addFile' : 'add')};
	return &$command($params{JOBID}) if ref($command) eq 'CODE';

	my $atTime = _std2atTime($params{TIME});
	
	$command =~ s/%TIME%/$atTime/g;
	$command =~ s/%FILE%/$params{FILE}/g;

  if ($SHELL) {
    $command = "SHELL=$SHELL $command";
  }

	if ($params{FILE}) {
		return (system($command) / 256);
	} else {
		# Ignore signal to die in case at commands fails
		local $SIG{'PIPE'} = 'IGNORE';

		open (ATCMD, "| $command");
		print ATCMD "$TAGID$params{TAG}\n" if $params{TAG};

		print ATCMD ref($params{COMMAND}) eq "ARRAY" ?
			join("\n", @{$params{COMMAND}}) : $params{COMMAND};
                  
		close (ATCMD);
		return $?;
	}

	0;
}

sub remove {
	my %params = @_;

	if ($params{JOBID}) {
		my $command = $AT{'remove'};
		return &$command(@_) if ref($command) eq 'CODE';

		$command =~ s/%JOBID%/$params{JOBID}/g;

		system($command) >> 8;
	} else {
		return if !defined $params{TAG};

		my %jobs = getJobs();
		my %return;

		foreach my $job (values %jobs) {
			next if !defined($job->{JOBID}) || 
				!defined($job->{TAG});

			if ($job->{JOBID} && $params{TAG} eq $job->{TAG}) {
				$return{$job->{JOBID}} = 
					remove(JOBID => "$job->{JOBID}") 
			}
		}

		return \%return
	}
}

sub getJobs {
	my %param = @_;

	my %jobs;
	
	my $command = $AT{'getJobs'};
	return &$command(@_) if ref($command) eq 'CODE';

	open (ATCMD, "$command |")
		or die "Schedule::At: Can't exec getJobs command: $!\n";
	line: while (defined (my $atLine = <ATCMD>)) {
		if (defined $AT{'headings'}) {
			foreach my $head (@{$AT{'headings'}}) {
				next line if $atLine =~ /$head/;
			}
		}

		chomp $atLine;

		my %atJob;
		($atJob{JOBID}, $atJob{TIME}) 
			= &{$AT{'parseJobList'}}($atLine);
		$atJob{TAG} = _getTag(JOBID => $atJob{JOBID});
		next if $param{TAG} && 
			(!$atJob{TAG} || $atJob{TAG} ne $param{TAG});
		next if $param{JOBID} && 
			(!$atJob{JOBID} || $atJob{JOBID} ne $param{JOBID});
		$jobs{$atJob{JOBID}} = \%atJob;
	}
	close (ATCMD);

	%jobs;
}

sub readJobs {
	my %jobs = getJobs(@_);

	my @job_ids = map { $_->{JOBID} } values %jobs;

	my %content;
	foreach my $jobid (@job_ids) {
		$content{$jobid} = _readJob(JOBID => $jobid);
	}

	%content
}

###############################################################################
# Private subroutines
###############################################################################

sub _readJob {
	my %params = @_;

	my $command = $AT{'getCommand'};
	$command = &$command($params{JOBID}) if ref($command) eq 'CODE';

	$command =~ s/%JOBID%/$params{JOBID}/g;

	local $/ = undef; # slurp mode
	open (JOB, "$command")
		or die "Can't open $command: $!\n";
	my $job = <JOB>;
	close (JOB);

	$job
}

sub _getTag {
	my %params = @_;

	my $job =  _readJob(@_);
	$job =~ /$TAGID(.*)$/m;
	return $1;

	my @job = split("\n", _readJob(@_));
	foreach my $commandLine (@job) {
		return $1 if $commandLine =~ /$TAGID(.*)$/;
	}

	undef;
}

sub _std2atTime {
	my ($stdTime) = @_;

	# StdTime: YYYYMMDDHHMM
	my ($year, $month, $day, $hour, $mins) = 
		$stdTime =~ /(....)(..)(..)(..)(..)/;

	my $timeFormat = $AT{'timeFormat'};	
	return &$timeFormat($year, $month, $day, $hour, $mins) 
		if ref($timeFormat) eq 'CODE';

	$timeFormat =~ s/%YEAR%/$year/g;
	$timeFormat =~ s/%MONTH%/$month/g;
	$timeFormat =~ s/%DAY%/$day/g;
	$timeFormat =~ s/%HOUR%/$hour/g;
	$timeFormat =~ s/%MINS%/$mins/g;

	$timeFormat;
}

=head1 NAME

Schedule::At - OS independent interface to the Unix 'at' command

=head1 SYNOPSIS

 require Schedule::At;

 Schedule::At::add(TIME => $string, COMMAND => $string [, TAG =>$string]);
 Schedule::At::add(TIME => $string, COMMAND => \@array [, TAG =>$string]);
 Schedule::At::add(TIME => $string, FILE => $string)

 %jobs = Schedule::At::getJobs();
 %jobs = Schedule::At::getJobs(JOBID => $string);
 %jobs = Schedule::At::getJobs(TAG => $string);

 Schedule::At::readJobs(JOBID => $string);
 Schedule::At::readJobs(TAG => $string);

 Schedule::At::remove(JOBID => $string);
 Schedule::At::remove(TAG => $string);

=head1 DESCRIPTION

This modules provides an OS independent interface to 'at', the Unix 
command that allows you to execute commands at a specified time.

=over 4

=item Schedule::At::add

Adds a new job to the at queue. 

You have to specify a B<TIME> and a command to execute. The B<TIME> has
a common format: YYYYMMDDHHmm where B<YYYY> is the year (4 digits), B<MM>
the month (01-12), B<DD> is the day (01-31), B<HH> the hour (00-23) and
B<mm> the minutes.

The command is passed with the B<COMMAND> or the B<FILE> parameter.
B<COMMAND> can be used to pass the command as an string, or an array of
commands, and B<FILE> to read the commands from a file.

The optional parameter B<TAG> serves as an application specific way to 
identify a job or a set of jobs.

Returns 0 on success or a value != 0 if an error occurred.

=item Schedule::At::readJobs

Read the job content identified by the B<JOBID> or B<TAG> parameters.

Returns a hash of JOBID => $string where $string is the the job
content. As the operating systems usually add a few environment settings,
the content is longer than the command provided when adding the job.

=item Schedule::At::remove

Remove an at job.

You identify the job to be deleted using the B<JOBID> parameter (an 
opaque string returned by the getJobs subroutine). You can also specify
a job or a set of jobs to delete with the B<TAG> parameter, removing
all the jobs that have the same tag (as specified with the add subroutine).

Used with JOBID, returns 0 on success or a value != 0 if an error occurred.
Used with TAG, returns a hash reference where the keys are the JOBID of
the jobs found and the values indicate the success of the remove operation.

=item Schedule::At::getJobs

Called with no params returns a hash with all the current jobs or 
dies if an error has occurred. 
It's possible to specify the B<TAG> or B<JOBID> parameters so only matching
jobs are returned.
For each job the key is a JOBID (an OS dependent string that shouldn't be 
interpreted), and the value is a hash reference. 

This hash reference points to a hash with the keys:

=over 4

=item TIME

An OS dependent string specifying the time to execute the command

=item TAG

The tag specified in the Schedule::At::add subroutine

=back

=back

=head1 Configuration Variables

=over 4

=item *

$Schedule::At::SHELL

This variable can be used to specify shell for execution of the scheduled command.
Can be useful for example when scheduling from CGI script and the account of the user under which httpd runs
is locked by using '/bin/false' or similar as a shell.

=back


=head1 EXAMPLES

 use Schedule::At;

 # 1
 Schedule::At::add (TIME => '199801181530', COMMAND => 'ls', 
	TAG => 'ScheduleAt');
 # 2
 @cmdlist = ("ls", "echo hello world");

 Schedule::At::add (TIME => '199801181630', COMMAND => \@cmdlist, 
	TAG => 'ScheduleAt');
 # 3
 Schedule::At::add (TIME => '199801181730', COMMAND => 'df');

 # This will remove #1 and #2 but no #3
 Schedule::At::remove (TAG => 'ScheduleAt');

 my %atJobs = Schedule::At::getJobs();
 foreach my $job (values %atJobs) {
	print "\t", $job->{JOBID}, "\t", $job->{TIME}, ' ', 
		($job->{TAG} || ''), "\n";
 } 

=head1 AUTHOR

Jose A. Rodriguez (jose AT rodriguez.jp)

=cut

###############################################################################
# OS dependent code
###############################################################################

sub AtCfg {
	# Currently the default configuration just aborts
	die "SORRY! There is no config for this OS.\n";
}

sub AtCfg_solaris {
	$AT{'add'} = 'at %TIME% 2> /dev/null';
	$AT{'addFile'} = 'at -f %FILE% %TIME% 2> /dev/null';
	$AT{'timeFormat'} = sub { 
		my ($year, $month, $day, $hour, $mins) = @_;

		my @months = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
			'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');

		"$hour:$mins " . $months[$month-1] . " $day, $year";
	};
	$AT{'remove'} = 'at -r %JOBID%';
	$AT{'getJobs'} = 'at -l';
	$AT{'headings'} = [];
	$AT{'getCommand'} = '/usr/spool/cron/atjobs/%JOBID%';
	# Ignore "user = xxx" when executed by root
	$AT{'parseJobList'} = sub { $_[0] =~ /^.*(\d{10}.a)\s+(.*)$/ };
}

sub AtCfg_sunos {
	&AtCfg_solaris;
	$AT{'getCommand'} = sub {
		my ($jobid) = @_;

		for my $filename (glob('/usr/spool/cron/atjobs/*')) {
			return $filename if (stat($filename))[1] == $jobid;
		}

		undef;
	}
}

sub AtCfg_dec_osf {
	&AtCfg_solaris;
	# josear.1137594600.a     Wed Jan 18 15:30:00 2006
	$AT{'parseJobList'} = sub { $_[0] =~ /^(\S+)\s+(.*)$/ };
}

sub AtCfg_hpux {
	$AT{'add'} = 'at %TIME% 2> /dev/null';
	$AT{'addFile'} = 'at -f %FILE% %TIME% 2> /dev/null';
	$AT{'timeFormat'} = '%HOUR%:%MINS% %MONTH%/%DAY%/%YEAR%';
	$AT{'remove'} = 'at -r %JOBID%';
	$AT{'getJobs'} = 'at -l';
	$AT{'headings'} = [];
	$AT{'getCommand'} = '/usr/spool/cron/atjobs/%JOBID%';
	$AT{'parseJobList'} = sub { $_[0] =~ /^(\S+)\s+(.*)$/ };
}

sub AtCfg_linux {
	$AT{'add'} = 'at %TIME% 2> /dev/null';
	$AT{'addFile'} = 'at -f %FILE% %TIME% 2> /dev/null';
	$AT{'timeFormat'} = '%HOUR%:%MINS% %MONTH%/%DAY%/%YEAR%';
	$AT{'remove'} = 'atrm %JOBID%';
	$AT{'getJobs'} = 'atq';
	$AT{'headings'} = ['Date'];
	$AT{'getCommand'} = 'at -c %JOBID% |';
	# 1	2003-01-18 15:30 a josear
	# 10	Tue Jan 31 10:00:00 2012 a josear (debian)
	$AT{'parseJobList'} = sub { 
		my @fields = split("\t", $_[0]);
		my $date = substr($fields[1], 0, 
			($fields[1] =~ /^d/) ? 16 : 24);
		($fields[0], $date) 
	};
}

sub AtCfg_aix {
	$AT{'add'} = 'at -t %TIME% 2> /dev/null';
	$AT{'addFile'} = 'at -f %FILE% %TIME% 2> /dev/null';
	$AT{'timeFormat'} = '%YEAR%%MONTH%%DAY%%HOUR%%MINS%';
	$AT{'remove'} = 'at -r %JOBID%';
	$AT{'getJobs'} = 'at -l';
	$AT{'headings'} = [];

	# Only for privileged users (group system), so use alternate command
	#$AT{'getCommand'} = '/usr/spool/cron/atjobs/%JOBID%';
	$AT{'getCommand'} = 'at -lv %JOBID% |tail +4 |';

	$AT{'parseJobList'} = sub { $_[0] =~ /^(\S+)\s+(.*)$/ };
}

sub AtCfg_dynixptx {
	$AT{'add'} = 'at %TIME% 2> /dev/null';
	$AT{'addFile'} = 'at -f %FILE% %TIME% 2> /dev/null';
	$AT{'timeFormat'} = sub {
	        my ($year, $month, $day, $hour, $mins) = @_;

	        my @months = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
	                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');

	        "$hour:$mins " . $months[$month-1] . " $day, $year";
	};
	$AT{'remove'} = 'at -r %JOBID%';
	$AT{'getJobs'} = 'at -l';
	$AT{'headings'} = [];
	$AT{'getCommand'} = '/usr/spool/cron/atjobs/%JOBID%';
	$AT{'parseJobList'} = sub {
	        my $user = scalar getpwuid $<;
	        if ($user eq 'root') {
	                $_[0] =~ /^\s*\S+\s*\S+\s*\S+\s*(\S+)\s+(.*)$/
	        }
	        else {
	                $_[0] =~ /(\S+)\s+(.*)$/
	        }
	};
}

sub AtCfg_freebsd {
	$AT{'add'} = 'at %TIME% 2> /dev/null';
	$AT{'addFile'} = 'at -f %FILE% %TIME% 2> /dev/null';
	$AT{'timeFormat'} = sub {
		my ($year, $month, $day, $hour, $mins) = @_;

	my @months = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
		'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');

	        "$hour:$mins " . $months[$month-1] . " $day $year";
	};
	$AT{'remove'} = 'atrm %JOBID%';
	$AT{'getJobs'} = 'at -l';
	$AT{'headings'} = ['Date', 'Owner', 'Queue', 'Job'];
	$AT{'getCommand'} = 'at -c %JOBID% | '; 
	$AT{'parseJobList'} = sub { $_[0] =~ s/^\s*(.+)\s+\S+\s+\S+\s+(\d+)$/$2_$1/; $_[0] =~ /^(.+)_(.+)$/ };
}

sub AtCfg_netbsd {  
        &AtCfg_freebsd;
}

sub AtCfg_dragonfly {  
        &AtCfg_freebsd;
}

sub AtCfg_openbsd {
        &AtCfg_freebsd;
        $AT{'headings'} = [];
        $AT{'parseJobList'} = sub { $_[0] =~ /^.*(\d{10}.c)\s+(.*)$/ };
}

# Mac OS X (darwin, tiger)
sub AtCfg_darwin {
	$AT{'add'} = 'at %TIME% 2> /dev/null';
	$AT{'addFile'} = 'at -f %FILE% %TIME% 2> /dev/null';
	$AT{'timeFormat'} = '%HOUR%:%MINS% %MONTH%/%DAY%/%YEAR%';
	$AT{'remove'} = 'atrm %JOBID%';
	$AT{'getJobs'} = 'atq';
	$AT{'headings'} = ['Job','Date'];
	$AT{'getCommand'} = 'at -c %JOBID% | ';
	# 74      Wed Jan 18 15:32:00 2006
	$AT{'parseJobList'} = sub {
		my @fields = split("\t", $_[0]);
		($fields[0], substr($fields[1], 0, 16)) 
	};
}
