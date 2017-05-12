
package PBS::PBSConfig ;
use PBS::Debug ;

use 5.006 ;
use strict ;
use warnings ;
use Data::Dumper ;
use Data::TreeDumper ;
use File::Spec::Functions qw(:ALL) ;

require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw(GetPbsConfig GetBuildDirectory GetSourceDirectories CollapsePath PARSE_SWITCHES_IGNORE_ERROR PARSE_PRF_SWITCHES_IGNORE_ERROR) ;
our $VERSION = '0.03' ;

use Getopt::Long ;
use Pod::Parser ;
use Cwd ;
use File::Spec;

use PBS::Output ;
use PBS::Log ;
use PBS::Constants ;
use PBS::PBSConfigSwitches ;

#-------------------------------------------------------------------------------

my %pbs_configuration ;

sub RegisterPbsConfig
{
my $package  = shift ;
my $configuration= shift ;

if(ref $configuration eq 'HASH')
	{
	$pbs_configuration{$package} = $configuration;
	}
else
	{
	PrintError("RegisterPbsConfig: switches are to be encapsulated within a hash reference!\n") ;
	}
}

#-------------------------------------------------------------------------------

sub GetPbsConfig
{
my $package  = shift || caller() ;

if(defined $pbs_configuration{$package})
	{
	return($pbs_configuration{$package}) ;
	}
else
	{
	PrintError("GetPbsConfig: no configuration for package '$package'! Returning empty set.\n") ;
	Carp::confess ;
	return({}) ;
	}
}

#-------------------------------------------------------------------------------

sub GetBuildDirectory
{
my $package  = shift || caller() ;

if(defined $pbs_configuration{$package})
	{
	return($pbs_configuration{$package}{BUILD_DIRECTORY}) ;
	}
else
	{
	PrintError("GetBuildDirectory: no configuration for package '$package'! Returning empty string.\n") ;
	Carp::confess ;
	return('') ;
	}
}

#-------------------------------------------------------------------------------

sub GetSourceDirectories
{
my $package  = shift || caller() ;

if(defined $pbs_configuration{$package})
	{
	return([@{$pbs_configuration{$package}{SOURCE_DIRECTORIES}}]) ;
	}
else
	{
	PrintError("GetSourceDirectories: no configuration for package '$package'! Returning empty list.\n") ;
	Carp::confess ;
	return([]) ;
	}
}

#-------------------------------------------------------------------------------

use constant PARSE_SWITCHES_IGNORE_ERROR => 1 ;

sub ParseSwitches
{
my ($pbs_config, $switches_to_parse, $ignore_error) = @_ ;
$pbs_config ||= {} ;

my $success_message = '' ;

local @ARGV = ( # default colors
		  '-ci'  => 'green'
		, '-ci2' => 'bold blue'
		, '-cw'  => 'yellow'
		, '-cw2' => 'bold yellow'
		, '-ce'  => 'red'
		, '-cd'  => 'magenta'
		, '-cs'  => 'bold green'
		, '-cu'  => 'cyan'
		) ;
		
Getopt::Long::Configure('no_auto_abbrev', 'no_ignore_case', 'require_order') ;

my @flags = PBS::PBSConfigSwitches::Get_GetoptLong_Data($pbs_config) ;
unless(GetOptions(@flags))
	{
	return([0, "Error in default colors configuration." . __FILE__ . ':' . __LINE__ . "\n"], $pbs_config, @ARGV) ;
	}

@ARGV = @$switches_to_parse ;

# tweek option parsing so we can mix switches with targets
my $contains_switch ;
my @targets ;

do
	{
	while(@ARGV && $ARGV[0] !~ /^-/)
		{
		#~ print "target => $ARGV[0] \n" ;
		push @targets, shift @ARGV ;
		}
		
	$contains_switch = @ARGV ;
	
	local $SIG{__WARN__} 
		= sub 
			{
			PrintWarning $_[0] unless $ignore_error ;
			} ;
			
	unless(GetOptions(@flags))
		{
		return(0, "Try perl pbs.pl -h.\n", $pbs_config, @ARGV) unless $ignore_error;
		}
	}
while($contains_switch) ;

$pbs_config->{TARGETS} = \@targets ;
 
return(1, $success_message, $pbs_config) ;
}

