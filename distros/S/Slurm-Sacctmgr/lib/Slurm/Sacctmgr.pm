#!/usr/local/bin/perl
#
#Perl wrappers for Slurm sacctmgr

package Slurm::Sacctmgr;
use strict;
use warnings;
use base qw(Class::Accessor);
use Carp qw(carp croak);

use version; our $VERSION = qw(1.1.0);


#-------------------------------------------------------------------
#	Globals
#-------------------------------------------------------------------

#By default, use the sacctmgr found in your path
my $DEFAULT_SACCTMGR_CMD='sacctmgr';
#If you wish to default to something else, you can either modify the
#class method default_sacctmgr_path_version, and/or uncomment 
#and change the line below. 
#$DEFAULT_SACCTMGR_CMD='/usr/local/slurm/bin/sacctmgr';
#It is also recommended that you set the $DEFAULT_SACCTMGR_VERSION to the
#Slurm version number associated with that specified sacctmgr command.
#Failure to do so might result in the package needing to issue extra 
#sacctmgr commands to determine what version of sacctmgr being run, which is inefficient
my $DEFAULT_SACCTMGR_VERSION;
#Uncomment and modify this if the Slurm version for the sacctmgr command listed
#in $DEFAULT_SACCTMGR_CMD is known
#$DEFAULT_SACCTMGR_VERSION='15.08.2';
#The default version of default_sacctmgr_path_version just returns these
#two values; modified versions might or might not use these values.

#This is intended for regression tests only
my $_last_raw_output;
sub _sacctmgr_last_raw_output($)
{       return $_last_raw_output;
}

my @SACCTMGR_CMD_CAPABILITIES_LIST =
(	'trackable_resources', #Supports TRES, at least at basic level
);

my %SACCTMGR_CMD_CAPABILITIES_HASH = map { $_ => undef } @SACCTMGR_CMD_CAPABILITIES_LIST;


#-------------------------------------------------------------------
#	Accessors
#-------------------------------------------------------------------

my @rw_accessors = qw(
	dryrun
	verbose
);

my @ro_accessors = qw(
	sacctmgr
	slurm_version
);
#	_sacctmgr_cmd_capabilities
#	_cached_sacctmgr_cmd_capabilities

__PACKAGE__->mk_accessors(@rw_accessors);
__PACKAGE__->mk_ro_accessors(@ro_accessors);


my @required_parms = qw(
	sacctmgr
);

#-------	Special accessors/mutators

sub slurm_version($;$)
#Gets version of slurm/sacctmgr cmd
#Preferably our cached version, but (unless $cachedonly flag is set)
#will call sacctmgr to get it if needed
#If unknown and $cachedonly set, will return undef.
{	my $self = shift;
	my $cachedonly = shift;

	my $svers = $self->get('slurm_version');
	return $svers if $svers;

	return if $cachedonly;

	return $self->_determine_slurm_version; #This sets 'slurm_version' data member
}

#-------------------------------------------------------------------
#	Constructors, etc
#-------------------------------------------------------------------

sub new($;@)
{	my $class = shift;
	my @args = @_;

	my $obj = {};
	bless $obj, $class;

	$obj->_parse_args(@args);
	$obj->_set_defaults;
	$obj->_init;

	return $obj;
}

sub _parse_args($@)
{	my $obj = shift;
	my %args = @_;

	my ($arg, $meth, $val);
	RWARG: foreach $arg (@rw_accessors)
	{	next RWARG unless exists $args{$arg};
		$val = delete $args{$arg};
		next RWARG unless defined $val;
		$meth = $arg;
		$obj->$meth($val);
	}

	ROARG: foreach $arg (@ro_accessors)
	{	next ROARG unless exists $args{$arg};
		$val = delete $args{$arg};
		next ROARG unless defined $val;

		if ( $arg eq 'sacctmgr' || $arg eq 'slurm_version' )
		{	#This gets handled specially
			my ($tmppath, $tmpver);
			if ( $arg eq 'sacctmgr' )
			{	$tmppath = $val;
				$tmpver = delete $args{'slurm_version'};
			} elsif ( $arg eq 'slurm_version' )
			{	$tmpver = $val;
				$tmppath = delete $args{'sacctmgr'};
			} else
			{	die "Should not reach here at ";
			}
			$obj->_set_sacctmgr_path($tmppath, $tmpver);
			next ROARG;
		}

		$meth = $arg;
		$obj->set($meth,$val);
	}


	#Warn about unknown arguments
	if ( scalar(keys %args) )
	{	my $tmp = join ", ", (keys %args);
		croak "Unrecognized arguments [ $tmp ] to constructor at ";
	};
}

