
package PBS::Warp::Warp1_8 ;
use PBS::Debug ;

use strict ;
use warnings ;

use 5.006 ;
 
require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw() ;
our $VERSION = '0.04' ;

#-------------------------------------------------------------------------------

use PBS::Output ;
#~ use PBS::Log ;
use PBS::Digest ;
use PBS::Constants ;
use PBS::Plugin;
use PBS::Warp;

use Cwd ;
use File::Path;
use Data::Dumper ;
#~ use Data::Compare ;
use Data::TreeDumper ;
use Digest::MD5 qw(md5_hex) ;
use Time::HiRes qw(gettimeofday tv_interval) ;


use constant RUN_NOT_NEEDED => -1 ;
use constant RUN_IN_NORMAL_MODE => 0 ;
use constant RUN_IN_WARP_MODE => 1 ;

#-------------------------------------------------------------------------------

sub WarpPbs
{
my ($targets, $pbs_config, $parent_config) = @_ ;

my ($warp_signature) = PBS::Warp::GetWarpSignature($targets, $pbs_config) ;
my $warp_path = $pbs_config->{BUILD_DIRECTORY} . '/warp1_8';
my $warp_file = "$warp_path/Pbsfile_$warp_signature.pl" ;

$PBS::pbs_run_information->{WARP_1_8}{FILE} = $warp_file ;
PrintInfo "Warp file name: '$warp_file'\n" if defined $pbs_config->{DISPLAY_WARP_FILE_NAME} ;

my ($run_in_warp_mode, $nodes, $number_of_removed_nodes, $warp_configuration) = CheckMd5File($targets, $pbs_config) ;

my $t0_warp = [gettimeofday];
my $t0_warp_check = $t0_warp ;

my @build_result ;

if($run_in_warp_mode == RUN_NOT_NEEDED)
	{
	PrintInfo("Warp: Up to date.\n") ;
	
	if($pbs_config->{DISPLAY_WARP_TIME})
		{
		my $warp_verification_time = tv_interval($t0_warp_check, [gettimeofday]) ;
		PrintInfo(sprintf("Warp verification time: %0.2f s.\n", $warp_verification_time)) ;
		$PBS::pbs_run_information->{WARP_1_8}{VERIFICATION_TIME} = $warp_verification_time ;
		
		my $warp_total_time = tv_interval($t0_warp, [gettimeofday]) ;
		PrintInfo(sprintf("Warp total time: %0.2f s.\n", $warp_total_time)) ;
		$PBS::pbs_run_information->{WARP_1_8}{TOTAL_TIME} = $warp_total_time ;
		}
		
	return (BUILD_SUCCESS, "Warp: Up to date", {READ_ME => "Up to date warp doesn't have any tree"}, $nodes) ;
	}
elsif ($run_in_warp_mode == RUN_IN_WARP_MODE)
	{
	if($number_of_removed_nodes)
		{
		if(defined $pbs_config->{DISPLAY_WARP_BUILD_SEQUENCE})
			{
			}
			
		eval "use PBS::PBS" ;
		die $@ if $@ ;
		
		unless($pbs_config->{DISPLAY_WARP_GENERATED_WARNINGS})
			{
			$pbs_config->{NO_LINK_INFO} = 1 ;
			$pbs_config->{NO_LOCAL_MATCHING_RULES_INFO} = 1 ;
			}
			
		# much of the "normal" node attributes are stripped in warp nodes
		# let the rest of the system know about this (ex graph generator)
		$pbs_config->{IN_WARP} = 1 ;
		
		my ($build_result, $build_message) ;
		my $new_dependency_tree ;
		
		eval
			{
			# PBS will link to the  warp nodes instead for regenerating them
			my $node_plural = '' ; $node_plural = 's' if $number_of_removed_nodes > 1 ;
			
			PrintInfo "Running PBS in warp mode. $number_of_removed_nodes node$node_plural to rebuild.\n" ;
			($build_result, $build_message, $new_dependency_tree)
				= PBS::PBS::Pbs
					(
					  $pbs_config->{PBSFILE}
					, ''    # parent package
					, $pbs_config
					, $parent_config
					, $targets
					, $nodes
					, "warp_tree"
					, DEPEND_CHECK_AND_BUILD
					) ;
			} ;
			
		if($@)
			{
			if($@ =~ /^BUILD_FAILED/)
				{
				# this exception occures only when a Builder fails so we can generate a warp file
				GenerateWarpFile
					(
					  $targets, $new_dependency_tree, $nodes
					, $pbs_config, $warp_configuration
					) ;
				}
				
			# died during depend or check
			die $@ ;
			}
		else
			{
			GenerateWarpFile
				(
				  $targets, $new_dependency_tree, $nodes
				, $pbs_config, $warp_configuration
				) ;
				
			# force a refresh after we build files and generated events
			# TODO: note that the synch should be by file not global or a single failure 
			#             would force a complete rebuild
			RunUniquePluginSub($pbs_config, 'ClearWatchedFilesList', $pbs_config, $warp_signature) ;
			}
			
		@build_result = ($build_result, $build_message, $new_dependency_tree, $nodes) ;
		}
	else
		{
		PrintInfo("Warp: Up to date.\n") ;
		@build_result = (BUILD_SUCCESS, "Warp: Up to date", {READ_ME => "Up to date warp doesn't have any tree"}, $nodes) ;
		}
	}
elsif($run_in_warp_mode == RUN_IN_NORMAL_MODE)
	{
	#eurk hack we could dispense with!
	# this is not needed but the subpses are travesed an extra time
	
	#TODO  since the md5 are not kept into the warp files anymore, a single generation is enough
	
	my ($dependency_tree_snapshot, $inserted_nodes_snapshot) ;
	
	$pbs_config->{INTERMEDIATE_WARP_WRITE} = 
		sub
		{
		my $dependency_tree = shift ;
		my $inserted_nodes = shift ;
		
		($dependency_tree_snapshot, $inserted_nodes_snapshot) = ($dependency_tree, $inserted_nodes) ;
		
		GenerateWarpFile
			(
			  $targets
			, $dependency_tree
			, $inserted_nodes
			, $pbs_config
			) ;
		} ;
		
	my ($build_result, $build_message, $dependency_tree, $inserted_nodes) ;
	eval
		{
		($build_result, $build_message, $dependency_tree, $inserted_nodes)
			= PBS::PBS::Pbs
				(
				$pbs_config->{PBSFILE}
				, ''    # parent package
				, $pbs_config
				, $parent_config
				, $targets
				, undef # inserted files
				, "root_NEEDS_REBUILD_pbs_$pbs_config->{PBSFILE}" # tree name
				, DEPEND_CHECK_AND_BUILD
				) ;
		} ;
		
		if($@)
			{
			if($@ =~ /^BUILD_FAILED/)
				{
				# this exception occures only when a Builder fails so we can generate a warp file
				GenerateWarpFile
					(
					  $targets
					, $dependency_tree_snapshot
					, $inserted_nodes_snapshot
					, $pbs_config
					) ;
				}
				
			die $@ ;
			}
		else
			{
			GenerateWarpFile
				(
				  $targets
				, $dependency_tree
				, $inserted_nodes
				, $pbs_config
				) ;
			}
			
	@build_result = ($build_result, $build_message, $dependency_tree, $inserted_nodes) ;
	}
else
	{
	die "Unexepected run type in Warp 1.8\n" ;
	}
	
return(@build_result) ;
}

