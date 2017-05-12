#
# This is a nonsucking forking module.
# Coded by:
# 	Brad Lhotsky <brad@divisionbyzero.net>
# Contributions by:
#	Mark Thomas <mark@ackers.net>
#
package Parallel::ForkControl;
use strict;
use warnings;

use POSIX qw/:signal_h :errno_h :sys_wait_h/;
use Storable qw(freeze thaw);
use Try::Tiny;
use CHI;

our $AUTOLOAD;
our $VERSION = 0.5;

use constant TRUE => 1;
use constant FALSE => 0;

use constant DEFAULT => 0;
use constant PERMISSION => 1;
use constant PERMIT_ALL => 'init/set/get/copy';

##################
# Debug constants
use constant DB_OFF	=> 0;
use constant DB_INFO	=> 1;
use constant DB_LOW	=> 2;
use constant DB_MED	=> 3;
use constant DB_HIGH	=> 4;

{
 # private data members
	my %_attributes = (
		# Name			     # defaults				# permissions
		'_name'				=> [ 'Unnamed Child',	PERMIT_ALL	],
		'_processtimeout'	=> [ 120,				PERMIT_ALL	],
		'_maxkids'			=> [ 5,					PERMIT_ALL	],
		'_minkids'			=> [ 1,					PERMIT_ALL	],
		'_maxload'			=> [ 4.50,				PERMIT_ALL	],
		'_maxmem'			=> [ 10.0,				PERMIT_ALL	],	# non functional
		'_maxcpu'			=> [ 25.0,				PERMIT_ALL	],
		'_method'			=> [ 'cycle',			PERMIT_ALL	],
		'_watchcount'		=> [ TRUE,				PERMIT_ALL	],
		'_watchload'		=> [ FALSE,				PERMIT_ALL	],
		'_watchmem'			=> [ FALSE,				PERMIT_ALL	],	# non functional
		'_watchcpu'			=> [ FALSE,				PERMIT_ALL	],	# non functional
		'_parentpid'		=> [ $$,				'get/set'	],
		'_code'				=> [ undef,				'init/get/set'	],
		'_debug'			=> [ DB_OFF,			'init/get/set'	],
		'_check_at'			=> [ 2,					PERMIT_ALL 	],
		'_checked'			=> [ 0,					'get/init'	],
		'_accounting'		=> [ FALSE,				PERMIT_ALL	],
		'_results'			=> [ undef,				'get'		],
		'_trackargs'		=> [ FALSE,				PERMIT_ALL	]
	);
	
	my %_KIDS=();
	my $_KIDS=0;
 # private member accessors
	sub _attributes {
		# return an array of our attributes
		return keys %_attributes;
	}
	sub _default {
		# return the default for a set attribute
		my ($self,$attr) = @_;
		$attr =~ tr/[A-Z]/[a-z]/;
		$attr =~ s/^\s*_?/_/;
		return unless exists $_attributes{$attr};
		return $_attributes{$attr}->[DEFAULT];
	}
	sub _can {
		# return TRUE if we can $perm the $attr
		my ($self,$perm,$attr) = @_;	
		$attr =~ tr/[A-Z]/[a-z]/;
		$attr =~ s/^\s*_?/_/;
		return unless exists $_attributes{$attr};
		$perm =~ tr/[A-Z]/[a-z/;
		return TRUE if $_attributes{$attr}->[PERMISSION] =~ /$perm/;
		return FALSE;
	}
	sub _kidstarted {
		# keep records of our children
		my ($self,$kid,@args) = @_;
		$self->_dbmsg(DB_LOW,"CHILD: $kid STARTING");
		#
		# use time() here to implement the process time out
		$_KIDS{$kid} = time;

		$self->{_results}{$kid} = {
			status		=> 'running',
			signature	=> undef,
			result		=> undef,
			exitcode	=> undef,
			error		=> undef
		} if $self->get_accounting();

		$self->_kid_signature($kid,@args);
		#
		# increment the KIDS cntr.
		$_KIDS++;

		#
		# return the pid!
		return $kid;
	}
	sub _kidstopped {
		# keep track
		my ($self,$kid,$err) = @_;
		$self->_dbmsg(DB_HIGH, "KIDSTOPPED: $kid");
		$self->_dbmsg(DB_HIGH, "KIDS: $_KIDS, (" . join(',',keys %_KIDS) . ")");
		return unless exists $_KIDS{$kid};
		if($self->get_accounting()) {
			$self->{_results}{$kid}{status} = 'terminated';
			$self->_kid_err($kid,$err) if defined $err;
		}
		$self->_dbmsg(DB_LOW,"CHILD: $kid ENDING");
		delete $_KIDS{$kid};
		return --$_KIDS;
	}
	sub kids {
		return wantarray() ? keys %_KIDS : $_KIDS;
	}
	sub kid_time {
		my ($self,$kid) = @_;
		return time unless exists $_KIDS{$kid};
		return $_KIDS{$kid};
	}
	sub _pid {
		return $$;
	}

	#
	# Child Accounting
	sub clear_results {
		my ($self) = @_;
		return unless $self->get_accounting();
		delete $self->{_results} if exists $self->{_results};
		$self->{_chi}->clear();
	}

	# Always return copies
	sub get_results { 
		my ($self,$key) = @_;
		return unless $self->get_accounting();
		if( !exists $self->{_results} ) {
			warn "something successfully did not happen\n";
			return;
		}
		if( defined $key ) {
			if( $self->{_results}{$key} ) {
				return { 
						%{ $self->{_results}{$key} },
						'return' => $self->{_chi}->get($key),
				};
			}
			else {
				warn "attempt to access undefined child '$key'\n";
				return;
			}
		}
		else {
			my %local_copy = %{ $self->{_results} };
			foreach my $kid ( keys %local_copy ) {
				$local_copy{$kid}->{return} = $self->{_chi}->get( $kid );
			}
			return \%local_copy;
		}
	}

	sub _kid_err {
		my ($self,$kid,$err) = @_;
		return unless $self->get_accounting();
		push @{ $self->{_results}{$kid}{error} }, $err;
	}
	sub _kid_exitcode {
		my ($self,$kid,$ec) = @_;
		return unless $self->get_accounting();
		$self->{_results}{$kid}{exitcode} = $ec;
	}
	sub _kid_return {
		my ($self,$kid,$return) = @_;
		return unless $self->get_accounting();
		$self->{_chi}->set( $kid, $return, 'never' );
	}
	sub _kid_signature {
		my ($self,$kid,@args) = @_;
		return unless $self->get_accounting() && $self->get_trackargs();
		$self->{_results}{$kid}{signature} = freeze \@args;
	}
	sub _kid_status {
		my ($self,$kid) = @_;
		return unless $self->get_accounting();
		foreach my $err ( @{ $self->{_results}{$kid}{error} } ) {
			$self->_dbmsg(DB_HIGH, "ChildError: $kid -> $err");
		}
	}

}

# Class Methods
sub DESTROY { }

sub new {
	# Constructor
	# Builds our initial Fork Object;
	my ($proto,@args) = @_;
	my $proto_is_obj = ref $proto;
	my $class = $proto_is_obj || $proto;
	my $self = bless {}, $class;
	# take care of capitalization:
	my %args=();
	while(@args) { 
		my $k = shift @args;
		my $v = shift @args;
		($k) = ($k =~ /^\s*_?(.*)$/);
		$args{lc($k)}=$v;
	}
	# now take care of our initialization
	foreach my $attr ($self->_attributes()) {
		my ($arg) = ($attr =~ /^_?(.*)/);
		# first see its in our argument list
		if(exists $args{$arg} && $self->_can('init',$attr)) {
			$self->{$attr} = $args{$arg};
		}
		# if not, check to see if we're copying an
		# object. Also, make sure we can copy it!
		elsif($proto_is_obj && $self->_can('copy', $attr)) {
			$self->{$attr} = $proto->{$attr};
		}
		# or, just use the default!
		else {
			$self->{$attr} = $self->_default($attr);
		}
	}
	# set the parent pid
	$self->set_parentpid($$);
	$self->_dbmsg(DB_HIGH,'FORK OBJECT CREATED');

	# Create the Cache
	$self->{_chi} = CHI->new( driver => 'File', root_dir => '/tmp', namespace => "PFC-$$" );
	return $self;
}


sub _overLoad {
	# this is a cheap linux only hack
	# I will be replacing this as soon as I have time
	my $CMDTOCHECK = '/usr/bin/uptime';
	my ($self) = shift;
	return FALSE unless $self->get_watchload();
	open(LOAD, "$CMDTOCHECK |") or return FALSE;
	local $/ = undef;
	chomp(local $_ = <LOAD>);
	close LOAD;
	if(/load average\:\s+(\d+\.\d+)/m) {
		my $current = $1;
		my $MAXLOAD = $self->get_maxload();
		if ($current >= $MAXLOAD) {
			$self->_dbmsg(DB_LOW,"OVERLOAD: Current: $current, Max: $MAXLOAD, RETURNING TRUE");
			return TRUE;
		}
		$self->_dbmsg(DB_LOW,"OVERLOAD: Current: $current, Max: $MAXLOAD, RETURNING FALSE");
		return FALSE;
	}
	$self->_dbmsg(DB_LOW,'OVERLOAD: ERROR READING LOAD AVERAGE, RETURNING FALSE');
	return FALSE;
}

sub _tooManyKids {
	# determine if there are too many forks
	my ($self) = @_;
	my $kids = $self->kids;
	my $MAXKIDS = $self->get_maxkids();
	my $MINKIDS = $self->get_minkids();

	#
	# Figure out how to do this check.
	if($self->get_watchload) {
		$self->_dbmsg(DB_MED,'TOOMANYKIDS - LOAD CHECKING');
		if($self->get_watchcount) {
			if(!$self->_overLoad && ($kids < $MAXKIDS)) {
				$self->_dbmsg(DB_LOW,"TOOMANYKIDS - MAX: $MAXKIDS, Kids: $kids, Return: FALSE");
				return FALSE;
			}
			$self->_dbmsg(DB_LOW,"TOOMANYKIDS - MAX: $MAXKIDS, Kids: $kids, Return: TRUE");
			return TRUE;
		}
		else {
			$self->_dbmsg(DB_MED,'TOOMANYKIDS - CHECKING LOAD, NOT CHECKING COUNT');
			if(!$self->_overLoad) {
				$self->_dbmsg(DB_LOW,"TOOMANYKIDS - Kids: $kids, UNCHECKED RETURNING FALSE");
				return FALSE;
			}
			if($self->kids < $self->get_minkids) {
				$self->_dbmsg(DB_LOW, "TOOMANYKIDS - OVERLOAD BUT REACHING MINIMUM KIDS!");
				return FALSE;
			}
			$self->_dbmsg(DB_LOW,"TOOMANYKIDS - Kids: $kids, UNCHECKED RETURNING TRUE");
			return TRUE;
		}
	} # end of watchload
	else {
		# not watching the load, stick to the
		# maxforks attribute
		$self->_dbmsg(DB_LOW,"TOOMANYKIDS - NOT CHECKING LOAD/MEM/CPU - Kids: $kids MAX: $MAXKIDS");
		if($kids >= $self->get_maxkids()) {
			$self->_dbmsg(DB_MED,'TOOMANYKIDS - RETURN TRUE');
			return TRUE;
		} else {
			$self->_dbmsg(DB_MED,'TOOMANYKIDS - RETURN FALSE');
			return FALSE;
		}
	}

	# if we get to this point something is wrong, return true
	return TRUE;
}

sub _check {
	#
	# this function is here to make sure we don't
	# freeze up eventually.  It should be all good.
	my $self = shift;
	$self->{_checked}++;
	return if $self->get_check_at > $self->get_checked;
	foreach my $pid ( $self->kids ) {
		my $alive = kill 0, $pid;
		if($alive) {
			my $start = $self->kid_time($pid);
			if(time - $start > $self->get_processtimeout()) {
				$self->_kid_err($pid,'process timeout');
				kill 15, $pid;
				$self->_kid_status($pid);
			}
		}
		else {
			$self->_dbmsg(DB_INFO, "Child ($pid) evaded the reaper. Caught by _check()\n");
			$self->_kidstopped($pid,'evaded the reaper');
		}
	}
	$self->{_checked} = 0;
}

sub run {
	# self and args go in, run the code ref or die if
	# the code ref isn't set
	my ($self,@args) = @_;

	#
	# Allow a user to pass a CODE Ref as the first argument,
	# default to legacy CODE Parameter.
	my $codeRef = shift @args;

	#
	# If it's not a code ref, put it back on args and get the code ref.
	if( ref $codeRef ne 'CODE' ) {
		unshift @args, $codeRef;
		$codeRef = $self->get_code();
	}

	my $typeCodeRef = ref $codeRef;	
	die "CANNOT RUN A $typeCodeRef IN run()\n" unless $typeCodeRef eq 'CODE';

	# return if our parent has died
	unless($self->_parentAlive()) {
		$self->_dbmsg(DB_MED, 'PARENT IS NOT ALIVE: ' . $self->get_parentpid);
		return;
	}

	# We might call _check();
	$self->_check();

	# wait for childern to die if we have too many
	if($self->get_method =~ /block/) {
		$self->waitforkids() if $self->_tooManyKids;
	}
	elsif($self->_tooManyKids) {
		$self->_kidstopped(wait);
	}
	else {
		#
		# Due limitations with the speed of process creation
		# on various modern OS's, its best to limit the maximum number
		# of processes created per second to 100
		select undef, undef, undef, 0.01;
	}

	# Protect us from zombies
	$SIG{CHLD} =  sub { $self->_REAPER };

	# fork();
	my $pid = fork();
	# check for errors
	die "*\n* FORK ERROR !!\n*\n" unless defined $pid;

	# if we're the parent return
	if($pid > 0) {
		return $self->_kidstarted($pid,@args);
	}

	# we're the child
	local $0 = ' Child of ' . $self->get_name;
	$self->_dbmsg(DB_HIGH,'Running Fork Code');
	my @trapSignals = qw(INT KILL TERM QUIT HUP ABRT);
	my @return = ();
	my $eval_error = undef;
	try {
		foreach my $sig (@trapSignals) {
			$SIG{$sig} = sub { $self->_REAPER; };
		}
		@return = $codeRef->(@args);
	} catch {
		$eval_error = shift;
		if($eval_error =~ /timeout/) {
			$self->_kid_err($$, 'alarmed out');
		}
	};
	$self->_kid_return( $$, scalar @return > 1 ? \@return : shift @return );

	my $CODE = $eval_error ? 1 : 0;
	exit $CODE;
}


sub waitforkids {
	# We'll just rely on our SIG{'CHLD'} handler to actually
	# disperse of the children, so all we have to do is wait
	# here.
	my $self = shift;
	# using select here because it doesn't interfere
	# with any signals in the program
	while( $self->kids ) {
		$self->_check;
		select undef, undef, undef, 1;
		$self->_REAPER;
	}
	return TRUE;
}
# Provided for legacy support
sub cleanup {
	my $self = shift;
	return $self->waitforkids;
}

sub _REAPER {
	# our SIGCHLD Handler
	# Code from the Perl Cookbook page 592
	# - heavily modified
	my $self = shift;

	my $pid = wait;

	if($pid > 0) {
		# a pid did something,
		$self->_dbmsg(DB_HIGH,"_REAPER found a child ($pid)!!!!!");
		my $rc = undef;
		if(!WIFEXITED($?)) {
			$rc=1;
			$self->_dbmsg(DB_INFO, "Child ($pid) exitted abnormally");
			$self->_kid_err($pid,'abnormal process termination');
		}
		elsif( WIFSIGNALED($?) ) {
			$self->_kid_err($pid,"Uncaught signal: " . WTERMSIG($?));
		}
		if(not defined $rc) {
			$rc = WEXITSTATUS($?);
		}
		$self->_kid_exitcode($pid,$rc);
		$self->_kidstopped($pid);
	}
	$SIG{CHLD} =  sub {$self->_REAPER};
}

sub _parentAlive {
	# check to see if the parent is still alive
	my $self = shift;
	return kill 0, $self->get_parentpid();
}

sub AUTOLOAD {
	# AUTOLOAD our get/set methods
	no strict 'refs';
	return if $AUTOLOAD =~ /DESTROY/;
	my ($self,$arg) = @_;

	# get routines
	if($AUTOLOAD =~ /get(_.*)/ && $self->_can('get', $1)) {
		my $attr = lc($1);
		*{$AUTOLOAD} = sub { return $_[0]->{$attr}; };
		return $self->{$attr};
	}

	# set routines
	if($AUTOLOAD =~ /set(_.*)/ && $self->_can('set', $1)){
		my $attr = lc($1);
		*{$AUTOLOAD} = sub {
					my ($self,$val) = @_;
					$self->{$attr} = $val;
					return $self->{$attr};
				};
		$self->{$attr} = $arg;
		return $self->{$attr};
	}

	warn "AUTOLOAD Could not find method $AUTOLOAD\n";
	return;
}

# DEBUG AND TESTING SUBS
sub _print_me {
	my $self = shift;
	my $class = ref $self;
	print "$class Object:\n";
	foreach my $attr ($self->_attributes) {
		my ($pa) = ($attr =~ /^_(.*)/);
		$pa = "\L\u$pa";
		my $val = ref $self->{$attr} || $self->{$attr};
		print "\t$pa: $val\n";
	}
	print "\n";
}

sub _dbmsg {
	# print debugging messages:
	my ($self,$pri,@MSGS) = @_;
	return unless $self->get_debug() >= $pri;
	foreach my $msg (@MSGS) {
		$msg =~ s/[\cM\r\n]+//g;
		my $date = scalar localtime;
		print STDERR "$date - $msg\n";
	}
	return TRUE;
}

 return 1;
1
__END__

=head1 NAME

Parallel::ForkControl - Finer grained control of processes on a Unix System

=head1 SYNOPSIS

  use Parallel::ForkControl;
  my $forker = new Parallel::ForkControl(
				WatchCount		=> 1,
				MaxKids			=> 50,
				MinKids			=> 5,
				WatchLoad		=> 1,
				MaxLoad			=> 8.00,
				Name			=> 'My Forker',
				Code			=> \&mysub
	);
  my @hosts = qw/host1 host2 host3 host5 host5/;

  my $altSub = sub { my $t = shift; ... };

  foreach my $host (@hosts) {
	if( $host eq 'alternateHost' ) {
		$forker->run( $altSub, $host );
	}
	else {
		$forker->run($host);
	}
  }

  $forker->waitforkids();  # wait for all children to finish;
  
  my $results = $forker->get_results();  # Get the Return Codes from Children
	# $results = {
	# 		'29786' => {	# Kid PID
	#				'status' => 'string',
	#				'exitcode' => int,
	#				'return' => $scalarCopyofReturnValue,
	#				'signature' => $scalarFreezeOfArguments,
	#		}, ...
  $forker->clear_results();              # Reset the Results Tracker
  .....

=head1 DESCRIPTION

Parallel::ForkControl introduces a new and simple way to deal with fork()ing.
The 'Code' parameter will be run everytime the run() method is called on the
fork object.  Any parameters passed to the run() method will be passed to the
subroutine ref defined as the 'Code' arg.  This allows a developer to spend
less time worrying about the underlying fork() system, and just write code.

=head1 METHODS

=over 4

=item B<new([ Option =E<gt> Value ... ])>

Constructor.  Creates a Parallel::ForkControl object for using.  Ideally,
all options should be set here and not changed, though the accessors and
mutators allow such behavior, even while the B<run()> method is being executed.

=over 4

=item Options

=over 4

=item Name

Process Name that will show up in a 'ps', mostly cosmetic, but serves as an
easy way to distinguish children and parent in a ps.

=item ProcessTimeOut

The max time any given process is allowed to run before its interrupted.
B<Default :>120 seconds

=item WatchCount

Enforce count (MaxKids) restraints on new processes.
B<Default :> 1

=item WatchLoad

Enforce load based (MaxLoad) restraints on process creation. NOTE: This MUST be
a true value to enable throttling based on Load Averages.
B<Default :> 0

=item WatchMem ***

(unimplemented)

=item WatchCPU ***

(unimplemented)

=item Method

May be 'block' or 'cycle'.  Block will fork off MaxKids and wait for all of them
to die, then fork off MaxKids more processes.  Cycle will continually replace
processes as the restraints allow.  Cycle is almost ALWAYS the preferred method.
B<Default :>Cycle
B

=item MaxKids

The maximum number of children that may be running at any given time.
B<Default :> 5

=item MinKids

The minimum number of kids to keep running regardless of load/memory/CPU
throttling.
B<Default :> 1

=item MaxLoad

The maximum one minute average load.  Make sure to set WatchLoad.
B<Default :> 4.50 (off by default)

=item MaxMem  *** 

(unimplemented)

=item MaxCPU ***

(unimplemented)

=item Code

This should be a subroutine reference.  If you intend on passing arguments to this
subroutine arguments it is imperative that you B<NOT> include () in the reference.
All code inside the subroutine will be run in the child process.  The module provides
all the necessary checks and safety nets, so your subroutine may just "return".  It is
not necessary, nor is it good practice to have exit()s in this subroutine as eventually,
return codes are stored and made available to the parent process after completion.
Examples:

	my $code = sub {
			# do something useful
			my $t = shift;
			return $t;
	};

	my $forker = new Parallel::ForkControl(
				Name => 'me',
				MaxKids => 10,
				Code => $code
				# or
				#Code => \&mysub
	)

	sub mysub {
		my $t = shift;
		return $t;
	}

Alternatively, you may pass the sub reference as the first argument of the B<run()> method.

=item Accounting

By default this is turned off.  If you would like to keep track of the exit codes, sub routine
return values, and current status of the children forked by the B<run()> routine, enable this
option:

	Accounting	=> 1

=item TrackArgs

By setting this to a true value, the fork controller will keep track of the arguments
passed to each of the children.  Using this you can see what arguments yielded which results.
This argument truly only makes sense if you've enabled the Accounting option.

=item Check_At

This determines between how many child processes the module does some checking
to verify the validity of its internal process table.  It shouldn't be necessary 
to modify this value, but given it is a little low, someone only utilizing this
module for a larger number of data sets might want to check things at larger
intervals.
B<Default :> 2

=item Debug

A number 0-4. The higher the number, the more debugging information you'll see.
0 means nothing.
B<Default :> 0

=back

=back

=item B<run([ @ARGS ])>

This method calls the subroutine passed as the I<Code> option.  This method
handles process throttling, creation, monitoring, and reaping.  The subroutine
in the I<Code> option run in the child process and all control is returned to the
parent object as soon as the child is successfully created. B<run()> will block
until it is allowed to create a process or process creation fails completely.
B<run()> returns the PID of the child on success, or undef on failure.  B<NOTE:> This
is not the return code of your subroutine.  I will eventually provide mapping
to argument sets passed to run() with success/failure options and (idea) a
"Report" option to enable some form of reporting based on that API.

=item B<waitforkids()>

This method blocks until all children have finished processing.

=item B<cleanup()>

Alias for waitforkids(), provided for legacy applications

=item B<get_results( [ $pid ])>

This method returns a hash reference of the arguments and return codes of the children:

	$hashref = {
		'2975' =>  {	# PID of Child
			exitcode => 0,
			status => 'done',
			signature => $FrozenScalar,
			return => $ReferenceToReturnValue
		},
		....
	};

The $pid is optional, but if specified, will return:

	$hashref = {
		exitcode => 0,
		status => 'done',
		signature => $FrozenScalar,
		return => $ReferenceToReturnValue
	};

Requires Accounting => 1 and optionally TrackArgs => 1



=item B<clear_results()>

This method clears the results hash.

=item B<kids()>

This method returns the PIDs of all the children still alive in array context.
In scalar context it returns the number of children still running.

=item B<kid_time( $PID )>

This method returns the start time in epoch seconds that the PID began.

=back

=head1 EXPORT

None by default.

=head1 KNOWN ISSUES

=over 4

=item 01/08/2004 - brad@divisionbyzero.net

For some reason, I'm having to throttle process creation, as a slew of  processes
starting and ending at the same time seems to be causing problems on my machine.
I've adjust the Check_At down to 2 which seems to catch any processes whose SIG{CHLD}
gets lost in the mess of spawning.  I'm looking into a more permanent, professional
solution.

=back

=head1 SEE ALSO

perldoc -f fork, search CPAN for Parallel::ForkManager

=head1 AUTHOR

Brad Lhotsky E<lt>brad@divisionbyzero.netE<gt>

=head1 CONTRIBUTIONS BY

Mark Thomas E<lt>mark@ackers.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Brad Lhotsky

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 
 
=cut
