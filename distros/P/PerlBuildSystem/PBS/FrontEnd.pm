
package PBS::FrontEnd ;
use PBS::Debug ;

use 5.006 ;
use strict ;
use warnings ;
use Data::Dumper ;
use Data::TreeDumper ;
use Carp ;
use Time::HiRes qw(gettimeofday tv_interval) ;
use Module::Util qw(find_installed) ;
use File::Spec::Functions qw(:ALL) ;

require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw() ;
our $VERSION = '0.44' ;

use PBS::Config ;
use PBS::PBSConfig ;
use PBS::PBS ;
use PBS::Output ;
use PBS::Constants ;
use PBS::Documentation ;
use PBS::Plugin ;
use PBS::Warp ;

#-------------------------------------------------------------------------------

my $pbs_run_index = 0 ; # depth of the PBS run
my $display_pbs_run ;

sub Pbs
{
my $t0 = [gettimeofday];

my (%pbs_arguments) = @_ ;

PBS::PBSConfig::RegisterPbsConfig('PBS', {}) ;
my $pbs_config = GetPbsConfig('PBS') ; # a reference to the PBS namespace config
$pbs_config->{ORIGINAL_ARGV} = join(' ', @ARGV) ;

my ($switch_parse_ok, $parse_message) = ParseSwitchesAndLoadPlugins($pbs_config, $pbs_arguments{COMMAND_LINE_ARGUMENTS}) ;
my ($targets) = $pbs_config->{TARGETS} ;

if($pbs_config->{DISPLAY_LIB_PATH})
	{
	print join(':', @{$pbs_config->{LIB_PATH}}) ;
	return(1) ;
	}

if($pbs_config->{DISPLAY_PLUGIN_PATH})
	{
	print join(':', @{$pbs_config->{PLUGIN_PATH}}) ;
	return(1) ;
	}

if($pbs_config->{GENERATE_BASH_COMPLETION_SCRIPT})
	{
	PBS::PBSConfigSwitches::GenerateBashCompletionScript() ;
	return(1) ;
	}

# override with callers pbs_config
if(exists $pbs_arguments{PBS_CONFIG})
	{
	$pbs_config = {%$pbs_config, %{$pbs_arguments{PBS_CONFIG}} } ;
	}

$pbs_config->{PBSFILE_CONTENT} = $pbs_arguments{PBSFILE_CONTENT} if exists $pbs_arguments{PBSFILE_CONTENT} ;

my $display_help              = $pbs_config->{DISPLAY_HELP} ;
my $display_switch_help       = $pbs_config->{DISPLAY_SWITCH_HELP} ;
my $display_help_narrow       = $pbs_config->{DISPLAY_HELP_NARROW_DISPLAY} || 0 ;
my $display_version           = $pbs_config->{DISPLAY_VERSION} ;
my $display_pod_documentation = $pbs_config->{DISPLAY_POD_DOCUMENTATION} ;

if($display_help || $display_switch_help || $display_version || defined $display_pod_documentation)
	{
	PBS::PBSConfigSwitches::DisplayHelp($display_help_narrow) if $display_help ;
	PBS::PBSConfigSwitches::DisplaySwitchHelp($display_switch_help) if $display_switch_help ;
	DisplayVersion() if $display_version ;
	
	PBS::Documentation::DisplayPodDocumentation($pbs_config, $display_pod_documentation) if defined $display_pod_documentation ;
	
	return(1) ;
	}
	
if(defined $pbs_config->{DISPLAY_LAST_LOG})
	{
	PBS::Log::DisplayLastestLog($pbs_config->{DISPLAY_LAST_LOG}) ;
	return(1) ;
	}

if(defined $pbs_config->{WIZARD})
	{
	eval "use PBS::Wizard;" ;
	die $@ if $@ ;

	PBS::Wizard::RunWizard
		(
		  $pbs_config->{LIB_PATH}
		, undef
		, $pbs_config->{WIZARD}
		, $pbs_config->{DISPLAY_WIZARD_INFO}
		, $pbs_config->{DISPLAY_WIZARD_HELP}
		) ;
		
	return(1) ;
	}

# Get the Pbsfile name,  cases above diddn't need it and we disn't want any "no pbsfile to defined  the build" to be (eventually) displayed
my ($pbsfile, $error_message) = PBS::PBSConfig::GetPbsfileName($pbs_config) ;
PrintError $error_message unless defined $pbsfile && $pbsfile ne '' ;

my $display_user_help        = $pbs_config->{DISPLAY_PBSFILE_POD} ;
my $extract_pod_from_pbsfile = $pbs_config->{PBS2POD} ;

if($display_user_help || $extract_pod_from_pbsfile)
	{
	PBS::PBSConfigSwitches::DisplayUserHelp($pbsfile , $display_user_help, $pbs_config->{RAW_POD}) ;
	return(1) ;
	}

#-------------------------------------------------------------------------------------------
# run PBS
#-------------------------------------------------------------------------------------------

# verify config first
my ($pbs_config_ok, $pbs_config_message) = PBS::PBSConfig::CheckPbsConfig($pbs_config) ;
return(0, $pbs_config_message) unless $pbs_config_ok ;

unless($switch_parse_ok)
	{
	# defered to get a chance to display PBS help
	return(0, $parse_message) ;
	}
	

$display_pbs_run++ if defined $pbs_config->{DISPLAY_PBS_RUN} ;
PrintInfo2 "** PBS run $pbs_run_index **\n" if $display_pbs_run ;

if(defined $pbs_config->{CREATE_LOG})
	{
	my $lh = $pbs_config->{CREATE_LOG} ;
	print $lh "** PBS run $pbs_run_index **\n";
	}

$pbs_run_index++ ;

print $parse_message ;

for my $target (@$targets)
	{
	if($target =~ /^\@/ || $target =~ /\@$/ || $target =~ /\@/ > 1)
		{
		die "Invalid composite target definition\n" ;
		}

	if($target =~ /@/)
		{
		die "Only one composite target allowed\n" if @$targets > 1 ;
		}
	}
	
$targets =
	[
	map
		{
		my $target = $_ ;
		
		$target = $_ if file_name_is_absolute($_) ; # full path
		$target = $_ if /^.\// ; # current dir (that's the build dir)
		$target = "./$_" unless /^[.\/]/ ;
		
		$target ;
		} @$targets
	] ;


$pbs_config->{PACKAGE} = 'PBS' ; #hmm, should be unique

# make the variables below accessible from a post pbs script
our $build_success = 1 ;
my ($build_result, $build_message) ;
our ($dependency_tree, $inserted_nodes) = ({}, {}) ;

my $parent_config = $pbs_config->{LOADED_CONFIG} || {} ;

if(@$targets)
	{
	$DB::single = 1 ;

	eval
		{
		($build_result, $build_message, $dependency_tree, $inserted_nodes)
			= PBS::Warp::WarpPbs($targets, $pbs_config, $parent_config) ;
		} ;
		
	if($@)
		{
		print STDERR $@ ;
		}
		
	$build_result = BUILD_FAILED unless defined  $build_result;
	
	$build_success = 0 if($@ || ($build_result != BUILD_SUCCESS)) ;

	}
else
	{
	PrintError("No targets given on the command line!\n") ;
	PBS::PBSConfigSwitches::DisplayUserHelp($pbsfile , 1, 0) ;
		
	$build_success = 0 ;
	}

$pbs_run_index-- ;
PrintInfo2 "** PBS run $pbs_run_index Done **\n" if $display_pbs_run ;

if(defined $pbs_config->{CREATE_LOG})
	{
	my $lh = $pbs_config->{CREATE_LOG} ;
	print $lh "** PBS run $pbs_run_index Done **\n";
	}

# move all stat into a variable accessible in from a pbs file and all
# the displaying into a plugin

if($pbs_config->{CHECK_DEPENDENCIES_AT_BUILD_TIME})
	{
	my $skip_statistics = PBS::Build::NodeBuilder::GetBuildTimeSkippStatistics() ;
	
	PrintInfo "Build time check: $skip_statistics->{CHECK_DEPENDENCIES} nodes, " 
		. "skipped: $skip_statistics->{SKIPPED_BUILDS} nodes ($skip_statistics->{SKIPP_RATIO}%)\n" ;

	$PBS::pbs_run_information->{SKIP_STATISTICS} = $skip_statistics  ;
	}
	
if($pbs_config->{DISPLAY_MD5_STATISTICS})
	{
	my $md5_statistics = PBS::Digest::Get_MD5_Statistics() ;
	
	PrintInfo "MD5 requests: $md5_statistics->{TOTAL_MD5_REQUESTS}"
		. "("
		. "cached requests: $md5_statistics->{CACHED_REQUESTS}"
		.", non cached requests: $md5_statistics->{NON_CACHED_REQUESTS}" 
		."), " 
		. "cache hits: $md5_statistics->{CACHE_HITS} ($md5_statistics->{MD5_CACHE_HIT_RATIO}%)\n" ;
		
	$PBS::pbs_run_information->{MD5_STATISTICS} = $md5_statistics ;
	}

if($pbs_config->{DISPLAY_PBS_TOTAL_TIME})
	{
	my $total_time_in_pbs = tv_interval ($t0, [gettimeofday]) ;
	PrintInfo(sprintf("Total time in PBS: %0.2f s.\n", $total_time_in_pbs)) ;
	
	$PBS::pbs_run_information->{TOTAL_TIME_IN_PBS} = $total_time_in_pbs
	}

RunPluginSubs($pbs_config, 'PostPbs', $build_success, $pbs_config, $dependency_tree, $inserted_nodes) ;

my $run = 0 ;
for my $post_pbs (@{$pbs_config->{POST_PBS}})
	{
	$run++ ;
	
	eval
		{
		PBS::PBS::LoadFileInPackage
			(
			''
			, $post_pbs
			, "PBS::POST_PBS_$run"
			, $pbs_config
			, "use strict ;\nuse warnings ;\n"
			  . "use PBS::Output ;\n"
			  . "my \$pbs_config = \$pbs_config ;\n"
			  . "my \$build_success = \$PBS::FrontEnd::build_success ;\n"
			  . "my \$dependency_tree = \$PBS::FrontEnd::dependency_tree ;\n"
			  . "my \$inserted_nodes = \$PBS::FrontEnd::inserted_nodes ; \n"
			  . "my \$pbs_run_information = \$PBS::pbs_run_information ; \n"
			) ;
		} ;

	PrintError("Couldn't run post pbs script '$post_pbs':\n   $@") if $@ ;
	}

return($build_success, 'PBS run ' . ($pbs_run_index + 1) . " building '@$targets' with '$pbs_config->{PBSFILE}'\n") ;
}