#-------------------------------------------------------------------------------

sub GetUserName
{
my $user = 'no_user_set' ;

if(defined $ENV{USER} && $ENV{USER} ne '')
	{
	$user = $ENV{USER} ;
	}
elsif(defined $ENV{USERNAME} && $ENV{USERNAME} ne '')
	{
	$user = $ENV{USERNAME} ;
	}
	
return($user) ;
}

#-------------------------------------------------------------------------------

sub CheckPbsConfig
{
my $pbs_config = shift ;

my $success_message = '' ;

#force options
$pbs_config->{DISPLAY_PROGRESS_BAR}++ ;
$pbs_config->{DISPLAY_COMPACT_DEPEND_INFORMATION}++ ;

# check the options
if(defined $pbs_config->{DISPLAY_DEPENDENCY_INFO})
	{
	delete $pbs_config->{DISPLAY_COMPACT_DEPEND_INFORMATION} ;
	}
	
#~ use Data::Validate::IP qw(is_ipv4 is_loopback_ipv4);
#~ if(exists $pbs_config{LIGHT_WEIGHT_FORK})
	#~ {
	#~ my ($server, $port) = split(':', $pbs_config->{LIGHT_WEIGHT_FORK}) ;
	
	#~ unless(is_ipv4($server) || is_loopback_ipv4($server))
		#~ {
		#~ die ERROR "Error: IP error '$pbs_config->{LIGHT_WEIGHT_FORK}' to -ubs\n" ;
		#~ }
	#~ }
	
# segmentation fault because of missing ':' and use statement placement.
#~ if(exists $pbs_config->{LIGHT_WEIGHT_FORK})
	#~ {
	#~ my ($server, $port) = split(':', $pbs_config->{LIGHT_WEIGHT_FORK}) ;
	#~ use Net:IP ;
	#~ my $ip = new Net::IP ($server) or die ERROR 'Error: invalid IP given to -ubs' ;
	#~ }
	
if(defined $pbs_config->{DISPLAY_COMPACT_DEPEND_INFORMATION})
	{
	$pbs_config->{NO_SUBPBS_INFO}++ ;
	}
	
if(defined $pbs_config->{DISPLAY_NO_PROGRESS_BAR})
	{
	delete $pbs_config->{DISPLAY_PROGRESS_BAR} ;
	}
	
if(defined $pbs_config->{DISPLAY_PROGRESS_BAR})
	{
	$PBS::Shell::silent_commands++ ;
	$PBS::Shell::silent_commands_output++ ;
	$pbs_config->{DISPLAY_NO_BUILD_HEADER}++ ;
	}
	
if(defined $pbs_config->{NO_WARP})
	{
	$pbs_config->{WARP} = 0 ;
	}
else
	{
	unless(defined $pbs_config->{WARP})
		{
		$pbs_config->{WARP} = 1.5 ;
		}
	}

if(defined $pbs_config->{DISPLAY_PBS_TIME})
	{
	$pbs_config->{DISPLAY_PBS_TOTAL_TIME}++ ;
	$pbs_config->{DISPLAY_TOTAL_BUILD_TIME}++ ;
	$pbs_config->{DISPLAY_TOTAL_DEPENDENCY_TIME}++ ;
	$pbs_config->{DISPLAY_CHECK_TIME}++ ;
	$pbs_config->{DISPLAY_WARP_TIME}++ ;
	}

if($pbs_config->{DISPLAY_DEPENDENCY_TIME})
	{
	$pbs_config->{DISPLAY_TOTAL_DEPENDENCY_TIME}++ ;
	}

if($pbs_config->{NO_SUBPBS_INFO} || $pbs_config->{DISPLAY_COMPACT_DEPEND_INFORMATION})
	{
	undef $pbs_config->{DISPLAY_DEPENDENCY_TIME} ;
	}

if($pbs_config->{TIME_BUILDERS})
	{
	$pbs_config->{DISPLAY_TOTAL_BUILD_TIME}++ ;
	}

$pbs_config->{DISPLAY_PBSUSE_TIME}++ if(defined $pbs_config->{DISPLAY_PBSUSE_TIME_ALL}) ;

$pbs_config->{DISPLAY_HELP}++ if defined $pbs_config->{DISPLAY_HELP_NARROW_DISPLAY} ;

$pbs_config->{DEBUG_DISPLAY_RULES}++ if defined $pbs_config->{DEBUG_DISPLAY_RULE_DEFINITION} ;

$pbs_config->{DISPLAY_USED_RULES}++ if defined $pbs_config->{DISPLAY_USED_RULES_NAME_ONLY} ;
	
$pbs_config->{DEBUG_DISPLAY_DEPENDENCIES}++ if defined $pbs_config->{DEBUG_DISPLAY_DEPENDENCY_RULE_DEFINITION} ;
$pbs_config->{DEBUG_DISPLAY_DEPENDENCIES}++ if defined $pbs_config->{DEBUG_DISPLAY_DEPENDENCIES_LONG} ;

if(@{$pbs_config->{DISPLAY_DEPENDENCIES_REGEX}})
	{
	$pbs_config->{DEBUG_DISPLAY_DEPENDENCIES}++ ;
	}
else
	{
	push @{$pbs_config->{DISPLAY_DEPENDENCIES_REGEX}}, '.*' ;
	}

$pbs_config->{DEBUG_DISPLAY_TRIGGER_INSERTED_NODES} = undef if(defined $pbs_config->{DEBUG_DISPLAY_DEPENDENCIES}) ;

$pbs_config->{DISPLAY_DIGEST}++ if defined $pbs_config->{DISPLAY_DIFFERENT_DIGEST_ONLY} ;


$pbs_config->{DISPLAY_SEARCH_INFO}++ if defined $pbs_config->{DISPLAY_SEARCH_ALTERNATES} ;

if(defined $pbs_config->{BUILD_AND_DISPLAY_NODE_INFO} || @{$pbs_config->{DISPLAY_BUILD_INFO}} || @{$pbs_config->{DISPLAY_NODE_INFO}})
	{
	undef $pbs_config->{BUILD_AND_DISPLAY_NODE_INFO} if (@{$pbs_config->{DISPLAY_BUILD_INFO}}) ;
	
	$pbs_config->{DISPLAY_NODE_ORIGIN}++ ;
	$pbs_config->{DISPLAY_NODE_DEPENDENCIES}++ ;
	$pbs_config->{DISPLAY_NODE_BUILD_CAUSE}++ ;
	$pbs_config->{DISPLAY_NODE_BUILD_RULES}++ ;
	$pbs_config->{DISPLAY_NODE_BUILDER}++ ;
	$pbs_config->{DISPLAY_NODE_BUILD_POST_BUILD_COMMANDS}++ ;
	
	undef $pbs_config->{DISPLAY_NO_BUILD_HEADER} ;
	}
	
# ------------------------------------------------------------------------------

$pbs_config->{GENERATE_TREE_GRAPH_DISPLAY_ROOT_BUILD_DIRECTORY} = undef if(defined $pbs_config->{GENERATE_TREE_GRAPH_DISPLAY_BUILD_DIRECTORY}) ;

$pbs_config->{GENERATE_TREE_GRAPH_DISPLAY_CONFIG}++ if(defined $pbs_config->{GENERATE_TREE_GRAPH_DISPLAY_CONFIG_EDGE}) ;
$pbs_config->{GENERATE_TREE_GRAPH_DISPLAY_PBS_CONFIG}++ if(defined $pbs_config->{GENERATE_TREE_GRAPH_DISPLAY_PBS_CONFIG_EDGE}) ;

for my $cluster_node_regex (@{$pbs_config->{GENERATE_TREE_GRAPH_CLUSTER_NODE}})
	{
	#~ print "$cluster_node_regex " ;
	
	$cluster_node_regex = './' . $cluster_node_regex unless ($cluster_node_regex =~ /^\.|\//) ;
	$cluster_node_regex =~ s/\./\\./g ;
	$cluster_node_regex =~ s/\*/.*/g ;
	$cluster_node_regex = '^' . $cluster_node_regex . '$' ;
	
	#~ print "=> $cluster_node_regex\n" ;
	}

for my $exclude_node_regex (@{$pbs_config->{GENERATE_TREE_GRAPH_EXCLUDE}})
	{
	#~ print "$exclude_node_regex => " ;
	$exclude_node_regex =~ s/\./\\./g ;
	$exclude_node_regex =~ s/\*/.\*/g ;
	#~ print "$exclude_node_regex\n" ;
	}

for my $include_node_regex (@{$pbs_config->{GENERATE_TREE_GRAPH_INCLUDE}})
	{
	#~ print "$include_node_regex => " ;
	$include_node_regex =~ s/\./\\./g ;
	$include_node_regex =~ s/\*/.\*/g ;
	#~ print "$include_node_regex\n" ;
	}
	
#-------------------------------------------------------------------------------
# build or not switches
if($pbs_config->{NO_BUILD} && $pbs_config->{FORCE_BUILD})
	{
	return(0, "-force_build and -no_build switch can't be given simulteanously\n") ;
	}
	
$pbs_config->{DO_BUILD} = 0 if $pbs_config->{NO_BUILD} ;

unless($pbs_config->{FORCE_BUILD})
	{
	while(my ($debug_flag, $value) = each %$pbs_config) 
		{
		if($debug_flag =~ /^DEBUG/ && defined $value)
			{
			$pbs_config->{DO_BUILD} = 0 ;
			keys %$pbs_config;
			last ;
			}
		}
	}
#-------------------------------------------------------------------------------

$pbs_config->{DISPLAY_DIGEST}++ if $pbs_config->{DISPLAY_DIFFERENT_DIGEST_ONLY} ;

$pbs_config->{DISPLAY_FILE_LOCATION}++ if $pbs_config->{DISPLAY_ALL_FILE_LOCATION} ;
$pbs_config->{DEBUG_DISPLAY_BUILD_SEQUENCE}++ if defined $pbs_config->{DEBUG_DISPLAY_BUILD_SEQUENCE_NAME_ONLY} ;

$Data::Dumper::Maxdepth = $pbs_config->{MAX_DEPTH} if defined $pbs_config->{MAX_DEPTH} ;
$Data::Dumper::Indent   = $pbs_config->{INDENT_STYLE} if defined $pbs_config->{INDENT_STYLE} ;

if(defined $pbs_config->{DISTRIBUTE} && ! defined $pbs_config->{JOBS})
	{
	$pbs_config->{JOBS} = 0 ; # let distributor determine how many jobs
	}

if(defined $pbs_config->{JOBS} && $pbs_config->{JOBS} < 0)
	{
	return(0, "Invalid value '$pbs_config->{JOBS}' for switch -j/-jobs\n") ;
	}
	
if(defined $pbs_config->{DEBUG_DISPLAY_TREE_NODE_TRIGGERED_REASON})
	{
	$pbs_config->{DEBUG_DISPLAY_TREE_NODE_TRIGGERED} = 1 ;
	}

if(defined $pbs_config->{DEBUG_DISPLAY_TREE_NAME_ONLY})
	{
	$pbs_config->{DEBUG_DISPLAY_TEXT_TREE} = '' unless $pbs_config->{DEBUG_DISPLAY_TEXT_TREE} ;
	}
	
if(defined $pbs_config->{DISPLAY_TEXT_TREE_USE_ASCII})
	{
	$pbs_config->{DISPLAY_TEXT_TREE_USE_ASCII} = 1 ;
	}
else
	{
	$pbs_config->{DISPLAY_TEXT_TREE_USE_ASCII} = 0 ;
	}

$pbs_config->{DISPLAY_TEXT_TREE_MAX_DEPTH} = -1 unless defined $pbs_config->{DISPLAY_TEXT_TREE_MAX_DEPTH} ;

#--------------------------------------------------------------------------------

$Data::TreeDumper::Startlevel = 1 ;
$Data::TreeDumper::Useascii   = $pbs_config->{DISPLAY_TEXT_TREE_USE_ASCII} ;
$Data::TreeDumper::Maxdepth   = $pbs_config->{DISPLAY_TEXT_TREE_MAX_DEPTH} ;

#--------------------------------------------------------------------------------

my ($pbsfile, $error_message) = GetPbsfileName($pbs_config) ;

return(0, $error_message) unless defined $pbsfile ;

$pbs_config->{PBSFILE} = $pbsfile ;
$pbs_config->{PBSFILE} = './' . $pbs_config->{PBSFILE} unless $pbs_config->{PBSFILE}=~ /^\.|\// ;

#--------------------------------------------------------------------------------

my $cwd = getcwd() ;
if(0 == @{$pbs_config->{SOURCE_DIRECTORIES}})
	{
	push @{$pbs_config->{SOURCE_DIRECTORIES}}, $cwd ;
	}

for my $plugin_path (@{$pbs_config->{PLUGIN_PATH}})
	{
	unless(file_name_is_absolute($plugin_path))
		{
		$plugin_path = catdir($cwd, $plugin_path)  ;
		}
		
	$plugin_path = PBS::PBSConfig::CollapsePath($plugin_path ) ;
	}
	
unless(defined $pbs_config->{BUILD_DIRECTORY})
	{
	if(defined $pbs_config->{MANDATORY_BUILD_DIRECTORY})
		{
		return(0, "No Build directory given and --mandatory_build_directory set.\n") ;
		}
	else
		{
		$pbs_config->{BUILD_DIRECTORY} = $cwd . "/out_" . GetUserName() ;
		}
	}

if(defined $pbs_config->{LIB_PATH})
	{
	for my $lib_path (@{$pbs_config->{LIB_PATH}})
		{
		$lib_path .= '/' unless $lib_path =~ /\/$/ ;
		}
	}

# compute a signature for the current PBS run
# check if a signature exists in the output directory
# OK if the signatures match
# on mismatch, ask for another output directory or force override

CheckPackageDirectories($pbs_config) ;

#----------------------------------------- Log -----------------------------------------
undef $pbs_config->{CREATE_LOG} if defined $pbs_config->{DISPLAY_LAST_LOG} ;

PBS::Log::CreatePbsLog($pbs_config) if(defined $pbs_config->{CREATE_LOG}) ;


return(1, $success_message) ;
}

#-------------------------------------------------------------------------------

my $parse_prf_switches_run = 0 ; # guaranty we load stuff in the right package

use constant PARSE_PRF_SWITCHES_IGNORE_ERROR => 1 ;

sub ParsePrfSwitches
{
my ($no_anonymous_pbs_response_file, $pbs_response_file_to_use, $load_package, $ignore_error) = @_ ; # reference to the config in the PBS namespace

my $package = caller() ;
my $prf_load_package = 'PBS_PRF_SWITCHES_' . $package . '_' . $parse_prf_switches_run ;

if(defined $load_package)
	{
	$prf_load_package = $load_package ;
	}
else
	{
	# we load the prf in its own namespace
	PBS::PBSConfig::RegisterPbsConfig($prf_load_package, {}) ;
	}
	
my $pbs_response_file ;
unless($no_anonymous_pbs_response_file)
	{
	$pbs_response_file = 'pbs.prf' if(-e 'pbs.prf') ;
	}

my $user = GetUserName() ;

$pbs_response_file = "$user.prf" if(-e "$user.prf") ;
$pbs_response_file =  $pbs_response_file_to_use if(defined $pbs_response_file_to_use) ;

if($pbs_response_file)
	{
	unless(-e $pbs_response_file)
		{
		die ERROR "Error! Can't find prf '$pbs_response_file'." ;
		}
		
	PBS::PBSConfig::RegisterPbsConfig($prf_load_package, {PRF_IGNORE_ERROR => $ignore_error}) ;
	
	use PBS::PBS;
	PBS::PBS::LoadFileInPackage
		(
		  'Pbsfile' # $type
		, $pbs_response_file
		, $prf_load_package
		, {} #$pbs_config
		, "use PBS::Prf ;\n" #$pre_code
		 ."use PBS::Output ;\n"
		, '' #$post_code
		) ;

	my $pbs_config = GetPbsConfig($prf_load_package) ;
	delete $pbs_config->{PRF_IGNORE_ERROR} ;
	
	return($pbs_response_file, $pbs_config) ;
	}
else
	{
	return('no prf defined', {}) ;
	}
}

#-------------------------------------------------------------------------------

sub GetPbsfileName
{
my $pbs_config = shift ;

my $pbsfile = '' ;
my $error_message = '' ;

if(defined $pbs_config->{PBSFILE})
	{
	$pbsfile = $pbs_config->{PBSFILE} ;
	}
else
	{
	my @pbsfile_names;
	if($^O eq 'MSWin32')
		{
		@pbsfile_names = qw(pbsfile.pl pbsfile) ;
		}
	else
		{
		@pbsfile_names = qw(Pbsfile.pl pbsfile.pl Pbsfile pbsfile) ;
		}

	my %existing_pbsfile = map{( $_ => 1)} grep { -e "./$_"} @pbsfile_names ;
	
	if(keys %existing_pbsfile)
		{
		if(keys %existing_pbsfile == 1)
			{
			($pbsfile) = keys %existing_pbsfile ;
			}
		else
			{
			$error_message = "PBS has found the following Pbsfiles:\n" ;
			
			for my $found_pbsfile (keys %existing_pbsfile)
				{
				$error_message .= "\t$found_pbsfile\n" ;
				}
				
			$error_message .= "Only one can be defined!\n" ;
			}
		}
	else
		{
		$error_message = "No 'Pbsfile' to define build.\n" ;
		}
	}

return($pbsfile, $error_message) ;
}

#-------------------------------------------------------------------------------

sub CollapsePath
{
#remove '.' and '..' from a path

my $collapsed_path = shift ;

#~ PrintDebug $collapsed_path  ;

$collapsed_path =~ s~(?<!\.)\./~~g ;
$collapsed_path =~ s~/\.$~~ ;

1 while($collapsed_path =~ s~[^/]+/\.\./~~) ;
$collapsed_path =~ s~[^/]+/\.\.$~~ ;

# remove double separators
$collapsed_path =~ s~\/+~\/~g ;

# collaps to root
$collapsed_path =~ s~^/(\.\./)+~/~ ;

#remove trailing '/'
$collapsed_path =~ s~/$~~ unless $collapsed_path eq '/' ;

#~ PrintDebug " => $collapsed_path\n"  ;

return($collapsed_path) ;
}

#-------------------------------------------------------------------------------

sub CheckPackageDirectories
{
my $pbs_config = shift ;

my $cwd = getcwd() ;

if(defined $pbs_config->{SOURCE_DIRECTORIES})
	{
	for my $source_directory (@{$pbs_config->{SOURCE_DIRECTORIES}})
		{
		unless(file_name_is_absolute($source_directory))
			{
			$source_directory = catdir($cwd, $source_directory) ;
			}
			
		$source_directory = CollapsePath($source_directory) ;
		}
	}
	
if(defined $pbs_config->{BUILD_DIRECTORY})
{
	unless(file_name_is_absolute($pbs_config->{BUILD_DIRECTORY}))
		{
		$pbs_config->{BUILD_DIRECTORY} = catdir($cwd, $pbs_config->{BUILD_DIRECTORY}) ;
		}
		
	$pbs_config->{BUILD_DIRECTORY} = CollapsePath($pbs_config->{BUILD_DIRECTORY}) ;
	}
}

#-------------------------------------------------------------------------------

1 ;

#-------------------------------------------------------------------------------

__END__
=head1 NAME

PBS::PBSConfig - Handles PBS configuration

=head1 DESCRIPTION

Every loaded package has a configuration. The first configuration, loaded
through the I<pbs> utility is stored in the 'PBS' package and is influenced by I<pbs> command line switches.
Subsequent configurations are loaded when a subpbs is run. The configuration name and contents reflect the loaded package parents
and the subpbs configuration.

I<GetPbsConfig> can be used (though not recommended), in Pbsfiles, to get the current pbs configuration. The configuration name is __PACKAGE__.
The returned scalaris a reference to the configuration hash.

	# in a Pbsfile
	use Data::TreeDumper ;
	
	my $pbs_config = GetPbsConfig(__PACKAGE__) ;
	PrintInfo(DumpTree( $pbs_config->{SOURCE_DIRECTORIES}, "Source directories")) ;

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=cut