sub _set_defaults($)
{	my $obj = shift;

	my ($tmp);
	$tmp = $obj->sacctmgr;
	unless ( $tmp )
	{	my @tmp = $obj->default_sacctmgr_path_version;
		$obj->_set_sacctmgr_path(@tmp);
	}

	return;
}

sub _init($)
{	my $obj = shift;

	my ($fld, $meth, $val);
	foreach $fld (@required_parms)
	{	$meth = $fld;
		$val = $obj->$meth;
		unless ( defined $val )
		{	croak "Missing required argument $fld";
		}
	}

}

#-------------------------------------------------------------------
#	Sacctmgr/slurm versioning stuff
#-------------------------------------------------------------------

sub default_sacctmgr_path_version($)
#This returns the default path to sacctmgr, and the default Slurm
#version, for use when defaulting sacctmgr value during construction
#of an instance.  The path and version are returned as elements
#of a 2 value list.
#
#This version just returns the lexicals
#	$DEFAULT_SACCTMGR_CMD and
#	$DEFAULT_SACCTMGR_VERSION
#defined at the top of this file.  For most cases, it is easiest to
#just change those variables.  This routine is provided as a hook
#in case system admins need to do something more complicated when
#defaulting these.
{	my $class = shift;

	return ( $DEFAULT_SACCTMGR_CMD, 
		$DEFAULT_SACCTMGR_VERSION );
}

sub sacctmgr_capabilities_by_version($$)
#Return the appropriate sacctmgr_cmd_capabilities hash for a given
#Slurm version number.  This is our "guess" of what various versions
#can/cannot do.
#Returns hash ref.
#This is a class method
{	my $class = shift;
	my $slurm_version = shift;
	my $me = __PACKAGE__ . '::sacctmgr_capabilities_by_version';

	return unless $slurm_version;
	#Strip leading/trailing whitespace from version
	$slurm_version=~ s/^\s*//; $slurm_version =~ s/\s*$//;

	my @vcomps = split /\./, $slurm_version;
	my $slurm_major = $vcomps[0];

	#REturn unknown caps if bad version given
	return unless $slurm_major =~ /^\d+$/;

	#Guess at capabilities
	if ( $slurm_major < 15 )
	{	#Looks like an older, pre-TRES version of slurm
		return
			{	trackable_resources => 0,
			};
	} else
	{	#Looks like a newer version of Slurm, with TRES support
		return
			{	trackable_resources => 1,
			};
	}
}

sub _set_sacctmgr_path($$;$)
#Sets sacctmgr path and version, and the capabilities hash
{	my $obj = shift;
	my $newpath = shift;
	my $newversion = shift;
	#This should only be called via new???
	my $me = __PACKAGE__ . '::new';

	unless ( $newpath )
	{	$newpath = $DEFAULT_SACCTMGR_CMD;
		unless ( $newversion )
		{	#Only default if defaulting path as well
			$newversion = $DEFAULT_SACCTMGR_VERSION;
		}
	}

	$obj->set('sacctmgr', $newpath); #newpath should always be set
	if ( $newversion )
	{	$obj->set('slurm_version', $newversion);
	} else
	{	#No version given, so set version to undef
		$obj->set('slurm_version', undef);
	}
	#Always clear capabilities_hash
	$obj->set('_capabilities_hash', undef);
}

sub _determine_slurm_version($)
#Calls 'sacctmgr --version' to get our slurm version
#Sets slurm_version data method and returns version
{	my $obj = shift;
	my $me = __PACKAGE__ . '::_determine_slurm_version';

	my @args = ( '--version' );
	
	my ( $err, @out) = $obj->_run_generic_sacctmgr_cmd_always(@args);

	my $errstr;
	if ( $err )
	{	$errstr = "Exit code: $err";
		my $output = join "\n", @out;
		$errstr .= "\n$output" if $output;
		croak "$me: Error running sacctmgr --version to get slurm version\n$errstr\nat ";
	}

	my @vlines = grep /^slurm/, @out;
	unless ( scalar(@vlines) )
	{	$errstr = join "\n", @out;
		croak "$me: Unable to get slurm version from 'sacctmgr --version'\n" .
			"Output was\n$errstr\nat ";
	}

	my $version = $vlines[0];
	$version =~ s/^slurm\s*//;
	$obj->set('slurm_version', $version);
	return $version;
}
	