#-----------------------------------------------------------------------------------------------------------------------

sub GenerateWarpFile
{
my ($targets, $dependency_tree, $inserted_nodes, $pbs_config, $warp_configuration) = @_ ;

$warp_configuration = PBS::Warp::GetWarpConfiguration($pbs_config, $warp_configuration) ; #$warp_configuration can be undef or from a warp file

PrintInfo("Generating warp file.               \n") ;

my $t0_warp_generate =  [gettimeofday] ;

GenerateMd5File($targets, $dependency_tree, $inserted_nodes, $pbs_config, $warp_configuration) ;
GenerateNodesWarp($targets, $dependency_tree, $inserted_nodes, $pbs_config, $warp_configuration) ;

if($pbs_config->{DISPLAY_WARP_TIME})
	{
	my $warp_generation_time = tv_interval($t0_warp_generate, [gettimeofday]) ;
	PrintInfo(sprintf("Warp total time: %0.2f s.\n", $warp_generation_time)) ;
	$PBS::pbs_run_information->{WARP_1_8}{GENERATION_TIME} = $warp_generation_time ;
	}
}

#-----------------------------------------------------------------------------------------------------------------------

sub GenerateMd5File
{
my ($targets, $dependency_tree, $inserted_nodes, $pbs_config, $warp_configuration) = @_ ;

my $t0_md5_generate =  [gettimeofday] ;

my ($warp_signature, $warp_signature_source) = PBS::Warp::GetWarpSignature($targets, $pbs_config) ;
my $warp_path = $pbs_config->{BUILD_DIRECTORY} . '/warp1_8';
mkpath($warp_path) unless(-e $warp_path) ;

(my $original_arguments = $pbs_config->{ORIGINAL_ARGV}) =~ s/[^0-9a-zA-Z_-]/_/g ;
my $warp_info_file= "$warp_path/Pbsfile_${warp_signature}_${original_arguments}" ;
open(WARP_INFO, ">", $warp_info_file) or die qq[Can't open $warp_info_file: $!] ;
close(WARP_INFO) ;

my $md5_file= "$warp_path/Pbsfile_${warp_signature}_md5.pl" ;
open(MD5, ">", $md5_file) or die qq[Can't open $md5_file: $!] ;

my %pbsfile_md5s = %$warp_configuration ;
my %node_md5s ;

for my $node_name (keys %$inserted_nodes)
	{
	my $node = $inserted_nodes->{$node_name} ;
	
	if(exists $node->{__BUILD_DONE})
		{
		if(exists $node->{__VIRTUAL})
			{
			$node_md5s{$node_name} = { __BUILD_NAME => $node->{__BUILD_NAME}, __MD5 => 'VIRTUAL'} ;
			}
		else
			{
			if(exists $node->{__INSERTED_AT}{INSERTION_TIME})
				{
				# this is a new node
				if(defined $node->{__MD5} && $node->{__MD5} ne 'not built yet')
					{
					$node_md5s{$node_name} = { __BUILD_NAME => $node->{__BUILD_NAME}, __MD5 => $node->{__MD5}} ;
					}
				else
					{
					if(defined (my $current_md5 = GetFileMD5($node->{__BUILD_NAME})))
						{
						$node->{__MD5} = $current_md5 ;
						$node_md5s{$node_name} = { __BUILD_NAME => $node->{__BUILD_NAME}, __MD5 => $current_md5} ;
						}
					else
						{
						die ERROR("Can't open '$node_name' to compute MD5 digest: $!") ;
						}
					}
				}
			else
				{
				# use the old md5
				$node_md5s{$node_name} = { __BUILD_NAME => $node->{__BUILD_NAME}, __MD5 => $node->{__MD5}} ;
				}
			}
		}
	else
		{
		$node_md5s{$node_name} = { __BUILD_NAME => $node->{__BUILD_NAME}, __MD5 => 'not built yet'} ; 
		}
		
	if(exists $node->{__FORCED})
		{
		$node_md5s{$node_name}{__MD5} = 'FORCED' ; 
		}
	}

local $Data::Dumper::Purity = 1 ;
local $Data::Dumper::Indent = 1 ;
local $Data::Dumper::Sortkeys = undef ;

print MD5 Data::Dumper->Dump([\%pbsfile_md5s], ['pbsfile_md5s']) ;
print MD5 Data::Dumper->Dump([\%node_md5s], ['node_md5s']) ;
print MD5 Data::Dumper->Dump([$VERSION], ['version']) ;

print MD5 'return($version, $pbsfile_md5s, $node_md5s);';

close(MD5) ;

my $md5_generation_time = tv_interval($t0_md5_generate, [gettimeofday]) ;
PrintInfo(sprintf("md5 generation time: %0.2f s.\n", $md5_generation_time)) if($pbs_config->{DISPLAY_WARP_TIME}) ;
}

#-------------------------------------------------------------------------------------------------------

sub CheckMd5File
{
my ($targets, $pbs_config) = @_ ;

my ($warp_signature) = PBS::Warp::GetWarpSignature($targets, $pbs_config) ;
my $warp_path      = $pbs_config->{BUILD_DIRECTORY} . '/warp1_8';
my $node_md5_file  = "$warp_path/Pbsfile_${warp_signature}_md5.pl" ;

my $run_in_warp_mode = RUN_IN_WARP_MODE ;

# md5 checking time
my $t0 =  [gettimeofday] ;

if(! -e $node_md5_file)
	{
	PrintWarning "Warp file'$node_md5_file' doesn't exist!\n" ;
	return(RUN_IN_NORMAL_MODE) ;
	}
	
my ($version, $pbsfile_md5s, $node_md5s) = do $node_md5_file ;

if(! defined $pbsfile_md5s || ! defined $node_md5s)
	{
	PrintWarning "Error in Warp file'$node_md5_file'!\n" ;
	return(RUN_IN_NORMAL_MODE) ;
	}

my $number_of_files = scalar(keys %$node_md5s) ;
$PBS::pbs_run_information->{WARP_1_8}{VERSION} = $version ;
$PBS::pbs_run_information->{WARP_1_8}{NODES_IN_DEPENDENCY_GRAPH} = $number_of_files ;

unless(defined $version)
	{
	PrintWarning("Warp: bad version (undefined). Warp file needs to be rebuilt.\n") ;
	return(RUN_IN_NORMAL_MODE) ;
	}
	
unless($version == $VERSION)
	{
	PrintWarning("Warp: bad version. Warp file needs to be rebuilt.\n") ;
	return(RUN_IN_NORMAL_MODE) ;
	}

PrintInfo(sprintf("md5 load time: %0.2f s. [$number_of_files]\n", tv_interval($t0, [gettimeofday]))) if($pbs_config->{DISPLAY_WARP_TIME}) ;

for my $pbsfile (keys %$pbsfile_md5s)
	{
	if(! defined $pbsfile_md5s->{$pbsfile} || PBS::Digest::IsFileModified($pbs_config, $pbsfile, $pbsfile_md5s->{$pbsfile}))
		{
		PrintWarning "Pbsfile modified, need to rebuild warp 1.8!\n" ;
		return(RUN_IN_NORMAL_MODE) ;
		}
	}

# regenerate nodes
my $nodes = {} ;
my $global_pbs_config = {} ;

my $t_node_regeneration =  [gettimeofday] ;
for my $node_name (keys %$node_md5s)
	{
	# rebuild the data PBS needs from the warp file
	
	#TODO: do not regenerate. pbs is interrested in knowing if the node exists to link to it
	# onl y regenerate if the data needs to be accessed (and even then, just compute the data without regenerating)
	
	# TODO: would the format below be fast enough to load?
	$nodes->{$node_name}{__NAME} = $node_name ;
	$nodes->{$node_name}{__BUILD_NAME} =  $node_md5s->{$node_name}{__BUILD_NAME} ;
	$nodes->{$node_name}{__MD5} =  $node_md5s->{$node_name}{__MD5} ;
	
	$nodes->{$node_name}{__BUILD_DONE} = "Field set in warp 1.8" ;
	$nodes->{$node_name}{__DEPENDED}++ ;
	$nodes->{$node_name}{__CHECKED}++ ; # pbs will not check any node (and its subtree) which is marked as checked
	$nodes->{$node_name}{__PBS_CONFIG} = $global_pbs_config unless exists $nodes->{$node_name}{__PBS_CONFIG} ;
	
	# TODO: if this information doesn't exists in warp 1.6 and it is done for backward compatibility only, reuse a reference to save memory
	$nodes->{$node_name}{__INSERTED_AT} =
			{
			'INSERTION_RULE' => 'N/A',
			'INSERTING_NODE' => 'N/A',
			'INSERTION_FILE' => 'N/A'
			} ;
			
	$nodes->{$node_name}{__DEPENDED_AT} = "N/A" ;
	}
	
PrintInfo(sprintf("node regeneration time %0.2f s.\n", tv_interval($t_node_regeneration, [gettimeofday]))) if($pbs_config->{DISPLAY_WARP_TIME}) ;

# use filewatching or default MD5 checking
# TODO: we don't need real nodes to verify md5 with the watch server, only to register them
#            if we were already registred, we wouldn't need to recreate the nodes
my $IsFileModified = RunUniquePluginSub($pbs_config, 'GetWatchedFilesChecker', $pbs_config, $warp_signature, $nodes) ;

if(defined $IsFileModified  && '' eq ref $IsFileModified  && 0 == $IsFileModified )
	{
	# nothing is modified
	return (RUN_NOT_NEEDED) ;
	}
	
$IsFileModified ||= \&PBS::Digest::IsFileModified ;

$t0 = [gettimeofday] ;
my (%nodes_not_matching, %nodes_removed) ;
my $node_verified = 0 ;

for my $node_name (keys %$node_md5s)
	{
	$node_verified++ ;
	PrintInfo "$node_verified\r" unless $node_verified %100 ;
	
	if
		(
		   defined $node_md5s->{$node_name}{__MD5}
		&& 
			(
			     $node_md5s->{$node_name}{__MD5} eq 'VIRTUAL'
			|| ! $IsFileModified->($pbs_config, $node_md5s->{$node_name}{__BUILD_NAME}, $node_md5s->{$node_name}{__MD5})
			)
		)
		{
	        PrintDebug "Warp checking: '$node_name'.\n" if($pbs_config->{DISPLAY_WARP_CHECKED_NODES}) ;
		}
	else
		{
		$nodes_not_matching{$node_name}++ ;
		$nodes_removed{$node_name}++ ;
		delete $nodes->{$node_name} ;
		
		PrintDebug "Warp checking: '$node_name', MD5 missmatch.\n" if($pbs_config->{DISPLAY_WARP_CHECKED_NODES}) ;
		}
	}

my $warp_node_path = $pbs_config->{BUILD_DIRECTORY} . "/warp1_8/warp_${warp_signature}" ;

for my $node_name (keys %nodes_not_matching)
	{
	#TODO; optimization, do this only if the node hasn't been removed by a dependency
	# next if exists $nodes_removed{$file}++ ;
	
	my ($node_warp_directory, $node_warp_full_path) = GetNodeWarpLocation($node_name , $warp_node_path) ;
	
	# load list
	my ($node_version, $node_dependents ) = do $node_warp_full_path ;
	
	if(defined $node_dependents)
		{
		if(defined $node_version)
			{
			if($node_version == $VERSION)
				{
				for my $dependent (@{$node_dependents->{__DEPENDENT}})
					{
					$nodes_removed{$dependent}++ ;
					delete $nodes->{$dependent} ;
					}
				}
			else
				{
				PrintWarning("Warp: bad version for node '$node_name' ['$node_warp_full_path']. Warp file needs to be rebuilt.\n") ;
				$run_in_warp_mode = RUN_IN_NORMAL_MODE ;
				}
			}
		else
			{
			PrintWarning("Warp: bad version (undefined) for node '$node_name' ['$node_warp_full_path']. Warp file needs to be rebuilt.\n") ;
			$run_in_warp_mode = RUN_IN_NORMAL_MODE ;
			}
		}
	else
		{
		PrintWarning "Warp: warp for node '$node_name' ['$node_warp_full_path'] not found! Can't run in Warp mode.\n" ;
		$run_in_warp_mode = RUN_IN_NORMAL_MODE ;
		}
	}

my $number_of_md5_mismatch  = scalar(keys %nodes_not_matching) ;
my $number_of_removed_nodes = scalar(keys %nodes_removed) ;

my $md5_time = tv_interval($t0, [gettimeofday]) ;

if($pbs_config->{DISPLAY_WARP_TIME})
	{
	PrintInfo(sprintf("md5 check time: %0.2f s. [$number_of_files/$number_of_md5_mismatch/$number_of_removed_nodes]\n", $md5_time)) ;
	}

return($run_in_warp_mode, $nodes, $number_of_removed_nodes, $pbsfile_md5s) ;
}

#-------------------------------------------------------------------------------------------------------

sub GenerateNodesWarp
{
my ($targets, $dependency_tree, $inserted_nodes, $pbs_config, $warp_configuration) = @_ ;

# generate a warp file per node (this could be faster with a DB
my $t0_single_warp_generate =  [gettimeofday] ;

my ($warp_signature) = PBS::Warp::GetWarpSignature($targets, $pbs_config) ;
my $warp_path = $pbs_config->{BUILD_DIRECTORY} . "/warp1_8/warp_${warp_signature}" ;
mkpath($warp_path) unless(-e $warp_path) ;

#~ my $node_generated = 1 ;
my %nodes_regenerated ;
my %nodes_needing_regeneration ;

# TODO, when regenerating, do not traverse all nodes, a second is lost

for my $node (values %$inserted_nodes)
	{
	my $node_name = $node->{__NAME} ;
	my ($node_warp_directory, $node_warp_full_path) = GetNodeWarpLocation($node_name , $warp_path) ;

	if(! -e $node_warp_full_path || exists $node->{__INSERTED_AT}{INSERTION_TIME}) #only new nodes are those that didn't match their md5
		{
		$nodes_needing_regeneration{$node->{__NAME}} = $node ;
		
		#what happends if the build fails? can we still use the md5 file
		
		#~ !!! if a node is changed, it might get more or less dependencies
		#~ !!! since we generate warp files that contain dependencies,
		#~ !!! we must regenerate the dependency nodes
		for(keys %$node)
			{
			next if /^__/ ;
			
			$nodes_needing_regeneration{$_} = $inserted_nodes->{$_} ; # multilpe nodes may have the same dependency but we regenerate only once
			}
		}
	}

#~ print DumpTree \%nodes_needing_regeneration, 'nodes_needing_regeneration', MAX_DEPTH => 1 ;

for my $node (values %nodes_needing_regeneration)
	{
	my $node_name = $node->{__NAME} ;
	
	next if exists $nodes_regenerated{$node_name} ;
	
	$nodes_regenerated{$node_name}++ ;
	
	my @dependents = GetAllDependents($node_name, $inserted_nodes) ;
	
	GenerateNodeWarp($node, \@dependents, $warp_path) ;
	}

my $number_of_node_warp = scalar (keys %nodes_regenerated) ;
my $single_warp_generation_time = tv_interval($t0_single_warp_generate, [gettimeofday]) ;

PrintInfo(sprintf("Single node warp generation time: %0.2f s. [$number_of_node_warp]\n", $single_warp_generation_time)) ;
}

#-------------------------------------------------------------------------------------------------------

sub GenerateNodeWarp
{

my ($node, $dependents, $warp_path) = @_ ;

my $node_name = $node->{__NAME} ;

my ($node_warp_directory, $node_warp_full_path) = GetNodeWarpLocation($node_name , $warp_path) ;

mkpath($node_warp_directory ) ;

my $node_dump =
	{
	'__NAME'       => $node_name, # not needed but informative
	'__DEPENDENT'  => $dependents,
	} ;

open(WARP, ">", $node_warp_full_path) or die qq[Can't open $node_warp_full_path: $!] ;

print WARP Data::Dumper->Dump([$node_dump], ['node']) ;
print WARP Data::Dumper->Dump([$VERSION], ['version']) ;
print WARP 'return($version, $node);';

close(WARP) ;
}

#-------------------------------------------------------------------------------------------------------

sub GetNodeWarpLocation
{
my ($node_name, $warp_path) = @_ ;

my ($volume, $node_warp_directory, $file) = File::Spec->splitpath($node_name);

# data for files with full path get in the appropriate place under the warp directory
if(File::Spec->file_name_is_absolute($node_name))
	{
	$node_warp_directory = 'ROOT/' . $node_warp_directory ;
	}
	
$node_warp_directory = "$warp_path/$node_warp_directory"  ;

return($node_warp_directory, "$node_warp_directory/$file.warp_1_8.pl") ;
}

#-------------------------------------------------------------------------------------------------------

use Memoize;
memoize('GetDependents');

sub GetAllDependents
{
my($node, $inserted_nodes) = @_ ;

return(GetDependents($node, $inserted_nodes)) ;
}

#-------------------------------------------------------------------------------------------------------

sub GetDependents
{
my($node, $inserted_nodes) = @_ ;

GenerateFirstLevelDependents($inserted_nodes) ;

my @dependents;

#TODO: fix the XDEPENDENT hack

if(exists $inserted_nodes->{$node}{__XDEPENDENT})
	{
	for my $dependent (@{$inserted_nodes->{$node}{__XDEPENDENT}})
		{
		push @dependents, GetDependents($dependent, $inserted_nodes) ;
		}
	
	push @dependents, @{$inserted_nodes->{$node}{__XDEPENDENT}} ;
	}

my %dependents = map{ $_ => 1} @dependents ;

# $inserted_nodes->{$node}{__ALL_DEPENDENT} = \%dependents ... could time optimize vs memory

return(keys %dependents) ;
}

#-------------------------------------------------------------------------------------------------------

{
my $GenerateFirstLevelDependents_done = 0 ;

sub GenerateFirstLevelDependents
{
my ($inserted_nodes) = @_ ;

return if $GenerateFirstLevelDependents_done ;

my $t0 =  [gettimeofday] ;
my $number_of_updated_dependencies = 0 ;

for my $node (values %{$inserted_nodes})
	{
	for my $dependency (keys %{$node})
		{
		next if $dependency =~ /^__/ ;
		
		$number_of_updated_dependencies++ ;
		
		# node may be a dry node from warp 
		$node->{$dependency} = {} if '' eq ref $node->{$dependency} ;
		
		push @{$node->{$dependency}{__XDEPENDENT}}, $node->{__NAME} ;
		}
	}
	
$GenerateFirstLevelDependents_done = 1 ;

PrintInfo(sprintf("GenerateFirstLevelDependents time: %0.2f s. [$number_of_updated_dependencies]\n", tv_interval($t0, [gettimeofday]))) ;
}

}

#-----------------------------------------------------------------------------------------------------------------------

1 ;

__END__
=head1 NAME

PBS::Warp::Warp1_8  -

=head1 DESCRIPTION

=head2 EXPORT

None.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=head1 SEE ALSO

B<PBS::Information>.

=cut
