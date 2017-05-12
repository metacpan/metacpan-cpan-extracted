#!/usr/local/bin/perl
#
#Perl wrappers for Slurm sshare cmd

package Slurm::Sshare;
use strict;
use warnings;
use base qw(Class::Accessor);
use Carp qw(carp croak);
use UNIVERSAL;

use version; our $VERSION = qw(1.2.2);

#-------------------------------------------------------------------
#	Globals
#-------------------------------------------------------------------

my $VERBOSE;

#By default, use the sshare command found in your PATH
my $SSHARE_CMD = 'sshare'; 
#IF you wish to default to something else, uncomment and change line below
#$SSHARE_CMD = '/usr/local/bin/sshare'; 
#It is also recommended that you set $SSHARE_CMD_CAPABILITIES to a hash ref
#showing the capabilities of the sshare command you designated above --- failure
#to do so might result in the package needing to test the command capabilities which
#is inefficient.  The value of $SSHARE_CMD_CAPABILITIES is a hash ref with keys
#based on the name of the capability, and a value of 1 (true) if the capability is
#supported, or 0 (false) otherwise.  You can use standard Perl Boolean semantics
#EXCEPT THAT YOU SHOULD NOT USE undef for false.  Any missing keys, keys with undef
#values, or missing/undef $SSHARE_CMD_CAPABILITIES are interpretted as the status
#of the capability is unknown and might need to run sshare to determine.
#
#Recognized capabilities are listed below in definition of @SSHARE_CMD_CAPABILITIES_LIST
my $SSHARE_CMD_CAPABILITIES = {};
#
#To indicate that the --partition flag is supported, use
# $SSHARE_CMD_CAPABILITIES = { can_display_partition => 1 };
#To indicate that the --partition flag is not supported, use
# $SSHARE_CMD_CAPABILITIES = { can_display_partition => 0 };
#Alternatively, to get (our best guess) of capabilities by Slurm version number, do
# Slurm::Sshare->set_sshare_capabilities_by_version('15.08.2');
#replacing 15.08.2 with your Slurm version

#These are the capabilities of sshare cmd we recognize
my @SSHARE_CMD_CAPABILITIES_LIST =
(	'can_display_partition', #Whether sshare supports --partition flag to
				#cause it to display partition information
);
my %SSHARE_CMD_CAPABILITIES_HASH = map { $_ => undef } @SSHARE_CMD_CAPABILITIES_LIST;

#This is for the caching of discovered sshare cmd capabilities, should be left undef
my $_CACHED_SSHARE_CMD_CAPABILITIES;

#These are intended for regression tests only
my $_last_raw_output;
sub _sshare_last_raw_output($)
{       return $_last_raw_output;
}

#And because each sshare_list can result in multiple calls to sshare,
#a variant which saves all output from give sshare_list command
my $_sslist_last_raw_output;
sub _sshare_list_last_raw_output($)
{	return $_sslist_last_raw_output;
}

#And allow clearing for some tests
sub _clear_sshare_last_raw_output($)
{	$_last_raw_output = undef;
}

#-------------------------------------------------------------------
#	Class methods
#-------------------------------------------------------------------

sub verbose($;$)
{	my $class = shift;
	my $new = shift;
	if ( defined $new )
	{	$VERBOSE = $new?1:0;
	}
	return $VERBOSE;
}

sub sshare($;$$)
{	my $class = shift;
	my $new = shift;
	my $caps = shift;
	my $me = __PACKAGE__ . '::sshare';
	if ( $new )
	{	$SSHARE_CMD = $new;
		if ( $caps && ref($caps) eq 'HASH' )
		{	$SSHARE_CMD_CAPABILITIES = $caps;
		} elsif ( $caps && ! ref($caps) )
		{	$class->set_sshare_capabilities_by_version($caps);
		} else
		{	$SSHARE_CMD_CAPABILITIES = undef;
			croak "$me: Invalid value '$caps' for sshare capabilities (expecting version number or hash ref) at "
				if $caps;
		}
		$_CACHED_SSHARE_CMD_CAPABILITIES = undef;
			
	}
	return $SSHARE_CMD;
}

sub sshare_cmd_supports($$;$)
#This checks if the current sshare command supports the named capability.
#It will use user given answer first, then try to used cached information, 
#and only if necessary invoke an actual sshare command to find out.
#Returns 1 (true) if sshare supports the capability
#Returns 0 (false) if sshare does NOT support the capability
#If $cachedonly flag is given and set, will never invoke an sshare to determine the
#result, and may return undef (also false) indicating we do not know.
{	my $class = shift;
	my $capname = shift;
	my $cacheonly = shift;
	my $me = __PACKAGE__ . '::sshare_cmd_supports';

	unless ( exists $SSHARE_CMD_CAPABILITIES_HASH{$capname} )
	{ 	warn "$me: Unrecognized capability '$capname', ignoring, at ";
		return 0; #Unrecognized capabilities are NOT supported
	}

	my $canwe;
	if ( $SSHARE_CMD_CAPABILITIES && ref($SSHARE_CMD_CAPABILITIES) eq 'HASH' )
	{	$canwe = $SSHARE_CMD_CAPABILITIES->{$capname};
	}

	#User provided a value, return it
	return ($canwe?1:0) if defined $canwe;

	#See if we have cached a value
	$canwe = undef;
	if ( $_CACHED_SSHARE_CMD_CAPABILITIES && ref($_CACHED_SSHARE_CMD_CAPABILITIES) eq 'HASH' )
	{	$canwe = $_CACHED_SSHARE_CMD_CAPABILITIES->{$capname};
	}

	#Return a cached value if we have it
	return ($canwe?1:0) if defined $canwe;

	#We only requested cached value, so exit with unknown result (undef)
	return if $cacheonly;

	#No cached value, we need to determine it
	return $class->_determine_sshare_cmd_capability($capname);
}
	
sub _determine_sshare_cmd_capability($$)
#Determine whether sshare cmd can do $capname
#Will update $_CACHED_SSHARE_CMD_CAPABILITIES and return result
{	my $class = shift;
	my $capname = shift;
	my $me = __PACKAGE__ . '::_determine_sshare_cmd_capability';

	if ( $capname eq 'can_display_partition' )
	{	$class->_determine_sshare_caps_from_help;
		return $_CACHED_SSHARE_CMD_CAPABILITIES->{$capname};
	}
}
		
sub _determine_sshare_caps_from_help($)
#This runs a sshare --help command, and sets what sshare cmd capabilities
#we can (in _CACHED_SSHARE_CMD_CAPABILITIES)
{	my $class = shift;

	my $output = $class->run_generic_sshare_cmd( '--help');
	my (@tmp);
	
	#Check for 'can_display_partition' (--partition flag)
	@tmp = grep /--partition/, @$output;
	$class->_set_sshare_caps_cache('can_display_partition', scalar(@tmp) );

}

sub _set_sshare_caps_cache($$$)
#This will set _CACHED_SSHARE_CMD_CAPABILITIES for $capname to $val
{	my $class = shift;
	my $capname = shift;
	my $val = shift;

	$val = $val?1:0;
	$_CACHED_SSHARE_CMD_CAPABILITIES={} 
		unless $_CACHED_SSHARE_CMD_CAPABILITIES &&
		ref($_CACHED_SSHARE_CMD_CAPABILITIES) eq 'HASH';

	$_CACHED_SSHARE_CMD_CAPABILITIES->{$capname} = $val;
}

sub _sshare_capabilities_by_version($$)
#Return the appropriate  sshare_capabilities hash by Slurm version number
#This is our "guess" of what different versions can do
#Returns hash ref.
{	my $class = shift;
	my $slurm_version = shift;
	my $me = __PACKAGE__ . '::_sshare_capabilities_by_version';

	#Leave everything on autodiscovery if no version given
	return unless defined $slurm_version; 

	#Strip leading/trailing whitespace
	$slurm_version =~ s/^\s*//; $slurm_version =~ s/\s*$//;
	
	my @vcomps = split /\./, $slurm_version;
	my $slurm_major = $vcomps[0];

	
	#Leave everything on autodiscovery if bad version given
	return unless $slurm_major =~ /^\d+$/;


	#Guess at capabilities
	if ( $slurm_major < 15 )
	{	#Looks like an old version of slurm
		#At least before partition info in sshare
		return
		{	can_display_partition => 0,
		};
	} else
	{	#Assuming a newer version which can display partition info in sshare
		return
		{	can_display_partition => 1,
		};
	}
}

sub set_sshare_capabilities_by_version($$)
#Sets the sshare capabilities hash to appropriate value based on slurm version
{	my $class = shift;
	my $slurm_version = shift;
	my $me = __PACKAGE__ . '::set_sshare_capabilities_by_version';

	my $caphash = $class->_sshare_capabilities_by_version($slurm_version);
	unless ( defined $caphash && ref($caphash) eq 'HASH' )
	{	$caphash = '' unless defined $caphash;
		warn "$me: Ignoring invalid/missing version $slurm_version at ";
		return;
	}

	$SSHARE_CMD_CAPABILITIES = $caphash;
}

	

#-------------------------------------------------------------------
#	Accessors
#-------------------------------------------------------------------

my @rw_accessors = qw(
);