sub sacctmgr_cmd_supports($$;$)
#This checks if the current sshare command supports the named capability.
#If $cachedonly is set, will only used cached information (i.e. will
#NOT invoke an sacctmgr call to find out the version)
#Returns 1 if supports, 0 if doesn't, and undef if unknown (should
#only occur if $cachedonly is set)
{	my $self = shift;
	my $capname = shift;
	my $cachedonly = shift;
	my $me = __PACKAGE__ . '::sacctmgr_cmd_supports';

	unless ( exists $SACCTMGR_CMD_CAPABILITIES_HASH{$capname} )
	{	warn "$me: Unrecognized capability named '$capname' at ";
		return 0; #Unrecognized => unsupported
	}

	my $capshash = $self->get('_capabilities_hash');
	unless ( $capshash && ref($capshash) eq 'HASH' )
	{	#No capabilities hash, do we have a slurm_version
		my $svers = $self->slurm_version($cachedonly);

		#svers should only be undef if cachedonly and need to look up
		return unless defined $svers;

		$capshash = $self->sacctmgr_capabilities_by_version($svers);
		unless ( $capshash && ref($capshash) )
		{	croak "$me: Unable to get capabilities hash for Slurm version $svers at ";
		}
		$self->set('_capabilities_hash', $capshash);
	}
	
	my $tmp = $capshash->{$capname};
	return $tmp if defined $tmp;
	warn "$me: Capability $capname not in capshash at ";
	return;
}
	
#
#-------------------------------------------------------------------
#	Basic sacctmgr commands
#-------------------------------------------------------------------

sub _noshell_backticks($$@)
#Calls an external command using pipes and forks so no shell gets invoked
#Returns ($err, @out) where $err is the error is the exit status of
#the command, and @out is the list of output returned, line by line.
#If $mode is 0, only STDOUT is returned in @out, 
#If $mode is non-zero, STDERR is dupped onto STDOUT and also returned.
{	my $obj = shift;
	my $mode = shift;
	my @cmd = @_;

	#Exit code for errors in exec in child
	my $chd_excode=254;

	my ($err, @out, $PIPE, $res);

	if ( $res = open($PIPE, "-|" )  )
	{	#Parent
		if ( ! defined $res )
		{	my $tmp = join ' ', @cmd;
			die "Pipe to '$tmp' failed: $!";
		}
		@out = <$PIPE>;
		$res = close $PIPE;
		$err = $?;
		if ( $err && ( ($err >> 8)  == $chd_excode ) )
		{	#We (probably?) got an exception running exec in child process
			#Re raise the exception
			my $exc = join '', @out;
			die $exc;
		}
		return ($err, @out);
	} else
	{	#Child
		#Duplicate stderr onto stdout if so requested
		if ( $mode )
		{	unless ( open(STDERR, '>&STDOUT') )
			{	print "Cannot dup stderr to stdout in child";
				die "Cannot dup stderr to stdout in child";
			}
		}
		#Wrap exec in an eval, and exit on error, not die.
		#Otherwise, if _noshell_backticks is put in an eval block, an exception raised
		#by exec (e.g. taint issues) will result in both child and parent continuing from
		#the user's eval block.  See e.g. http://www.perlmonks.org/?node_id=166538
		eval { exec { $cmd[0] } @cmd; #Not subject to shell escapes
		};
		#We only reach here if exec raised an exception
		warn "$@" if $@;
		exit $chd_excode;
	}
}