#-------------------------------------------------------------------------------

sub ParseSwitchesAndLoadPlugins
{
# This is a bit hairy since plugins might add switches that are accepted on the command line and in a prf and
# the plugin path can be defined on the command line and in a prf!
# We load the pbs config twice. Once to handle the paths and the switches pertinent to plugin loading
# and once to "really" load the config.

my ($pbs_config, $command_line_arguments) = @_ ;
my $parse_message = '' ;

$pbs_config->{PLUGIN_PATH} = [] ;
$pbs_config->{LIB_PATH} = [] ;

# get the PBS_PLUGIN_PATH and PBS_LIB_PATH from the command line or the prf
# handle -plp and -ppp on the command line (get a separate config)
(my $command_line_switch_parse_ok, my $command_line_parse_message, my $command_line_config, my $command_line_targets)
	= PBS::PBSConfig::ParseSwitches(undef, $command_line_arguments, PARSE_SWITCHES_IGNORE_ERROR) ;

$pbs_config->{PLUGIN_PATH} = $command_line_config->{PLUGIN_PATH} if(@{$command_line_config->{PLUGIN_PATH}}) ;
$pbs_config->{DISPLAY_PLUGIN_RUNS}++ if $command_line_config->{DISPLAY_PLUGIN_RUNS};
$pbs_config->{DISPLAY_PLUGIN_LOAD_INFO}++ if $command_line_config->{DISPLAY_PLUGIN_LOAD_INFO} ;
$pbs_config->{NO_DEFAULT_PATH_WARNING}++ if $command_line_config->{NO_DEFAULT_PATH_WARNING} ;

$pbs_config->{LIB_PATH} = $command_line_config->{LIB_PATH} if(@{$command_line_config->{LIB_PATH}}) ;

#  handle -plp && -ppp in a prf
unless(defined $command_line_config->{NO_PBS_RESPONSE_FILE})
	{
	my ($pbs_response_file, $prf_config) 
		= PBS::PBSConfig::ParsePrfSwitches
			(
			  $command_line_config->{NO_ANONYMOUS_PBS_RESPONSE_FILE}
			, $command_line_config->{PBS_RESPONSE_FILE}
			, undef # run prf in separate namespace
			, PARSE_PRF_SWITCHES_IGNORE_ERROR
			) ;
			
	$prf_config->{PLUGIN_PATH} ||= [] ;
	$prf_config->{LIB_PATH} ||= [] ;
	
	push @{$pbs_config->{PLUGIN_PATH}}, @{$prf_config->{PLUGIN_PATH}} unless (@{$pbs_config->{PLUGIN_PATH}}) ;
	$pbs_config->{DISPLAY_PLUGIN_RUNS}++ if $prf_config->{DISPLAY_PLUGIN_RUNS};
	$pbs_config->{DISPLAY_PLUGIN_LOAD_INFO}++ if $prf_config->{DISPLAY_PLUGIN_LOAD_INFO} ;
	$pbs_config->{NO_DEFAULT_PATH_WARNING}++ if $prf_config->{NO_DEFAULT_PATH_WARNING} ;
	
	push @{$pbs_config->{LIB_PATH}}, @{$prf_config->{LIB_PATH}} unless (@{$pbs_config->{LIB_PATH}}) ;
	}

# broken
#~ use PAR ;
#~ my $zip = PAR::par_handle($0); # an Archive::Zip object
#~ my $src = $zip->memberNamed('lib/Hello.pm')->contents;

#~ use Archive::Zip ;
#~ my $zip = new Archive::Zip(__FILE__);
#=> error: member not found at /usr/bin/par.pl line 171

#~ PrintDebug "the file => $0  " . __FILE__ . "\n" ;
#~ PrintDebug $zip->members() ;
#~ PrintDebug "****************************\n" ;

# nothing defined on the command line and in a prf, last resort, use the distribution files
my $plugin_path_is_default ;

if(!exists $pbs_config->{PLUGIN_PATH} || ! @{$pbs_config->{PLUGIN_PATH}})
	{
	my ($basename, $path, $ext) = File::Basename::fileparse(find_installed('PBS::PBS'), ('\..*')) ;
	
	my $distribution_plugin_path = $path . 'Plugins' ;
	
	if(-e $distribution_plugin_path)
		{
		unless($pbs_config->{NO_DEFAULT_PATH_WARNING})
			{
			$parse_message .= WARNING "PBS plugin path not defined, using distribution plugins from $distribution_plugin_path! See --ppp.\n" ;
			}
			
		$pbs_config->{PLUGIN_PATH} = [$distribution_plugin_path] ;
		$plugin_path_is_default++ ;
		}
	else
		{
		die ERROR "No PBS plugin path set and couldn't found any in the distribution. See --ppp.\n" ;
		}
	}

my $lib_path_is_default ;

if(!exists $pbs_config->{LIB_PATH} || ! @{$pbs_config->{LIB_PATH}})
	{
	my ($basename, $path, $ext) = File::Basename::fileparse(find_installed('PBS::PBS'), ('\..*')) ;
	
	my $distribution_library_path = $path . 'PBSLib/' ;
	
	if(-e $distribution_library_path )
		{
		unless($pbs_config->{NO_DEFAULT_PATH_WARNING})
			{
			$parse_message .= WARNING "PBS lib path not defined, using distribution lib from $distribution_library_path! See --plp.\n" ;
			}
			
		$pbs_config->{LIB_PATH} = [$distribution_library_path] ;
		$lib_path_is_default++ ;
		}
	else
		{
		die ERROR "No PBS library path set and couldn't found any in the distribution. See --plp.\n" ;
		}
	}
	
# load the plugins
PBS::Plugin::ScanForPlugins($pbs_config, $pbs_config->{PLUGIN_PATH}) ; # plugins might add switches

# reparse the command line switches merging to PBS config
$pbs_config->{PLUGIN_PATH} = [] unless $plugin_path_is_default ;
$pbs_config->{LIB_PATH} = [] unless $lib_path_is_default ;

(my $switch_parse_ok, my $parse_switches_message) = PBS::PBSConfig::ParseSwitches($pbs_config, $command_line_arguments) ;
$parse_message .= $parse_switches_message ;

# testing of parse result is handled by caller

# reparse the prf 
unless(defined $pbs_config->{NO_PBS_RESPONSE_FILE})
	{
	my ($pbs_response_file, $prf_config) 
		= PBS::PBSConfig::ParsePrfSwitches
			(
			  $pbs_config->{NO_ANONYMOUS_PBS_RESPONSE_FILE}
			, $pbs_config->{PBS_RESPONSE_FILE}
			, undef # package to run prf in
			) ;
			
	#merging to PBS config, CLI has higher priority
	for my $key (keys %$prf_config)
		{
		if('ARRAY' eq ref $prf_config->{$key})
			{
			if(! exists $pbs_config->{$key} || 0 == @{$pbs_config->{$key}})
				{
				$pbs_config->{$key} = $prf_config->{$key}
				}
			}
		elsif('HASH' eq ref $prf_config->{$key})
			{
			# commandline definitions and user definitions
			if(! exists $pbs_config->{$key} || 0 == keys(%{$pbs_config->{$key}}))
				{
				$pbs_config->{$key} = $prf_config->{$key}
				}
			}
		else
			{
			if(! exists $pbs_config->{$key} || ! defined $pbs_config->{$key})
				{
				$pbs_config->{$key} = $prf_config->{$key}
				}
			}
		}
	}

return($switch_parse_ok, $parse_message) ;
}

#-------------------------------------------------------------------------------

sub DisplayVersion
{

use PBS::Version ;
my $version = PBS::Version::GetVersion() ;

print <<EOH ;

This is the Perl Build System, PBS, version $version

Copyright 2002-2008, Nadim Khemir and Anders Lindgren.

PBS comes with NO warranty. If you need a warranty, a completely
unafordable licencing fee can be arranged.

Send all suggestions and inqueries to <nadim\@khemir.net>.

EOH
}

#-------------------------------------------------------------------------------

1 ;

__END__
=head1 NAME

PBS::FrontEnd  -

=head1 SYNOPSIS

  use PBS::FrontEnd ;
  PBS::FrontEnd::Pbs(@ARGV) ;

=head1 DESCRIPTION

Entry point into B<PBS>.

=head2 EXPORT

None.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=head1 SEE ALSO

B<PBS> reference manual.

=cut