#We include partition, and not grptresmins/tresrunmins.  The latter
#are added separately to @ro_accessors, and sshare list either ends
# in grpcpumins+cpurunmins OR grptresmins + tresrunmins, so 
#new_from_sshare_record handles specially.
my @sshare_fields_in_order = qw(
	account
	user
	partition
	raw_shares
	normalized_shares
	raw_usage
	normalized_usage
	effective_usage
	fairshare
	grpcpumins
	cpurunmins
);

my @ro_accessors = (@sshare_fields_in_order, 'cluster', 'grptresmins', 'tresrunmins' );

__PACKAGE__->mk_accessors(@rw_accessors);
__PACKAGE__->mk_ro_accessors(@ro_accessors);


my @required_parms = qw(
);

#-------------------------------------------------------------------
#	Constructors, etc
#-------------------------------------------------------------------

sub new($;@)
{	my $class = shift;
	$class = ref($class) if ref($class);
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
		if ( $arg eq 'grptresmins' )
		{	$obj->_set_grptresmins($val);
		} elsif ( $arg eq 'tresrunmins' )
		{	$obj->_set_tresrunmins($val);
		} else
		{	$meth = $arg;
			$obj->set($meth,$val);
		}
	}


	#Warn about unknown arguments
	if ( scalar(keys %args) )
	{	my $tmp = join ", ", (keys %args);
		croak "Unrecognized arguments [ $tmp ] to constructor at ";
	};
}