sub _run_generic_sacctmgr_cmd_always($@)
#Run a generic sacctmgr cmd, returning results
#Does NOT honors dryrun.
#This should only be called directly for commands which do NOT
#modify the database
{	my $obj = shift;
	my @args = @_;

	my $cmd = $obj->sacctmgr;
	my $mode = 1;
	if ( $obj->verbose )
	{	#Verbose mode:
		#Output command before executing it
		my @tmp = ($obj->sacctmgr, @args);
		my $tmpsp = '';
		my $tmpcmd = '';
		#Quote any args with whitespace so verbose output looks better
		foreach (@tmp)
		{	my $tmp = $_;
			if ( $tmp =~ /\s/ )
			{	#Quote it if it has whitespace
				$tmp = "'$tmp'";
			}
			$tmpcmd .= $tmpsp . $tmp;
			$tmpsp = " ";
		}
		#my $tmpcmd = join ' ', @tmp;
		print STDERR "[VERBOSE] $tmpcmd\n";
	}
	my ($err, @out ) = $obj->_noshell_backticks($mode, $cmd, @args);
	$_last_raw_output = [ @out ];
	return ($err, @out);
}

sub run_generic_sacctmgr_cmd($@)
#Run a generic sacctmgr cmd, returning results
#Honors dryrun
#Returns list ref of output, line by line on success.
#Returns non-ref error message on error.
{	my $obj = shift;
	my @args = @_;

	if ( $obj->dryrun )
	{	unshift @args, $obj->sacctmgr;
		#my $cmd = join ' ', @args;
		#Quote any args with whitespace so debug output looks better
		my $cmd = '';
		my $tmpsp = '';
		foreach (@args)
		{	my $tmp = $_;
			if ( $tmp =~ /\s/ )
			{	#quote it if has whitespace
				$tmp = "'$tmp'";
			}
			$cmd .= $tmpsp . $tmp;
			$tmpsp = ' ';
		}
		print STDERR "[DRYRUN] $cmd\n";
		return [];
	}
	my ($err, @out) = $obj->_run_generic_sacctmgr_cmd_always(@args);
	if ( $err )
	{	my $errstr = "Exit code: $err";
		my $output = join "\n", @out;
		$errstr .= "\n$output" if $output;
		return $errstr;
	}
	#return $err if $err;
	return [ @out ];
	
}

sub run_generic_safe_sacctmgr_cmd($@)
#Run a "safe" generic sacctmgr cmd, returning results
#which should not modify accounting info.
#Does NOT honor dryrun, as command is "safe"
#We append a --readonly to command to make sure it IS safe
#
#Returns list ref of output, line by line on success.
#Returns non-ref error message on error.
{	my $obj = shift;
	my @args = @_;

	push @args, '--readonly';
	my ($err, @out) = $obj->_run_generic_sacctmgr_cmd_always(@args);
	if ( $err )
	{	my $errstr = "Exit code: $err";
		my $output = join "\n", @out;
		$errstr .= "\n$output" if $output;
		return $errstr;
	}
	#return $err if $err;
	return [ @out ];
}

sub run_generic_sacctmgr_list_command($@)
#Runs a sacctmgr list command, returns output as a list ref of list refs
#of the fields in order. 
#(Tried using hash refs, but those get abbreviated.  Ugh!)
#'list' should be included in the command spec
#
#On error, returns non-ref error message/error code
#
#Appends --parsable2 and --noheader to the command
#Does NOT honor dryrun (as --readonly)
{	my $obj = shift;
	my @cmd = @_;

	push @cmd, '--parsable2', '--noheader';
	my $lines = $obj->run_generic_safe_sacctmgr_cmd(@cmd);

	return $lines unless $lines && ref($lines) eq 'ARRAY';

	my $results = [];
	foreach my $line (@$lines)
	{	chomp $line;
		my @values = split /\|/, $line;
		push @$results, \@values;
	}

	return $results;
}


1;
__END__

=head1 NAME

Slurm::Sacctmgr - Perl wrapper to sacctmgr command

=head1 SYNOPSIS

  use Slurm::Sacctmgr;

  my $sacctmgr = Slurm::Sacctmgr->new( sacctmgr=>'path to sacctmgr command');

  my $sacctmgr->dryrun(1);
  my $sacctmgr->verbose(1);

  my $results;

  #This one won't run in dryrun mode
  $results = $sacctmgr->run_generic_sacctmgr_cmd('create', 
		'cluster', 'mycluster');
  if ( $results && ref($results) eq 'ARRAY' )
  {	print "Results of create cluster are: ",
		(join "\n", @$results), "\n\n";
  } else
  {	print STDERR "Error running create cluster: $results\n";
  }

  #This one will run in dryrun mode.  --readonly is silently appended, so
  #is "safe" to run in dryrun mode
  $sacctmgr->run_generic_safe_sacctmgr_cmd('list', 'cluster');
  if ( $results && ref($results) eq 'ARRAY' )
  {	print "Results of list cluster (human readable) are: ",
		(join "\n", @$results), "\n\n";
  } else
  {	print STDERR "Error running list cluster: $results\n";
  }

  #This also runs in dryrun mode.  --readonly, --parsable2, and --noheader
  #are added to the command silently
  $sacctmgr->run_generic_sacctmgr_list_command('list','cluster');
  if ( $results && ref($results) eq 'ARRAY' )
  {	print "Results of list cluster (machine readable) are: ",
		(join "\n", @$results), "\n\n";
  } else
  {	print STDERR "Error running list cluster: $results\n";
  }

  ...


=head1 DESCRIPTION

These provide wrappers to the Slurm B<sacctmgr> command.   Basically, it
allows access to the Slurm B<sacctmgr> command from within Perl.   Forks and
pipes are used so no new shell is spawned (and shell expansion is not handled)
for increased safety.   Although there might be advantages to using B<Slurmdb> and 
accessing the database directly,  this wrapper approach has some advantages as well, one
of which is that provides greater correlation with existing manual procedures using
these commands, thereby easing the automation of existing processes.

The interface to this package is object orientated, mainly to reduce namespace pollution.

=head2 CONSTRUCTOR and DATA members

The constructor B<new> takes key => value pairs to set the data members, 
which are:

=over 4

=item B<sacctmgr>:

The path to the Slurm B<sacctmgr> command.  Can only be set at time of
construction.  Normally defaults to just "sacctmgr", i.e. will look for it in your
path.  Systems staff can set a different default by changing the value of the 
constant B<$DEFAULT_SACCTMGR_CMD> at the top of this file.  It is recommended
that they also set B<$DEFAULT_SACCTMGR_VERSION> at the same time if specifying
the B<sacctmgr> command of a specific Slurm version.

=item B<dryrun>:

If this is set, the module works in B<dryrun> mode.  See below for details.
Default is false.

=item B<verbose>:

If this is set, the module works in B<verbose> mode.  Basically, the various
B<sacctmgr> commands will be printed out just before they are executed.  
Commands which do not actually run due to B<dryrun> mode will not be printed
out due to B<verbose> mode, but will get printed out due to being B<dryrun>
mode (i.e. they will get printed once, and only once).
Default is false.

=back

Accessors exist for all of the above.
The B<sacctmgr> field is read-only, and can only be set at time of
construction.  B<dryrun> and B<verbose> are read-write, and can be set
at any time by providing a defined boolean value as an explicit argument
to the accessor.  Usual perl boolean semantics apply, except that you
cannot provide an undef value to the accessor to unset the fields (as that
would be interpretted as a read accessor, not a mutator).

The main methods are the methods to actually run B<sacctmgr> commands.  These
use forking and pipes to avoid invoking an Unix shell for additional safety
(i.e., shell expansions will not work).  The intent is to be able to 
programatically issue B<sacctmgr> commands and get the results.  The functions
take the B<sacctmgr> command, with each word as a separate argument to
the function.  The actual B<sacctmgr> command should NOT be given, as we will
use the one provided to the constructor.

=head3 Default value for B<sacctmgr> path and Slurm version

If the user does not set the path to B<sacctmgr> (and perhaps the version
of Slurm) when constructing an instance, these will be defaulted.  It is
recommended that system administrators modify B<Sacctmgr.pm> after installation
to set the default path to the appropriate value for the cluster, and to
also set the Slurm version.  However, if the system administrator did not
modify the file, the default default is to use whatever B<sacctmgr> command
is found in the caller's path, and the Slurm version will be determined, if needed,
by probing the B<sacctmgr> command (which involves an extra fork and exec).