sub _set_defaults($)
{	my $obj = shift;

	#Duplicate GrpCPUMins/CPURunMins <=> GrpTRESMins/TRESRunMins
	#Since all accessors are read-only, we can just do it here when instantiating object
	#Otherwise, probably best to create private _grpcpumins, etc. accessor/mutators and have the
	#public grpcpumin, etc. accessor/mutators set their partner appropriately when they are set.
	my ($tmp1, $tmp2, $val);

	$tmp1 = $obj->grptresmins;
	$tmp2 = $obj->grpcpumins;
	if ( defined $tmp1 )
	{	unless ( defined $tmp2 )
		{	#Set grpcpumins from grptresmins->{cpu}
			$val = $tmp1->{cpu};
			$obj->set('grpcpumins', $val) if defined $val;
		}
	} else
	{	if ( defined $tmp2 )
		{	#Set grptresmins from grpcpumins
			$val = { cpu => $tmp2 };
			$obj->_set_grptresmins($val);
		}
	}

	$tmp1 = $obj->tresrunmins;
	$tmp2 = $obj->cpurunmins;
	if ( defined $tmp1 )
	{	unless ( defined $tmp2 )
		{	#Set cpurunmins from trerunsmins->{cpu}
			$val = $tmp1->{cpu};
			$obj->set('cpurunmins', $val) if defined $val;
		}
	} else
	{	if ( defined $tmp2 )
		{	#Set tresrunmins from cpurunmins
			$val = { cpu => $tmp2 };
			$obj->_set_tresrunmins($val);
		}
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

#-----	Special private mutators for tresrunmins/grptresmins
#	Handle either string or hash ref

sub _tres_string2hash($$)
#Converts tres string (fld=val, fld2=val2, etc) to hash ref ( {fld=>val, fld2=>val2} )
{	my $obj = shift;
	my $string = shift;
	my $fldname = shift;
	my $me = __PACKAGE__ . '::new';

	croak "$me: Illegal value $string for $fldname (expecting HASH ref or string) at "
			if ref($string);

	my $href = {};

	#Strip leading/trailing spaces
	$string =~ s/^\s*//; $string =~ s/\s*$//;

	my @records = split /\s*,\s*/, $string;
	foreach my $record (@records)
	{	
		croak "$me: Illegal value '$string' for $fldname: " .
			"No = in record '$record' at "
			unless ( $record =~ /=/ );

		my ( $fld, $val ) = split /\s*=\s*/, $record;
		croak "$me: Illegal value '$string' for $fldname: " .
			"Duplicate TRES value for $fld at "
			if exists $href->{$fld};

		$href->{$fld} = $val;
	}

	return $href;
}

		
sub _set_grptresmins($$)
#Sets grptresmins either from string or hash ref
{	my $obj = shift;
	my $new = shift;
	my $fld = 'grptresmins';
	my $me = __PACKAGE__ . '::new';

	unless ( defined $new )
	{	#new = undef, so undefine it
		$obj->set($fld, undef);
		return;
	}

	unless ( ref($new) eq 'HASH' )
	{	#Should have a string
		$new = $obj->_tres_string2hash($new, $fld);
	}

	$obj->set($fld, $new);
}

sub _set_tresrunmins($$)
#Sets tresrunmins either from string or hash ref
{	my $obj = shift;
	my $new = shift;
	my $fld = 'tresrunmins';
	my $me = __PACKAGE__ . '::new';

	unless ( defined $new )
	{	#new = undef, so undefine it
		$obj->set($fld, undef);
		return;
	}

	unless ( ref($new) eq 'HASH' )
	{	#Should have a string
		$new = $obj->_tres_string2hash($new, $fld);
	}

	$obj->set($fld, $new);
}

		
#-------------------------------------------------------------------
#	Class methods to Run basic sshare commands
#-------------------------------------------------------------------

sub _noshell_backticks($$@)
#Calls an external command using pipes and forks so no shell gets invoked
#Returns ($err, @out) where $err is the error is the exit status of
#the command, and @out is the list of output returned, line by line.
#If $mode is 0, only STDOUT is returned in @out, 
#If $mode is non-zero, STDERR is dupped onto STDOUT and also returned.
{	my $class = shift;
	my $mode = shift;
	my @cmd = @_;

	my ($err, @out, $PIPE, $res);
	my $chd_excode=254;

	if ( $res = open($PIPE, "-|" )  )
	{	#Parent
		if ( ! defined $res )
		{	my $tmp = join ' ', @cmd;
			die "Pipe to '$tmp' failed: $!";
		}
		@out = <$PIPE>;
		$res = close $PIPE;
		$err = $?;
		if ( $err && ( ($err >> 8) == $chd_excode ) )
		{	#We (probably?) got an exception running exec in child process
			#Re-raise the exception
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
		#Otherwise, if _noshell_backticks_ is put in an eval block,
		#an exception raised by exec (e.g. taint issues) will result in
		#BOTH child and parent continuing from the user's eval block.
		#See e.g http://www.perlmonks.org/?node_id=166538
		eval { exec { $cmd[0] } @cmd; #Not subject to shell escapes
		};
		#We only reach here if exec raised an exception
		warn "$@" if $@;
		exit $chd_excode;
	}
}

sub _run_generic_sshare_cmd_always($@)
#Run a generic sshare cmd, returning results
#Does NOT honors dryrun.
#This should only be called directly for commands which do NOT
#modify the database
{	my $class = shift;
	my @args = @_;

	my $cmd = $class->sshare;
	my $mode = 1;
	if ( $class->verbose )
	{	#Verbose mode:
		#Output command before executing it
		my @tmp = ($class->sshare, @args);
		my $tmpcmd = join ' ', @tmp;
		print STDERR "[VERBOSE] $tmpcmd\n";
	}
	my ($err, @out ) = $class->_noshell_backticks($mode, $cmd, @args);
        $_last_raw_output = [ @out ];
	return ($err, @out);
}

sub run_generic_sshare_cmd($@)
#Run a generic sshare cmd, returning results
#No dryrun mode, as sshare is view only anyway.  Also, no --readonly flag.
#
#Returns list ref of output, line by line on success.
#Returns non-ref error message on error.
{	my $class = shift;
	my @args = @_;

	my ($err, @out) = $class->_run_generic_sshare_cmd_always(@args);
	if ( $err )
	{	my $errstr = "Exit code: $err";
		my $output = join "\n", @out;
		$errstr .= "\n$output" if $output;
		return $errstr;
	}
	#return $err if $err;
	return [ @out ];
	
}

sub run_generic_sshare_list_command($@)
#Runs a sshare list command, returns output as a list ref of list refs
#of the fields in order. 
#(Tried using hash refs, but those get abbreviated.  Ugh!)
#'list' should be included in the command spec
#
#The list of arguments to this method are passed as arguments to the sshare
#command.  
#On error, returns non-ref error message/error code
#
#Appends --parsable2, --long and --noheader to the command
{	my $class = shift;
	my @cmd = @_;

	push @cmd, '--parsable2', '--noheader', '--long';
	my $lines = $class->run_generic_sshare_cmd(@cmd);

	return $lines unless $lines && ref($lines) eq 'ARRAY';

	my $results = [];
	LINE: foreach my $line (@$lines)
	{	chomp $line;
		next LINE unless $line =~ /\|/;
		my @values = split /\|/, $line;
		push @$results, \@values;
	}

	return $results;
}

#-------------------------------------------------------------------
#	Class methods to generate Slurm::Sshare object from output of
#	sshare command
#-------------------------------------------------------------------

sub _sshare_fields_in_order($)
#Should return a list ref of field names in order sacctmgr will return them
{	my $class = shift;
	return [ @sshare_fields_in_order];
}

sub new_from_sshare_record($$$)
#Generates a new instance from a list ref as obtained from the
#sshare command output
{	my $class = shift;
	my $record = shift;
	my $cluster = shift;

	my $fields = $class->_sshare_fields_in_order;
	my @fields = @$fields;
	my @record = @$record;

	#Determine if we have partition info or not
	#3rd field is either partition or raw_shares, so if not
	#a number we have partition (unless undef (only for root?)
	#in which case look at 4th field, either RawShare (if partition)
	#NormShares (w/out part) or so check if integral.)
	my $have_partition_info;
	my $tmp = $record->[2];
	if ( defined $tmp && $tmp ne '' )
	{	#Have a value
		#Is it an integer (for raw_shares)
		if ( $tmp =~ /^\s*\d+\s*$/ )
		{	#Looks like raw_shares, so no partinfo
			$have_partition_info = 0;
		} else
		{	#Non-numeric, so must be a partition name
			$have_partition_info = 1;
		}
	} else
	{	#No value for raw shares/partition.  
		#Try next field and see if integral
		$tmp = $record->[3];
		if ( $tmp =~ /^\s*\d+\s*$/ )
		{	#Integral, so is RawShares, so we have partition
			$have_partition_info = 1;
		} elsif ( $tmp ne '' )
		{	$have_partition_info = 0;
		} else
		{	#Boths [2] and [3] are empty; i.e. either
			#both raw and normshares are empty (and no partinfo)
			#of both partition and rawshares are empty (w partinfo)
			#[4] should either be rawusage (no partinfo) or normshares (w partinfo)
			$tmp = $record->[4];
			if ( $tmp =~ /^\s*\d+\s*$/ )
			{	#Integer, so looks like rawusage
				$have_partition_info = 0;
			} elsif ( $tmp =~ /\./ )
			{	#Has decimal point, so looks like normshares
				$have_partition_info = 1;
			} else
			{	#I am about to give up.  Count fields
				#Will see one extra due to final |
				$have_partition_info = (scalar(@$record) == scalar(@fields) +1)?1:0;
			}
		}
	}
	if ( $have_partition_info )
	{	#We should cache that we have a sshare which can give partition info
		$class->_set_sshare_caps_cache('can_display_partition', 1 );
	}
	#but not if $have_partition_info=0, as maybe sshare can do it but requested it not do so

	my @newargs = ();
	@newargs = (cluster => $cluster) if $cluster;

	FIELD: foreach my $fld (@fields)
	{	next FIELD if $fld eq 'partition' && ! $have_partition_info;
		my $val = shift @record;
		$val =~ s/^ *// if defined $val;
		$fld = lc $fld;

		if ( $fld eq 'grpcpumins' )
		{	#Is this grpcpumins or grptresmins?  Former is integral, latter is x=y
			$fld = 'grptresmins' if ( defined $val && $val !~ /^\s*\d+\s*$/ && $val !~ /^\s*$/ );
		}
		if ( $fld eq 'cpurunmins' )
		{	#Is this cpurunmins or tresrunmins?  Former is integral, latter is x=y
			$fld = 'tresrunmins' if ( defined $val && $val !~ /^\s*\d+\s*$/ && $val !~ /^\s*$/ );
		}
		if ( $fld eq 'grptresmins' || $fld eq 'tresrunmins' )
		{	#If we have TRES data, our sshare should be new enough to give partition info
			$class->_set_sshare_caps_cache('can_display_partition', 1 );
		}

			
		push @newargs, $fld, $val if defined $val && $val ne '';
	}

	my $obj = $class->new(@newargs);
	return $obj;
}

#-------------------------------------------------------------------
#	High level commands
#-------------------------------------------------------------------

sub sshare_list($@)
#Gets sshare output.
#Input parameters are key=>value pairs and can include:
#	accounts: list of accounts to get information for
#	clusters: list of clusters to get information for. 
#	users: list of users to get information for
#	nopartinfo: boolean to determine whether we try to get partition information.
#
#List values can be either list refs or CSV strings.  For users, if the single
#string 'ALL' is given (not part of a list), then all users will be listed.
#
#If nopartinfo flag is set, the sshare command will not include the '--partition'
#flag to get partition information.  Default is unset (so include the '--partition'
#flag if the sshare command supports it).  This of course is only useful when 
#the sshare command supports the --partition flag (although can be used on older sshares
#to avoid attempting to discover if it is supported).
#
#On success, returns a list ref of Slurm::Sshare objects corresponding
#to the output of the sshare command.  Possibly an empty list.
#
#On error, either aborts or returns non-ref true value (text describing
#the error)
{	my $class = shift;
	my %where = @_;

	my $me = 'sshare_list';
	my @args = ();
	my $tmp;

	my $accounts = delete $where{accounts};
	my $clusters = delete $where{clusters};
	my $users = delete $where{users};
	my $nopartinfo = delete $where{nopartinfo};
	croak "$me: Extraneous arguments [" . (join ', ', (keys %where) ) .
		"] given, aborting at " if scalar(%where);

	if ( scalar(keys %where) )
	{	$tmp = join ", ", (keys %where);
		croak "$me: Unrecognized arguments [ $tmp ], aborting.\n";
	}

	if ( $accounts )
	{	unless ( ref($accounts) eq 'ARRAY' )
		{	$accounts = [ split /\s*,\s*/, $accounts ];
		}
	}
	if ( $accounts && scalar(@$accounts) )
	{	$tmp = join ",", @$accounts;
		push @args, "--accounts=$tmp";
	}

	if ( $clusters )
	{	unless ( ref($clusters) eq 'ARRAY' )
		{	$clusters = [ split /\s*,\s*/, $clusters ];
		}
	}
	#unless ( $clusters && scalar(@$clusters) )
	#{	croak "$me: At least one cluster must be specified at ";
	#}

	if ( $users )
	{	unless ( ref($users) eq 'ARRAY' )
		{	$users = [ split /\s*,\s*/, $users ];
		}
	}
	if ( $users && ref($users) eq 'ARRAY' )
	{   if ( scalar(@$users) ) 
	    {	if ( $users->[0] eq 'ALL' )
		{	push @args, '--all';
		} else
		{	$tmp = join ",", @$users;
			push @args, "--users=$tmp";
		}
	    } else
	    {	#We were given an empty list ref of users
		#Return only records with NO user field
		#Can't actually do it, so set users to non-existant user
		push @args, "--users='NO SUCH USER'";
	    }
	}

	#Include partition name in results if can and not explicitly requested not to
	unless ($nopartinfo)
	{	if ( $class->sshare_cmd_supports('can_display_partition') )
		{	push @args, '--partition';
		}
	}

	#Save raw output for debugging purposes
	$_sslist_last_raw_output = [];

	my @objects = ();

	if ( $clusters )
	{   # One or more clusters specified; run sshare on each specified cluster
	    # and label results based on the cluster
	    foreach my $cluster (@$clusters)
	    {	my $tmplist = $class->run_generic_sshare_list_command(
			"--clusters=$cluster", @args);
		push @$_sslist_last_raw_output, @{$class->_sshare_last_raw_output};

		unless ( $tmplist && ref($tmplist) )
		{	return "Error in sshare cmd for $cluster: $tmplist";
		}

		foreach my $rec (@$tmplist)
		{	
			my $obj = $class->new_from_sshare_record($rec,$cluster);
			push @objects, $obj;
		}
	    }
	} else
	{	#No clusters specified
	    	my $tmplist = $class->run_generic_sshare_list_command(@args);
		push @$_sslist_last_raw_output, @{$class->_sshare_last_raw_output};

		unless ( $tmplist && ref($tmplist) )
		{	return "Error in sshare cmd: $tmplist";
		}

		foreach my $rec (@$tmplist)
		{	
			my $obj = $class->new_from_sshare_record($rec);
			push @objects, $obj;
		}
	}
		
	return [@objects];
}

sub combine_tres_hashes($$$)
#Given two hash refs representing TRES hashes, they will be combined.
#Either hash  ref can be undef, which is treated essentially as an empty hash
#(except that if both are undef, this will return undef)
#If a field is common to both and defined value in both, the field will be
#in the combined hash with the sum of the values of the individual hashes.
#If a field is found in only one of the two, it will be passed unchanged into
#the combined hash
{	my $class = shift;
	my $thash1 = shift;
	my $thash2 = shift;
	my $me = __PACKAGE__ . '::combine_tres_hashes';

	return unless $thash1 || $thash2;
	croak "$me: Invalid tres1 ($thash1), expecting hash ref, at "
		if $thash1 && ref($thash1) ne 'HASH';
	croak "$me: Invalid tres2 ($thash2), expecting hash ref, at "
		if $thash2 && ref($thash2) ne 'HASH';
	$thash1 = {} unless $thash1;
	$thash2 = {} unless $thash2;

	my $chash = {};
	my @keys = keys %$thash1;
	push @keys, (keys %$thash2);
	my %temp = map { $_ => undef } @keys;
	@keys = keys %temp;

	foreach my $key (@keys)
	{	my $tres1 = $thash1->{$key};
		my $tres2 = $thash2->{$key};

		if ( defined $tres1 && defined $tres2 )
		{	#Defined for both
			$chash->{$key} = $tres1 + $tres2;
		} elsif ( defined $tres1 )
		{	$chash->{$key} = $tres1;
		} elsif ( defined $tres2 )
		{	$chash->{$key} = $tres2;
		}
	}
	return $chash;
}
		
	
sub combine_sshare_usage_records($$;$)
#Takes a list ref of Slurm::Sshare instances (e.g. filtered output of sshare_list
#command), and returns a hash ref containing the "sum" of the records.
#NOTE: no checks are made that it is sensible to combine the records given
#The resultant hash will have the following keys:
#	raw_shares
#	normalized_shares
#	raw_usage
#	normalized_usage
#	effective_usage
#	fairshare
#	grpcpumins
#	cpurunmins
#Fields will only exist if exist and have defined values in at least one element.
#All of the above are simply summed
#
#In addition, the hash valued fields
#	grptresmins
#	tresrunmins
#will be added key by key.
#
#Elements of the  input list ref can also be a hash ref with the above fields instead
#of an actual Slurm::Sshare object.
{	my $class = shift;
	my $list = shift || [];
	my $me = shift || __PACKAGE__ . '::combine_sshare_usage_records';

	my ($rshares, $nshares, $rusage, $nusage, $eusage, $fshare, $gcpumins, $crunmins);
	my ($grptresmins, $tresrunmins);
	foreach my $rec (@$list)
	{	my ( $tmp_rshares, $tmp_nshares, $tmp_rusage, $tmp_nusage);
		my ( $tmp_eusage, $tmp_fshare, $tmp_gcmins, $tmp_crmins);
		my ( $tmp_grptresmins, $tmp_tresrunmins);
		#Get values for this record
		if ( UNIVERSAL::isa($rec, 'Slurm::Sshare') || UNIVERSAL::can($rec,'raw_usage') )
		{	#Looks like a Slurm::Sshare instance
			$tmp_rshares = $rec->raw_shares;
			$tmp_nshares = $rec->normalized_shares;
			$tmp_rusage  = $rec->raw_usage;
			$tmp_nusage  = $rec->normalized_usage;
			$tmp_eusage  = $rec->effective_usage;
			$tmp_fshare  = $rec->fairshare;
			$tmp_gcmins  = $rec->grpcpumins;
			$tmp_crmins  = $rec->cpurunmins;
			$tmp_grptresmins = $rec->grptresmins;
			$tmp_tresrunmins = $rec->tresrunmins;
		} elsif ( ref($rec) eq 'HASH' )
		{	#Simple hash ref
			$tmp_rshares = $rec->{raw_shares};
			$tmp_nshares = $rec->{normalized_shares};
			$tmp_rusage  = $rec->{raw_usage};
			$tmp_nusage  = $rec->{normalized_usage};
			$tmp_eusage  = $rec->{effective_usage};
			$tmp_fshare  = $rec->{fairshare};
			$tmp_gcmins  = $rec->{grpcpumins};
			$tmp_crmins  = $rec->{cpurunmins};
			$tmp_grptresmins = $rec->{grptresmins};
			$tmp_tresrunmins = $rec->{tresrunmins};
		} else
		{	croak "$me: Illegal sshare usage record $rec, expecting Slurm::Sshare instance";
		}

		if ( defined $tmp_rshares )
		{ 	$rshares = 0 unless defined $rshares;
			$rshares += $tmp_rshares;
		}
		if ( defined $tmp_nshares )
		{ 	$nshares = 0 unless defined $nshares;
			$nshares += $tmp_nshares;
		}
		if ( defined $tmp_rusage )
		{ 	$rusage = 0 unless defined $rusage;
			$rusage += $tmp_rusage;
		}
		if ( defined $tmp_nusage )
		{ 	$nusage = 0 unless defined $nusage;
			$nusage += $tmp_nusage;
		}
		if ( defined $tmp_eusage )
		{ 	$eusage = 0 unless defined $eusage;
			$eusage += $tmp_eusage;
		}
		if ( defined $tmp_fshare )
		{ 	$fshare = 0 unless defined $fshare;
			$fshare += $tmp_fshare;
		}
		if ( defined $tmp_gcmins )
		{ 	$gcpumins = 0 unless defined $gcpumins;
			$gcpumins += $tmp_gcmins;
		}
		if ( defined $tmp_crmins )
		{ 	$crunmins = 0 unless defined $crunmins;
			$crunmins += $tmp_crmins;
		}

		#Handle TRES stuff
		if ( defined $tmp_grptresmins)
		{	$grptresmins = $class->combine_tres_hashes(
				$grptresmins, $tmp_grptresmins);
		}
		if ( defined $tmp_tresrunmins)
		{	$tresrunmins = $class->combine_tres_hashes(
				$tresrunmins, $tmp_tresrunmins);
		}
	}

	my $hash = {
		raw_shares => $rshares,
		normalized_shares => $nshares,
		raw_usage => $rusage,
		normalized_usage => $nusage,
		effective_usage => $eusage,
		fairshare => $fshare,
		grpcpumins => $gcpumins,
		cpurunmins => $crunmins,
		grptresmins => $grptresmins,
		tresrunmins => $tresrunmins,
	};
	return $hash;
}

sub collect_usage_records_by_account($@)
#Takes a list ref of Slurm::Sshare instances (e.g. output of sshare_list)
#and collects them by cluster, account, and user.
#Input is key => value pairs, with the following keys recognized:
#	records: list ref of Slurm::Sshare instances REQUIRED
#	clusters: list ref of clusters to include in results.
#		If omitted, results will include data for all clusters
#		found in records.  To get results for records with
#		cluster undef, use either 'DEFAULT' or undef in list ref.
#	accounts: list ref of accounts to include in results.
#		If omitted, results will include data for all accounts
#		found in results.
#	users: list ref of users to include results for.  Defaults to
#		all users found in results.
#The return value is a hash ref keyed on the cluster names (an undef cluster
#name is converted to the string 'DEFAULT').  The value is another hash
#ref, this time keyed on the account name.  The value of the account name
#key is yet another hash ref, this one containing usage information for
#the specified account.  It may have the following keys:
#	account: name of the account (always present)
#	cluster: name of the cluster (might be undef)
#	raw_shares
#	normalized_shares
#	raw_usage
#	normalized_usage
#	effective_usage
#	fairshare
#	grpcpumins
#	cpurunmins
#	grptresmins
#	tresrunmins
#	users_hash: a hash ref keyed on user name, containing usage data
#		for that user AND account.  It has similar structure to
#		the account usage data, except no users_hash key, and instead
#		has an user key with the name of the user.
#For both the account and user level usage hash, the usage fields may or may not
#be present, depending on whether there was any data for them in the records.
{	my $class = shift;
	my %args = @_;
	my $me = __PACKAGE__ . '::collect_usage_records_by_account';

	my $records = delete $args{records};
	my $only_clusters = delete $args{clusters};
	my $only_accounts = delete $args{accounts};
	my $only_users = delete $args{users};

	croak "$me: Missing required parameter 'records' at " unless $records;
	croak "$me: Invalid value '$records' for parameter records (expecting list ref) at "
		unless $records && ref($records) eq 'ARRAY';
	if ( %args )
	{	my $tmp = join ', ', (keys %args);
		croak "$me: Extraneous parameters [ $tmp ], aborting at ";
	}
	
	$only_clusters = [ $only_clusters ] 
		if $only_clusters && ref($only_clusters) ne 'ARRAY';
	$only_clusters = [ map { (defined $_)?$_:'DEFAULT' } @$only_clusters ]
		if $only_clusters && ref($only_clusters) eq 'ARRAY';
	$only_clusters = [ undef ]
		if $only_clusters && ref($only_clusters) eq 'ARRAY' && scalar(@$only_clusters);
	$only_accounts = [ $only_accounts ] 
		if $only_accounts && ref($only_accounts) ne 'ARRAY';
	$only_users = [ $only_users ] 
		if $only_users && ref($only_users) ne 'ARRAY';
	my %only_clusters = ();
	my %only_accounts = ();
	my %only_users = ();
	%only_clusters = map { $_ => undef } @$only_clusters 
		if $only_clusters && ref($only_clusters) eq 'ARRAY';
	%only_accounts = map { $_ => undef } @$only_accounts
		if $only_accounts && ref($only_accounts) eq 'ARRAY';
	%only_users = map { $_ => undef } @$only_users
		if $only_users && ref($only_users) eq 'ARRAY';

	#Get all clusters referenced in our records
	my @clusters = map { $_->cluster } @$records;
	my %temp = map { (defined($_)?$_:'') => undef } @clusters;
	@clusters = keys %temp;

	my $results = {};

	CLUSTER: foreach my $cluster (@clusters)
	{	my $tmpclus = $cluster;
		$tmpclus = 'DEFAULT' unless defined $cluster;
		$tmpclus = 'DEFAULT' if $cluster eq '';
		next CLUSTER if $only_clusters && ! exists $only_clusters{$tmpclus};
		my $cresults = {};

		#Get all records for this cluster
		my @crecords;
		if ( $tmpclus eq 'DEFAULT' )
		{	@crecords = grep { ! defined $_->cluster } @$records;
		} else
		{	@crecords = grep { $_->cluster eq $cluster } @$records;
		}

		#Get all accounts referenced in our records
		my @accounts = map { $_->account } @crecords;
		%temp = map { $_ => undef } @accounts;
		@accounts = keys %temp;

		ACCOUNT: foreach my $account (@accounts)
		{	next ACCOUNT if $only_accounts && ! exists $only_accounts{$account};

			#Get all records for this account
			my @arecords = grep { $_->account eq $account } @crecords;

			#Get the data for the account as a whole (records with no user set)
			my @nouser = grep { ! $_->user } @arecords;
			my $ahash = $class->combine_sshare_usage_records(\@nouser, $me);
			$ahash = {} unless $ahash && ref($ahash) eq 'HASH';
			my $aresults = { 	
					cluster=> $cluster,
					account => $account,
					%$ahash,
				};

			#Get collect the data for individual users in the account
			my @userrecs = grep { $_->user } @arecords;
			my @allusers = map { $_->user } @userrecs;
			%temp = map { $_ =>  undef } @allusers;
			@allusers = keys %temp;

			my $users_hash = {};

			USER: foreach my $user (@allusers)
			{	next USER if $only_users && ! $only_users{$user};
				my @urecords = grep { $_->user eq $user } @userrecs;
				my $uhash = $class->combine_sshare_usage_records(\@urecords, $me);
				$uhash = {} unless $uhash && ref($uhash) eq 'HASH';
				$uhash->{cluster} = $cluster;
				$uhash->{account} = $account;
				$uhash->{user} = $user;

				$users_hash->{$user} = $uhash;
			}

			$aresults->{users_hash} = $users_hash;

			$cresults->{$account} = $aresults;
		}

		$results->{$tmpclus} = $cresults;
	}

	return $results;
}
				
sub sshare_usage($@)
#This takes arguments which are passed to sshare_list.  The output from sshare_list
#is then passed to collect_usage_records_by_account for parsing.
#So see sshare_list for input specifications, and 
#collect_usage_records_by_account for output specifications.
#On non-fatal errors, returns a non-ref error string;
{	my $class = shift;
	my @args = @_;
	my $me = __PACKAGE__ . '::sshare_usage';

	my $records = $class->sshare_list(@args);
	return "$me: $records at " unless $records && ref($records) eq 'ARRAY';

	my $usage_hash = $class->collect_usage_records_by_account(records=>$records);
	return $usage_hash;
}

sub sshare_usage_for_account($@)
#Calls sshare_usage to get usage information for a specific cluster and account.
#Takes key => value pairs as input, recognizing the following keys
#	cluster: name of cluster.  If omitted, will use whatever cluster sshare defaults to
#	account: name of account to get usage info for.  REQUIRED
#	users: a list ref of user names to return data for.  If omitted, will return
#		data for all users associated with the account.  Give an empty list
#		ref (i.e. []) to get no user information returned.
#	nowarnings: boolean.  If true, suppress warnings about not finding any data for the account
#
#On non-fatal errors, returns a non-ref textual error string.
#On success, returns an account usage hash ref, e.g. a hash ref with keys
#	account: name of the account (always present). Same as input
#	cluster: same as cluster for input
#	raw_shares
#	normalized_shares
#	raw_usage
#	normalized_usage
#	effective_usage
#	fairshare
#	grpcpumins
#	cpurunmins
#	grptresmins
#	tresrunmins
#	users_hash: a hash ref keyed on user name, containing usage data
#		for that user AND account.  It has similar structure to
#		the account usage data, except no users_hash key, and instead
#		If users list was given. will be restricted to those users, otherwise will
#		contain all users who can access the account.
#NOTE: not all of the above fields will be defined; only if they have values in one of the records
#from sshare
#If no information for cluster/account found, a warning will be generated (unless nowarnings)
{	my $class = shift;
	my %args = @_;
	my $me = __PACKAGE__ . '::sshare_usage_for_account';

	#Get and validate input
	my $cluster = delete $args{cluster};
	my $account = delete $args{account};
	my $users = delete $args{users};
	my $nowarn = delete $args{nowarnings};

	croak "$me: Missing required parameter 'account' at " unless $account;
	if ( %args )
	{	my $tmp = join ', ', (keys %args);
		croak "$me: Extraneous arguments [$tmp] provided.  Aborting at ";
	}

	#call sshare
	my $tmpusers = $users;
	$tmpusers = 'ALL' unless $tmpusers;

	my @sshare_args = ( accounts=>[$account], users=>$tmpusers);
	push @sshare_args, clusters => [$cluster] if $cluster && $cluster ne 'DEFAULT';

	my $usage = $class->sshare_usage(@sshare_args);
	return $usage unless $usage && ref($usage) eq 'HASH';

	my $tmpclus = $cluster;
	$tmpclus = 'DEFAULT' unless defined $cluster;
	#my $clusage = $usage->{$cluster};
	my $clusage = $usage->{$tmpclus};
	unless ( $clusage && defined $clusage )
	{	#No records for this cluster?
		carp "$me: Unable to find information for cluster $cluster in sshare output at " unless $nowarn;
		return { cluster => $cluster, account=>$account };
	}

	my $ausage = $clusage->{$account};
	unless ( $ausage && defined $ausage )
	{	#No records for this account in cluster?
		carp "$me: Unable to find information for account $account in cluster $cluster in sshare output at " unless $nowarn;
		return { cluster => $cluster, account=>$account };
	}
	
	return $ausage;
}

sub sshare_usage_for_account_user($@)
#Calls sshare_usage to get usage information for a specific user, cluster and account.
#Takes key => value pairs as input, recognizing the following keys
#	cluster: name of cluster.  If omitted, will use whatever cluster sshare defaults to
#	account: name of account to get usage info for.  REQUIRED
#	user: name of user to get usage info for.  REQUIRED.
#	nowarnings: boolean.  If true, suppress warnings about not finding any data for the account
#
#On non-fatal errors, returns a non-ref textual error string.
#On success, returns an account usage hash ref, e.g. a hash ref with keys
#	account: name of the account (always present). Same as input
#	user: name of user (always present).  Same as input
#	cluster: same as cluster for input
#	raw_shares
#	normalized_shares
#	raw_usage
#	normalized_usage
#	effective_usage
#	fairshare
#	grpcpumins
#	cpurunmins
#	grptresmins
#	tresrunmins
#NOTE: not all of the above fields will be defined; only if they have values in one of the records
#from sshare
#If no information for cluster/account/user found, a warning will be generated (unless nowarnings)
{	my $class = shift;
	my %args = @_;
	my $me = __PACKAGE__ . '::sshare_usage_for_account_user';

	#Get and validate input
	my $cluster = delete $args{cluster};
	my $account = delete $args{account};
	my $user = delete $args{user};
	my $nowarn = delete $args{nowarnings};

	croak "$me: Missing required parameter 'account' at " unless $account;
	croak "$me: Missing required parameter 'user' at " unless $user;
	if ( %args )
	{	my $tmp = join ', ', (keys %args);
		croak "$me: Extraneous arguments [$tmp] provided.  Aborting at ";
	}

	#call sshare
	my @sshare_args = ( accounts=>[$account], users=>[$user] );
	push @sshare_args, clusters => [$cluster] if $cluster && $cluster ne 'DEFAULT';

	my $usage = $class->sshare_usage(@sshare_args);
	return $usage unless $usage && ref($usage) eq 'HASH';

	my $tmpclus = $cluster;
	$tmpclus = 'DEFAULT' unless defined $cluster;
	my $clusage = $usage->{$tmpclus};
	unless ( $clusage && defined $clusage )
	{	#No records for this cluster?
		carp "$me: Unable to find information for cluster $cluster in sshare output at " unless $nowarn;
		return { cluster => $cluster, account=>$account, user=>$user };
	}

	my $ausage = $clusage->{$account};
	unless ( $ausage && defined $ausage )
	{	#No records for this account in cluster?
		carp "$me: Unable to find information for account $account in cluster $cluster in sshare output at " unless $nowarn;
		return { cluster => $cluster, account=>$account, user=>$user };
	}

	my $users_hash = $ausage->{users_hash};
	unless ( $ausage && defined $ausage )
	{	#No records for users of this  account
		carp "$me: Unable to find user usage information for account $account in cluster $cluster in sshare output at " unless $nowarn;
		return { cluster => $cluster, account=>$account, user=>$user };
	}
	
	my $uusage = $users_hash->{$user};
	unless ( $uusage && defined $uusage )
	{	#No records for this user in this  account
		carp "$me: Unable to find usage information for user $user, account $account, cluster $cluster in sshare output at " unless $nowarn;
		return { cluster => $cluster, account=>$account, user=>$user };
	}
	
	return $uusage;
}

sub usage_for_account_in_cluster($@)
#******************************************************
#	This routine is DEPRECATED
#	Use sshare_usage_for_account instead.  
#	This will be deleted in a future version
#******************************************************
#Input same as sshare_usage_for_account.
#Output on success is
# [ $cpusec_used, $cpumin_limit, $cpumin_unused, $userdata ]
#where $userdata is hash ref with key=username, value=cpusecs used by user/account
{	my $class = shift;
	my %args = @_;
	my $me = __PACKAGE__ . '::usage_for_account_in_cluster';

	#Get and validate input
	my $cluster = delete $args{cluster};
	my $account = delete $args{account};
	my $users = delete $args{users};
	my $nowarn = delete $args{nowarnings};

	my $usage_hash = $class->sshare_usage_for_account(
		cluster=>$cluster, account=>$account,
		users=>$users, nowarnings=>$nowarn);
	return $usage_hash unless $usage_hash && ref($usage_hash) eq 'HASH';

	#Convert to old style output
	my $users_hash = $usage_hash->{users_hash};
	my $userdata;
	if ( $users_hash && ref($users_hash) eq 'HASH' && scalar(%$users_hash) )
	{	$userdata = { map { $_ => $users_hash->{$_}->{raw_usage} } (keys %$users_hash) };
	}
	my $cpusec_used = $usage_hash->{raw_usage} || 0;
	my $cpumin_used = $cpusec_used/60 if defined $cpusec_used;
	my $cpumin_limit = $usage_hash->{grpcpumins} || 0;
	my $cpumin_unused;
	$cpumin_unused = $cpumin_limit - $cpumin_used if defined $cpumin_limit && defined $cpumin_used;

	my $results = [ $cpusec_used, $cpumin_limit, $cpumin_unused, $userdata ];
	return $results;
}

sub usage_for_user_account_in_cluster($@)
#Input same as sshare_usage_for_account_user.
#Output on success is the number of cpusecs used by this user/account/cluster
#If no record for user in account/cluster found, will generate warning (unless
#nowarnings set) and return undef.
{	my $class = shift;
	my %args = @_;
	my $me = __PACKAGE__ . '::usage_for_user_account_in_cluster';

	#Get and validate input
	my $cluster = delete $args{cluster};
	my $account = delete $args{account};
	my $user = delete $args{user};
	my $nowarn = delete $args{nowarnings};

	my $usage_hash = $class->sshare_usage_for_account_user(
		cluster=>$cluster, account=>$account,
		user=>$user, nowarnings=>$nowarn);
	return unless defined $usage_hash;
	return $usage_hash unless $usage_hash && ref($usage_hash) eq 'HASH';

	my $cpusecs_used = $usage_hash->{raw_usage};
	return 0 unless defined $cpusecs_used;
	return $cpusecs_used;
}

#
1;
__END__

=head1 NAME

Slurm::Sshare - wrapper around the Slurm sshare command

=head1 SYNOPSIS

  use Slurm::Sshare;

  my $Sshare = 'Slurm::Sshare';
  $Sshare->verbose(1); #Print sshare commands as running them

  my $shares = $Sshare->sshare_list(clusters=>'dt2');

  foreach $share (@$shares)
  {	print $share->cluster, $share->account, $share->user, 
		$share->raw_usage, $share->grpcpumins, "\n";
  }

  my $usage_hash = $Sshare->sshare_usage(clusters=>'dt2', users=>'nixon');
  ...


=head1 DESCRIPTION

This is a wrapper around the Slurm B<sshare> command.  Basically, it allows
the Slurm B<sshare> command to called from within Perl, with some processing
of the output into a more Perlish form, thereby enabling Perl scripts to have
access to the share information for Slurm associations.  The B<sshare> command is called using
forks and pipes, so no additional shell is spawned, and shell expansion is not
done, making things a bit more secure.

The interface to this package is object oriented, mainly to reduce namespace pollution.

Since the B<sshare> command is only useful when Slurm is running with the priority/multifactor
plugin, this Perl class has the same restrictions on its usefulness.


=head2 Class Data Members

There are a couple of class data members that control the behavior of this package, that
can be controlled by the following accessor/mutators:

=over 4

=item B<sshare>:

The path to the Slurm B<sshare> command.  Normally, this defaults to just "sshare", i.e. it will
look for B<sshare> in your current path.  Systems staff can set a different default by changing the
value of B<$SSHARE_CMD> at the top of this file.  

=item B<verbose>:

If this is set, the module will work in B<verbose> mode, which means that every B<sshare> command will be
printed to STDERR before execution.  Default is false.  If you wish to explicitly set this to false, you
will need to provide a defined but false value (e.g. 0, but not undef) to the mutator.

=back

These methods are both  accessors and mutators, so in order to turn off verbose mode 
you need to supply a defined but false argument (e.g. 0) to the B<verbose> function; 
if the value undef is provided, the call will be treated as a pure accessor 
(rather than mutator) call, and the new value will B<not> be set.

The B<sshare> method accepts zero, one, or two explicit arguments.  With zero arguments, it acts as
an accessor and returns the current path to the Slurm B<sshare> command.  With a single argument, 
it sets the path.  With two arguments, the first argument sets the path, and the second argument is
either a Slurm version number, or a hash ref describing what capabilities/features that version
of the Slurm B<sshare> command supports (see the section  B<SLURM/Sshare versions> for more
information).  If the second argument is omitted, the package will assume it needs to detect the
capabilities of B<sshare> if needed (and any previously cached information about that is deleted).

Because the Slurm B<sshare> command only reads the Slurm databases and does not update them, there
is no B<dryrun> mode for this class.

=head2 CONSTRUCTOR and DATA members

Typically, one does not need to explicitly call the constructor for this class; the main methods
for external consumption are class methods, and might return one or more instances of the class.
But we include this section for completeness, and also to discuss the data members of this class.

The constructor B<new> takes key => value pairs to set the initial value of data members.
The instance data members are:

=over 4

=item B<account>:

The account for this association.

=item B<user>:

The user for this association.

=item B<partition>:

The partition for this association.  This is only available on newer Slurm sshares (v 15 and greater???).

=item B<cluster>:

The cluster for this association.

=item B<raw_shares>:

The raw shares assigned to this user/account.

=item B<normalized_shares>:

The shares assigned to this user/account, normalized to the total number of assigned shares.

=item B<raw_usage>:

The number of cpu-seconds of all the jobs that charged this account by this user.  This number will
decay over time when PriorityDecayHalfLife is defined.

=item B<normalized_usage>:

The number of cpu-seconds of all the jobs that charged this account by this user, normalized to the
total number of cpu-seconds of all jobs run on the cluster, subject to PriorityDecayHalfLife when defined.

=item B<effective_usage>:

Like B<normalized_usage>, but augmented to account for usage from sibling accounts.

=item B<fairshare>:

The fair share factorfor this account/user.

=item B<grpcpumins>: 

The CPU minutes limit set on the account.

=item B<cpurunmins>:

The estimated (based an walltime limits) number of CPU minutes needed to complete all currently running jobs
for this user/account.

=item B<grptresmins>:

This is a hash ref with the name of the trackable resource and the value is the limit imposed on this resource
for this association and its children.
Units will vary by the resource being tracked.  For "cpu" it is in cpu-minutes.  For "mem", it is in MB-minutes.

=item B<trescpumins>:

This is a hash ref with the name of the trackable resource and the value is the estimated amount of this
resource that will be consumed by currently running jobs under this association.
Units will vary by the resource being tracked.  For "cpu" it is in cpu-minutes, for "mem", in MB-minutes.

=back

Note that the B<cluster> data member is B<not> included in the B<sshare> output, but will be filled in if
possible by the B<sshare_list> command if it is called on a specific cluster.  

Also, older (before Slurm version 15.xx) versions of sshare output grpcpumins and cpurunmins, but later
versions output grptresmins and trescpumins.  This module will parse either format and produce both fields;
obviously, if an older version of sshare is being used there will not be any data for any trackable resource
except for "cpu".

The instance data members above are associated with read-only accessors with the same name.  Normally they
will be set when instances are created from parsing the output of the B<sshare> command.  

=head2 The B<sshare_list> method

This class methods runs the B<sshare> command with the appropriate arguments, and returns an array reference
of instances of this class representing the rows of output returned by the B<sshare> command.  In addition
to the class (an instance can also be used) invocant, it takes a (possibly empty) list of key => value
pairs to provide arguments to the B<sshare> command, with the following keys recognized:

=over 4

=item B<clusters>: 

A list of clusters to issue the B<sshare> command to.  I.e., the B<--clusters> argument to the B<sshare> command.

=item B<accounts>: 

A list of accounts to report on.  The B<--accounts> argument to the B<sshare> command.

=item B<users>: 

A list of users to report on.  The special value B<ALL>, if given as the only user, will result in the B<--all> flag passed to B<sshare>, otherwise this becomes the B<--users> argument to B<sshare>.  An undef value or an empty list ref will cause only records without an user value to be returned (in actuality,
we issue B<--users=NO SUCH USER> to B<sshare>).

=item B<nopartinfo>:

A boolean value.  If set, the package will not request partition information (i.e.  the B<--partition> flag will not be provided to the B<sshare> 
command) even if the B<sshare> command supports it.  In particular, setting this flag might cause the package to forego an extra call to B<sshare>
to determine if the flag is supported.  

=back

For all the lists above, you can give either a list ref or a scalar CSV string.

The B<accounts> argument is converted (if neccessary) to a scalar CSV string and added to the 
argument list of the B<sshare> command with the B<--accounts> flag.  The B<users> argument is handled similarly,
except that if the user list is 'ALL', instead of setting the B<--users> flag the B<-all> flag will be added
to the argument list of the B<sshare> command.

The B<clusters> argument, if given, is handled specially.  For each cluster specified, the B<sshare> command
is invoked with the B<--clusters> argument set to that cluster name (along with any flags from the
B<accounts> and B<users> arguments), and the results for each single cluster
invocation of B<sshare> are parsed separately, and passed the name of the cluster the command was issued to
in order to set the B<cluster> data member.  If the B<clusters> argument is not given, the B<sshare> command
is invoked just once, without any B<--clusters> argument, and the B<cluster> data member will B<NOT> be set
when the output of the B<sshare> command is parsed.

The B<sshare_list> command will raise an exception if called with improper arguments.  On more transient errors
(like the sshare command errored), it will return a non-reference scalar error text.  Otherwise, on success
it returns a (possibly empty) list of B<Slurm::Sshare> instances representing each association the sshare
reported on.  

=head2 The B<combine_tres_hashes>

This takes a pair of hash references, and combines them.  The hash refs are expected to represent
TRES names and values, e.g. values for GrpTRESMins or TRESRunMins.  Like TRES keys in both hashes
are added together; if a key exists in only one of the two hash refs, it is just passed through
(i.e. the missing field in the other hash is treated as a zero).

=head2 The B<combine_sshare_usage_records> method

The Slurm sshare command produces a line of output for each Slurm association meeting the specified
criteria.  Depending on the version of Slurm/sshare command being run, the partition information might
or might not be available to the B<Slurm::Sshare> package (and even if it is available, package 
configuration might prevent its being requested).  Even if partition information I<is> available, it might
not be of interest in certain cases.  Usually in such cases what one is interested is the total usage
statistics over all of a set of related associations.  

The B<combine_sshare_usage_records> method takes a list ref of such B<Slurm::Sshare> records/instances
and returns a hash reference with the combined usage statistics.  The returned hash reference can have
the following keys:

=over 4

=item B<raw_shares>: The total number of raw_shares for all records in the input list.

=item B<normalized_shares>: The total number of normalized_shares for all records in the input list.

=item B<raw_usage>: The total number of raw_usage for all records in the input list.  This is the total number of CPU seconds used by these associations.

=item B<normalized_usage>: The total number of normalized_usage for all records in the input list.

=item B<effective_usage>: The total number of effective_usage for all records in the input list.

=item B<fairshares>: The total number of fairshares for all records in the input list.

=item B<grpcpumins>: The total number of grpcpumins for all records in the input list.  This is in CPU minutes.

=item B<cpurunmins>: The total number of cpurunmins for all records in the input list.  This is the total number of CPU minutes expected to be needed to complete all currently running jobs in these associations.

=item B<grptresmins>: A hash ref representing the account limits on various TRESes.

=item B<tresrunmins>: A hash ref representing the amount of various TRESes estimated to be needed to complete currently running jobs.

=back

At this time, the above fields (except for the TRES hash references B<grptresmins> and B<tresrunmins>) 
are simply summed over the input records.  The TRES hash references are combined with the
method B<combine_tres_hashes>.  This should be the appropriate
handling of the usage fields and the cpurunmins fields; I am less certain about the shares, fairshare,
and grpcpumins fields, but I cannot think of a better way to handle them either.  If a value is missing
or undefined in any of the input records, it does not contribute to the output hash, and indeed, fields
in the output hash can be missing or undefined if they are not defined in any of the input fields.

B<NOTE:> This routine does not do any sanity checking or verification that it makes sense to combine
the records given to it; it blindly combined the usage statistics on all records given trusting that
you know what you are doing.

Although it is typically expected that the input list ref will consist of instances of B<Slurm::Sshare>,
this method will also accept a hash ref with the same fields as the output hash instead of an instance
of B<Slurm::Sshare>.


=head2 The B<collect_usage_records_by_account> method

This method takes a list ref of B<Slurm::Sshare> instances and sorts by cluster, account, and user
to produce a hash ref with usage statistics.  Input parameters should be given as key => value pairs,
with the following keys recognized:

=over 4

=item B<records>: 

the list ref of B<Slurm::Sshare> instances (i.e. records from sshare command) to sort.

=item B<clusters>: 

a list ref of cluster names to include in the results.  If omitted, results will
include data for all clusters referenced in B<records>.  To restrict results to those for records with
cluster undefined, either provide an empty list ref or use either the string 'DEFAULT' or an 
undef as values in the list ref.

=item B<accounts>:

a list ref of account names to include in the results.  If omitted or an empty list ref, results will
include data for all accounts referenced in B<records>.

=item B<users>: 

a list ref of user names to include in the results.  If omitted, results will include data for all 
users referenced in B<records>.

=back

The return value is a hash ref of hash refs.  The outermost hash is keyed on cluster names (with
results corresponding to records for which the cluster is undefined are put under the key C<DEFAULT>).
The values are once again hash refs, this time keyed under the account name.  The values again are
hash refs, with keys giving the account and cluster and usage information for the account (in the
specified cluster).  It may also have a key C<users_hash>, whose value is another hash ref keyed on
usernames, the value being another hash ref giving usage information for that combination of user,
account, and cluster.  E.g., the result would be something like

	$result = 
	{	cluster1 =>
		{	account1 =>
			{	account => 'account1',
				cluster => 'cluster1',
				raw_usage => 777777,
				normalized_usage => .777777,
				...
				users_hash =>
				{	george =>
					{	user => 'george',
						account => 'account1',
						cluster => 'cluster1',
						raw_usage => 111111,
						...
					},
					kevin =>
					{	user => 'kevin',
						account => 'account1',
						cluster => 'cluster1',
						raw_usage => 222222,
						...
					},
					...
				},
			},

			account2 =>
			{	account => 'account2',
				cluster => 'cluster1',
				raw_usage => 1234567,
				...
				users_hash =>
				{	george => { ... },
					kevin =>  { ... },
					...
				}
			},
			...
		},
		cluster2 =>
		{	account1 => 
			{	account => 'account1',
				cluster => 'cluster2',
				...
				users_hash => 
				{	george => { ... },
					...
				},
			},
			account2 => { ... },
			...
		},
		...
	};


The usage hashes for both the account and individual users can contain the following keys:

=over 4

=item B<account>: 

The name of the account.  This should always be present.

=item B<cluster>: 

The name of the cluster.  This will be undefined if the cluster was not specified.

=item B<raw_shares>, B<normalized_shares>, B<raw_usage>, B<normalized_usage>, B<effective_usage>, B<fairshare>, B<grpcpumins>, B<cpurunmins> :

These will represent the same values as given by the corresponding data members of this class.  These
will represent the sum over all partitions if there are multiple records for the specified cluster/account
and/or user.

=item B<grptresmins>, B<tresrunmins>:

These will be hash refs, keyed on TRES type/name.

=back

The usage hashes for individual users will contain the additional key B<user>, whose value will be
the name of the user in question.

The usage hashes for accounts may contain the additional key B<users_hash> whose value is a hash ref
keyed on username with values being the usage hash for that individual user (for that account/cluster).

B<NOTE:> restricting users,accounts, and/or clusters only effectively filters the records in B<records>
being considered.  E.g., the total usage for a given account in a cluster will include usage for all
users of that account, not just the ones in the B<users> list ref.  But the B<usage_hash> will only

=head2 The B<sshare_usage> method

This method combines the B<sshare_list> and B<collect_usage_records_by_account> methods, because it
is expected that the two will generally be used together.  For input, it takes the same key => value
pairs as B<sshare_list> does, namely 

=over 4

=item B<clusters>: 

A list of clusters to issue the B<sshare> command to.  I.e., the B<--clusters> argument to the B<sshare> command.

=item B<accounts>: 

A list of accounts to report on.  The B<--accounts> argument to the B<sshare> command.

=item B<users>: 

A list of users to report on.  The special value B<ALL>, if given as the only user, will result in the B<--all> flag passed to B<sshare>, otherwise this becomes the B<--users> argument to B<sshare>.

=back

It then calls B<collect_usage_records_by_account>, feeding it the results of the B<sshare_list> command,
and returns the result.  The return value is the same as for B<collect_usage_records_by_account>, namely
a hash ref of hash refs for cluster, account, and users.  Note that no arguments restricting the clusters, 
accounts, or users in the results are passed to B<collect_usage_records_by_account>, so only the parameters
passed to B<sshare_list> restrict what is included in the results.

=head2 The B<sshare_usage_for_account> method

This is a convenience method for calling B<sshare_usage> to return data for a specific account (in a
specific cluster).  It takes key => value pairs for its arguments, recognizing the following keys:

=over 4

=item B<account>: 

The name of the account to get usage for.  REQUIRED.

=item B<cluster>: 

The name of the cluster to get usage for.  The sshare default will be used if omitted.

=item B<users>:

A list ref of user names to return data for.  This is passed to the B<users> argument of B<sshare_usage>.
If omitted, data for all users associated with the account will be returned.  Give an empty list ref
(e.g. []) to have no user information returned.

=item B<nowarnings>:

If this boolean value is set to true, warnings about not finding any data for the account will be
suppressed.  By default, if not data for the account is found, a warning will be produced on STDERR.

=back

The return value is the account level hash ref as described in B<collect_usage_records_by_account>.


=head2 The B<sshare_usage_for_account_user>

Like B<sshare_usage_for_account> this is a convenience wrapper around B<sshare_usage>, but this
form returns the usage data for a specific user of an account in a cluster.  It takes key => value 
pairs for input parameters, recognizing:

=over 4

=item B<account>:

The name of the account to get usage for.  REQUIRED.

=item B<user>:

The name of the user to get usage for.  REQUIRED.

=item B<cluster>:

The name of the cluster to get usage for.  The sshare default will be used if omitted.

=item B<nowarnings>:

If this boolean value is set to true, warnings about not finding any data for the account/user will be
suppressed.  By default, if not data for the account and user is found, a warning will be produced on STDERR.

=back

The return value is the user level hash ref (e.g. the value for this username in the B<users_hash> hash
ref) as described in B<collect_usage_records_by_account>.


=head2 The B<usage_for_account_in_cluster> method

B<THIS METHOD IS DEPRECATED>.  Use B<get_usage_for_account_in_cluster> instead, which basically takes the
same arguments and returns the same information (and more) as a hash ref instead of an array ref.

This class method runs and parses the appropriate B<sshare> commands to compute the usage for a specific Slurm
allocation account in a specific cluster.   This makes certain assumptions on how the associations, and limits
for the associations, are defined in Slurm.  It is assumed that there in a given cluster, there is a single
association for the allocation account without an user set, and that the usage limit for the allocation account
is set soley in the B<GrpCPUMins> field of this association.  It is believed that this is a fairly common 
arrangement, but it could fail if, for example, there are associations without an user set for this allocation 
account for specific partitions, with or without B<GrpCPUMins> set on the per-partition associations.  This
assumption also fails if the allocation account has limits imposed on it from parent associations.

The method takes its arguments as key => value pairs, recognizing the following keys:

=over 4

=item B<cluster>:

The name of the cluster to get information for.  The underlying B<sshare_list> command will be directed at
that cluster.  This parameter is REQUIRED.

=item B<account>:

The name of the allocation account to get information for.  This parameter is REQUIRED.

=item B<users>:

This is a list ref of users to return data for.  If omitted or undef, data will be returned for all
users found.  To return data for no user, set this to an empty list ref (e.g. []).

=item B<nowarnings>:

This takes a standard Perl boolean value.  If true, warnings to STDERR for the account not being
found in sshare output are suppressed.  Default is false (display warnings).

=back 

The method will raise a fatal exception on certain errors, mainly for errors related to being invoked 
improperly (e.g. required parameters are missing, invalid data type for users, etc).   For less serious
errors (e.g. the underlying sshare did not succeed), an non-reference scalar error text string will
be returned.  On success, an array reference with the following elements will be returned:

=over 4

=item B<cpusec_used> : 

the total number of cpusecs used by all jobs charged to the specified account/cluster.

=item B<cpumin_limit> : 

the GrpCPUMins limit for this account/cluster (see caveats above).

=item B<cpumin_unused>: 

the difference between B<cpumin_limit> and B<cpusec_used> (in CPU-minutes)

=item B<used_by_username>: 

a hash reference, keyed by username, of the total number of CPU seconds used by jobs in all associations with
the specified account/cluster and username.  If the B<users> array reference was given, it will be restricted
to users in the specified list.

=back

In certain suspicious situations (e.g. no associations for the specified account in the specified cluster
could be found, or some of the assumptions discussed above do not appear to be holding), the method will
try to return a sensible answer, but will generate a warning to STDERR.  E.g., if no assocation for the
account is found, a warning will be generated but data (with all values 0) will be returned.


=head2 The B<usage_for_user_account_in_cluster> method

This class method will invoke the Slurm B<sshare> command to get usage information for a specific user
in a specified allocation account and cluster.  The B<sshare> command will normally return a separate
line for each association associated with this user/account/cluster (i.e., a separate line for each
partition the user is associated with).  This method will sum up the CPU seconds used for this user
over all the associations, and return it.

The method takes its arguments as key => value pairs, recognizing the following keys:

=over 4

=item B<user>: the name of the user to get usage for.  REQUIRED.

=item B<account>: the name of the account to get usage for.  REQUIRED.

=item B<cluster>: the name of the cluster to direct B<sshare> commands at.  REQUIRED.

=item B<nowarnings>: if true, warnings to STDERR are suppressed.  Default is false.

=back

All errors in this routine will result in an exception being raised; this includes errors running the
B<sshare> command.  On success, the sum of the CPU seconds consumed for all associations with the
specified user, account, and cluster will be returned.  On some suspicious cases the method will return
the best value it can get but also print a warning to STDERR (unless nowarnings is set to true).  E.g. if no associations
found for the specified user, account, and cluster, the method will print a warning and return 0 CPU-seconds.

=head2 SLURM/Sshare versions

This package has been used in various forms on version of Slurm going back to about 2.6.
Version 15.x introduced some significant changes impacting the sshare command and this package,
namely

=over 4

=item 1) GrpCPUMins and CPURunMins have been generalized to GrpTRESMins and TRESRunMins.

=item 2) Newer versions of sshare can now show the partition associated with a record

=back

These changes have necessitated some significant changes in the B<Slurm::Sshare> package.  The
parsing of sshare output now can handle output with either GrpCPUMins and CPURunMins or
GrpTRESMins and TRESRunMins.  It can also handle output from sshare either with or without partition information.
By default, the methods invoking sshare commands will attempt to request partition information
if the package believes the sshare command supports such; determining whether the sshare command
supports such is the tricky part.

When the path to the sshare command is set (either through the B<sshare> mutator, or via default settings),
it is possible to tell the package whether the flag for requesting partition information is supported
by that sshare command.  For the B<sshare> mutator, this is done via the optional second explicit argument;
one can provide a hash reference with capibilities of the sshare command as keys and the values indicating
whether the capability is available or not.  The values follow standard Perl boolean semantics, B<EXCEPT>
that an undef value (or a missing key in the hash ref) is interpretted as "unknown" and that the code will
need to determine this on its own if necessary.  If a defined value is given, the code assumes the user knows
what the sshare command can handle, and the code will ignore any evidence to the contrary.  The only "capability"
currently recognized is "can_display_partition", so one can do something like:

	Slurm::Sshare->sshare('/some/path/sshare', { can_display_partition=> 1 } );

to set the path to the sshare command to '/some/path/sshare' and instruct the package that this sshare
command does support the -m or --partition flag to display partition information.  Similarly,

	Slurm::Sshare->sshare('/some/path/sshare', { can_display_partition=> 0 } );

would set the path to the sshare command and instruct the package that is does NOT support that flag.
Alternatively, one can replace the capabilities hash reference with a scalar representing the Slurm
version number, e.g.

	Slurm::Sshare->sshare('/some/path/sshare', '15.08.2');

to set the path and instruct the package that sshare is for Slurm 15.08.2, and has the corresponding capabilities.
Omitting the hash ref (or providing an empty hash reference or one for which the value of the can_display_partition
field is undefined) will set the path to sshare but require the package to figure out whether the partition flag is
supported.

The method B<set_sshare_capabilities_by_version($SLURM_VERSION_NUMBER)> will set the current capabilities hash
based on the specified Slurm version number.

System administrators can change the default used for the sshare command by changing the B<$SSHARE_CMD> variable
at the top of this file; at the same time they can modify B<$SSHARE_CMD_CAPABILITIES> to a hash ref providing the
capabilities of the sshare command being used. (Or instead of directly setting B<$SSHARE_CMD_CAPABILITIES>, you
can invoke B<set_sshare_capabilities_by_version> with the appropriate version number).   We recommend that
system administrators set both the path and version appropriately.  By default, whatever sshare is found
in the user's path is used, and the package needs to determine what capabilities it has.  

The capabilities of the sshare command (and all cached knowledge about such) is cleared whenever the B<sshare> method
is called with a path (even if the path is the same as has been previously used).

If the package needs to determine the capabilities of the sshare command, it does so lazily.  E.g., if all calls to
B<sshare_list> (direct or indirect) have the B<nopartinfo> argument set, the code does not need to know if sshare can
handle the B<--partition> flag, and so it does not need to invoke a separate sshare command to discover this.  Furthermore,
since the displaying of GrpTRESMins instead of GrpCPUMins (is believed to have) occurred at the same time, the code
to parse sshare output will use that to silently cache whether the command supports the partition flag.  Only if actually
necessary will the package silently issue an sshare command to determine this fact (currently it bases such on the
output of the C<sshare --help> command).  

The class method B<sshare_cmd_supports> allows one to query the capabilities of the current sshare command.  It takes
one explicit required parameter, the name of the capability being queried (currently, only 'can_display_partition' is
supported), and an optional boolean variable.  If this optional variable is true, only cached results will be used,
and the method will not invoke sshare to discover the capabilities.  If omitted or false, the method will invoke sshare
to discover its capabilities as described above if needed.  The return value is 1 (true) if the sshare command supports
the named capability, 0 (false) if it does not, or undef (false) if it is not known.  This last case can only occur if
the optional boolean parameter was set to true.

It is hoped that this approach will allow for a solution to this current difference in version as well as being robust
enough to adapt to future changes in Slurm.

=head2 EXPORT

None.  OO interface only.

=head1 SEE ALSO

Slurmdb

Slurm::Sacctmgr

=head1 AUTHOR

Tom Payerle, payerle@umd.edu

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014-2016 by the University of Maryland

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