For system administrators looking to default these values, there are several
ways to proceed.  The method B<_set_defaults> handles setting all default
values for the instance (although currently only B<sacctmgr> is defaulted).
If B<sacctmgr> is in need of being defaulted, it calls the method
B<default_sacctmgr_path_version> which returns the path and possibly version
as a list.  The default version of B<default_sacctmgr_path_version> simply
returns the lexical variables B<$DEFAULT_SACCTMGR_CMD> and 
B<$DEFAULT_SACCTMGR_VERSION> which are defined at the top of the B<Sacctmgr.pm>
file.  If not modified, these should be just 'sacctmgr' and undef, respectively,
which results in whatever B<sacctmgr> in the invoker's path being executing,
and the package not knowing what version of Slurm is being used (which means
if the version is needed, the package will attempt to query sacctmgr to discover
the version).

In most cases, it is recommended that the system administrator just change the
values of the lexical B<$DEFAULT_SACCTMGR_CMD> and B<$DEFAULT_SACCTMGR_VERSION> 
at the top of the file to the full path to the sacctmgr command and the version 
of Slurm being used on the cluster.  This will avoid issues if there are issues
with the caller's path, and prevent extra invocations of sacctmgr to determine
the Slurm version.

If the situation is too complicated for the above, the B<default_sacctmgr_path_version>
provides a hook wherein the system administrator can use whatever algorithm desired
to default these values.  E.g., if you have two clusters sharing the same perl
library but running different versions of Slurm.


=head2 RUN-type commands

The "run" commands are:

=over 4

=item B<$sacctmgr->run_generic_sacctmgr_cmd(@sacctmgr_args)>

This runs B<sacctmgr> with the arguments given in B<@sacctmgr_args>,
UNLESS we are in dryrun mode.  In dryrun mode, the command is only printed
out (with a B<[DRYRUN]> prefix).

=item B<$sacctmgr->run_generic_safe_sacctmgr_cmd(@sacctmgr_args)>

This behaves much like B<run_generic_sacctmgr_cmd>, except that it will
always run, even in dryrun mode.  Also, we prepend the B<--readonly> argument
to the argument list.  It is intended for commands which do B<NOT> update
the database (and we use the B<--readonly> flag to enforce that).  Because
the command does not update the database, it can safely run in B<dryrun>
mode.  This is useful for B<sacctmgr> commands that your script runs to
gather information.

=item B<$sacctmgr->run_generic_sacctmgr_list_command(@sacctmgr_args)>

This behaves much like B<run_generic_safe_sacctmgr_cmd>, except that it also
adds the flags B<-parseable2> and B<-noheader> to the argument list.  This
is intended to wrap commands to collect information using B<sacctmgr> and
present to your script in a machine-usable fashion.  Note that you still need
to give the full argument list to B<sacctmgr>, i.e. the 'list' or 'show' 
command is not assumed.

=back

=head2 RETURN VALUES AND ERROR HANDLING

For serious (fatal) errors, such as:

=over 4

=item in the constructor, when required parameters are missing or illegal parameters given.

=item in the "run" commands, due to errors duplicating stderr onto stdout or errors forking the sacctmgr command.

=back

For non-fatal errors, the return value will be a non-reference scalar string containing
the error text.  E.g., if the sacctmgr command returns a non-zero exit code, the "run" methods
will return a string starting with "Error code: " followed by the error code and
any error message received from sacctmgr.

On success, the return value for the "run" methods will be an array reference, containing
the output of the sacctmgr command (each element of the array being one line of output).

=head2 DRYRUN MODE

For testing of scripts, it is nice to have a B<dryrun> mode in which the
user can see what commands would be executed, but without the commands actually
executing.  To do this, have a B<dryrun> flag in your code, and set
the B<dryrun> data method of your B<Slurm::Sacctmgr> instance.  This can
be done either at time of construction or afterwards with the 
B<dryrun> mutator.  B<NOTE:> Although standard Perl boolean semantics are
honored, you cannot use the B<dryrun> mutator to unset the data method; as

  $sacctmgr->dryrun(undef);

will be considered a request to get the value of B<dryrun>, not to set it
to undef (false).  Use instead something like:

  $sacctmgr->dryrun(0);

Actually, only commands which modify the database should not run; getting
a list of all clusters, etc. is harmless and you normally want those to
run (otherwise your code won't get far enough to reach the parts that really
need debugging).  So we provide a B<run_generic_sacctmgr_cmd> method which
honors the B<dryrun> setting, and will only actually execute the command
when B<dryrun> is false, as well as B<run_generic_safe_sacctmgr_cmd>, which
does B<NOT> honor the B<dryrun> setting, and always runs.

The latter is intended for commands which do B<not> modify the database, and
so are safe to run even in a debugging session.  To ensure the DB does not
get modified, it adds the B<--readonly> flag to B<sacctmgr>.

The B<run_generic_sacctmgr_list_command> is a variant of the 
B<run_generic_safe_sacctmgr_cmd>, intended for the somewhat common operation
of requesting information from B<sacctmgr>.  It adds flags to make the
output more machine readable.

=head2 VERBOSE MODE

If the B<verbose> data method is set, either at construction time or via
the B<verbose> mutator afterwards, the B<sacctmgr> commands will be printed
out to STDERR before being executed.  This is again useful for debugging.

B<Note:> If both B<verbose> and B<dryrun> modes are set, only the "safe"
commands are printed out due to the instance being in B<verbose> mode.
The "unsafe" commands get intercepted by B<dryrun> mode first, before 
B<verbose> mode can print them out.  But the B<dryrun> mode prints them out
anyway, so the result is the command gets printed out exactly once, which is
what you probably want anyway.

=head2 EXPORT

None.  OO interface only.

=head2 EXAMPLES

Generally, you will instantiate an instance of of this class and then pass it
to one of the B<Slurm::Sacctmgr::*> package class methods to do the actual work.
The following little example script will print for each Slurm account the
GrpCPUMin limits by cluster/partition, as well as list the users who can access
the account:

  #!/usr/bin/perl
  use Slurm::Sacctmgr;
  use Slurm::Sacctmgr::Account;
  use Slurm::Sacctmgr::Association;
  
  #You can specify a full path to sacctmgr below if wanted, defaults to just 'sacctmgr'
  my $sa = Slurm::Sacctmgr->new;

  #Get a list of all accounts sacctmgr knows of
  my $accounts = Slurm::Sacctmgr::Account->sacctmgr_list($sa);

  foreach my $acct (@$accounts)
  {	my $account = $acct->account; #The name of the account
  	my ($assoc, $cluster, $partition);
  
  	# Get all associations in sacctmgr related to this account.
  	# Arguments after the Slurm::Sacctmgr instance are passed to the sacctmgr list assoc command
	my $assocs = Slurm::Sacctmgr::Association->sacctmgr_list($sa, account=>$account);
  
  	#Separate the associations with and without user members
  	my @acctassocs = grep { ! defined $_->user } @$assocs;
  	my @userassocs = grep { defined $_->user } @$assocs;
  
  	print "--------------------------------------\n";
  	print "Account $account:\n";
  
  	#Print GrpCPUMin limits on any associations w/out users
  	printf "\t%10s %10s %10s\n", 'Cluster', 'Partition', 'GrpCPUMins' if ( @acctassocs );
	foreach $assoc (@acctassocs)
  	{	$cluster = $assoc->cluster || '<any>';
  		$partition = $assoc->partition || '<any>';
  		my $cpumin = $assoc->grpcpumins || '<unlimited>';
  		printf "\t%10s %10s %10s\n", $cluster, $partition, $cpumin;
  	}
  
  	#List users with access to this Account
  	printf "\t%10s %10s %10s\n", 'User', 'Cluster', 'Partition' if ( @userassocs );
  	foreach $assoc (@userassocs)
  	{	$cluster = $assoc->cluster || '<any>';
  		$partition = $assoc->partition || '<any>';
  		my $user = $assoc->user || '<any>';
  		printf "\t%10s %10s %10s\n", $user, $cluster, $partition;
  	}
  }

=head1 SEE ALSO

Slurmdb

Slurm::Sacctmgr::Account

Slurm::Sacctmgr::Associaton

Slurm::Sacctmgr::Cluster

Slurm::Sacctmgr::EntityBase

Slurm::Sacctmgr::Event

Slurm::Sacctmgr::Qos

Slurm::Sacctmgr::Transaction

Slurm::Sacctmgr::User

Slurm::Sacctmgr::WCKey

=head1 AUTHOR

Tom Payerle, payerle@umd.edu

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2016 by the University of Maryland.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

