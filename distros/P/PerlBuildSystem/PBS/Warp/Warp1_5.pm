
package PBS::Warp::Warp1_5 ;
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
our $VERSION = '0.05' ;

#-------------------------------------------------------------------------------

use PBS::Output ;
use PBS::Log ;
use PBS::Digest ;
use PBS::Constants ;
use PBS::Plugin;
use PBS::Warp;

use Cwd ;
use File::Path;
use Data::Dumper ;
use Data::Compare ;
use Data::TreeDumper ;
use Digest::MD5 qw(md5_hex) ;
use Time::HiRes qw(gettimeofday tv_interval) ;

#-------------------------------------------------------------------------------

sub WarpPbs
{
my ($targets, $pbs_config, $parent_config) = @_ ;

my ($warp_signature) = PBS::Warp::GetWarpSignature($targets, $pbs_config) ;
my $warp_path = $pbs_config->{BUILD_DIRECTORY} . '/warp1_5';
my $warp_file= "$warp_path/Pbsfile_$warp_signature.pl" ;

$PBS::pbs_run_information->{WARP_1_5}{FILE} = $warp_file ;
PrintInfo "Warp file name: '$warp_file'\n" if defined $pbs_config->{DISPLAY_WARP_FILE_NAME} ;

my ($nodes, $node_names, $global_pbs_config, $insertion_file_names) ;
my ($version, $number_of_nodes_in_the_dependency_tree, $warp_configuration) ;

my $run_in_warp_mode = 1 ;

my $t0_warp_check ;
my $t0_warp = [gettimeofday];

# Loading of warp file can be eliminated if:
# we add the pbsfiles to the watched files
# we are registred with the watch server (it will have the nodes already)

if(-e $warp_file)
	{
#	do $warp_file or die ERROR("Couldn't evaluate warp file '$warp_file'\nFile error: $!\nCompilation error: $@\n") ;
	($nodes, $node_names, $global_pbs_config, $insertion_file_names,
	$version, $number_of_nodes_in_the_dependency_tree, $warp_configuration)
		= do $warp_file or die ERROR("Couldn't evaluate warp file '$warp_file'\nFile error: $!\nCompilation error: $@\n") ;
	
	$PBS::pbs_run_information->{WARP_1_5}{SIZE} = -s $warp_file ;
	
	if($number_of_nodes_in_the_dependency_tree)
		{
		$PBS::pbs_run_information->{WARP_1_5}{SIZE_PER_NODE} = int((-s $warp_file) / $number_of_nodes_in_the_dependency_tree) ;
		}
	else
		{
		$PBS::pbs_run_information->{WARP_1_5}{SIZE_PER_NODE} = 'No node in the warp tree' ;
		$run_in_warp_mode = 0 ;
		}
		
	$PBS::pbs_run_information->{WARP_1_5}{VERSION} = $version ;
	$PBS::pbs_run_information->{WARP_1_5}{NODES_IN_DEPENDENCY_GRAPH} = $number_of_nodes_in_the_dependency_tree	;
	
	if($pbs_config->{DISPLAY_WARP_TIME})
		{
		my $warp_load_time = tv_interval($t0_warp, [gettimeofday]) ;
		
		PrintInfo(sprintf("Warp load time: %0.2f s.\n", $warp_load_time)) ;
		$PBS::pbs_run_information->{WARP_1_5}{LOAD_TIME} = $warp_load_time ;
		}
		
	$t0_warp_check = [gettimeofday];
	
	PrintInfo "Verifying warp: $number_of_nodes_in_the_dependency_tree nodes ...\n" ;
	
	unless(defined $version)
		{
		PrintWarning2("Warp: bad version. Warp file needs to be rebuilt.\n") ;
		$run_in_warp_mode = 0 ;
		}
		
	unless($version == $VERSION)
		{
		PrintWarning2("Warp: bad version. Warp file needs to be rebuilt.\n") ;
		$run_in_warp_mode = 0 ;
		}
		
	# check if all pbs files are still the same
	if(0 == CheckFilesMD5($warp_configuration, 1))
		{
		PrintWarning("Warp: Differences in Pbsfiles. Warp file needs to be rebuilt.\n") ;
		$run_in_warp_mode = 0 ;
		}
	}
else
	{
	PrintWarning("Warp file '$warp_file' doesn't exist.\n") ;
	$run_in_warp_mode = 0 ;
	}

my @build_result ;
if($run_in_warp_mode)
	{
	# use filewatching or default MD5 checking
	my $IsFileModified = RunUniquePluginSub($pbs_config, 'GetWatchedFilesChecker', $pbs_config, $warp_signature, $nodes) ;

	# skip all tests if nothing is modified
	if($run_in_warp_mode && defined $IsFileModified  && '' eq ref $IsFileModified  && 0 == $IsFileModified )
		{
		if($pbs_config->{DISPLAY_WARP_TIME})
			{
			my $warp_verification_time = tv_interval($t0_warp_check, [gettimeofday]) ;
			PrintInfo(sprintf("Warp verification time: %0.2f s.\n", $warp_verification_time)) ;
			$PBS::pbs_run_information->{WARP_1_5}{VERIFICATION_TIME} = $warp_verification_time ;
			
			my $warp_total_time = tv_interval($t0_warp, [gettimeofday]) ;
			PrintInfo(sprintf("Warp total time: %0.2f s.\n", $warp_total_time)) ;
			$PBS::pbs_run_information->{WARP_1_5}{TOTAL_TIME} = $warp_total_time ;
			}
			
		PrintInfo("Warp: Up to date.\n") ;
		return (BUILD_SUCCESS, "Warp: Up to date", {READ_ME => "Up to date warp doesn't have any tree"}, $nodes) ;
		}

	$IsFileModified ||= \&PBS::Digest::IsFileModified ;
	
	my $number_of_removed_nodes = 0 ;
	
	# check md5 and remove all nodes that would trigger
	my $node_verified = 0 ;
	my $node_existed = 0 ;
	for my $node (keys %$nodes)
		{
		if($pbs_config->{DISPLAY_WARP_CHECKED_NODES})	
			{
			PrintDebug "Warp checking: '$node'.\n" ;
			}
		else
			{
			PrintInfo "\r$node_verified" unless  ($node_verified + $number_of_removed_nodes) % 100 ;
			}
			
		$node_verified++ ;
		
		next unless exists $nodes->{$node} ; # can have been removed by one of its dependencies
		
		$node_existed++ ;
		
		my $remove_this_node = 0 ;
		
		if('VIRTUAL' eq $nodes->{$node}{__MD5})
			{
			# virtual nodes don't have MD5
			}
		else
			{
			# rebuild the build name
			if(exists $nodes->{$node}{__LOCATION})
				{
				$nodes->{$node}{__BUILD_NAME} = $nodes->{$node}{__LOCATION} . substr($node, 1) ;
				}
			else
				{
				$nodes->{$node}{__BUILD_NAME} = $node ;
				}
				
			$remove_this_node += $IsFileModified->($pbs_config, $nodes->{$node}{__BUILD_NAME}, $nodes->{$node}{__MD5}) ;
			}
			
		$remove_this_node++ if(exists $nodes->{$node}{__FORCED}) ;
		
		if($remove_this_node) #and its dependents and its triggerer if any
			{
			my @nodes_to_remove = ($node) ;
			
			while(@nodes_to_remove)
				{
				my @dependent_nodes ;
				
				for my $node_to_remove (grep{ exists $nodes->{$_} } @nodes_to_remove)
					{
					if($pbs_config->{DISPLAY_WARP_TRIGGERED_NODES})	
						{
						PrintDebug "Warp: Removing node '$node_to_remove'\n" ;
						}
					
					push @dependent_nodes, grep{ exists $nodes->{$_} } map {$node_names->[$_]} @{$nodes->{$node_to_remove}{__DEPENDENT}} ;
					
					# remove triggering node and its dependents
					if(exists $nodes->{$node_to_remove}{__TRIGGER_INSERTED})
						{
						my $trigerring_node = $nodes->{$node_to_remove}{__TRIGGER_INSERTED} ;
						push @dependent_nodes, grep{ exists $nodes->{$_} } map {$node_names->[$_]} @{$nodes->{$trigerring_node}{__DEPENDENT}} ;
						delete $nodes->{$trigerring_node} ;
						}
						
					delete $nodes->{$node_to_remove} ;
					
					$number_of_removed_nodes++ ;
					}
					
				if($pbs_config->{DISPLAY_WARP_TRIGGERED_NODES})	
					{
					PrintDebug '-' x 30 . "\n" ;
					}
					
				@nodes_to_remove = @dependent_nodes ;
				}
			}
		else
			{
			# rebuild the data PBS needs from the warp file
			$nodes->{$node}{__NAME} = $node ;
			$nodes->{$node}{__BUILD_DONE} = "Field set in warp 1.5" ;
			$nodes->{$node}{__DEPENDED}++ ;
			$nodes->{$node}{__CHECKED}++ ; # pbs will not check any node (and its subtree) which is marked as checked
			
			$nodes->{$node}{__PBS_CONFIG} = $global_pbs_config unless exists $nodes->{$node}{__PBS_CONFIG} ;
			
			$nodes->{$node}{__INSERTED_AT}{INSERTION_FILE} = $insertion_file_names->[$nodes->{$node}{__INSERTED_AT}{INSERTION_FILE}] ;
			
			unless(exists $nodes->{$node}{__DEPENDED_AT})
				{
				$nodes->{$node}{__DEPENDED_AT} = $nodes->{$node}{__INSERTED_AT}{INSERTION_FILE} ;
				}
				
			#let our dependent nodes know about their dependencies
			#this needed when regenerating the warp file from partial warp data
			for my $dependent (map {$node_names->[$_]} @{$nodes->{$node}{__DEPENDENT}})
				{
				if(exists $nodes->{$dependent})
					{
					$nodes->{$dependent}{$node}++ ;
					}
				}
			}
		}
		
	if($pbs_config->{DISPLAY_WARP_TRIGGERED_NODES})	
		{
		PrintInfo "\rNodes: $node_verified verified: $node_existed\n" ;
		}
	else
		{
		PrintInfo "\r" ;
		}
	
	if($pbs_config->{DISPLAY_WARP_TIME})
		{
		my $warp_verification_time = tv_interval($t0_warp_check, [gettimeofday]) ;
		PrintInfo(sprintf("Warp verification time: %0.2f s.\n", $warp_verification_time)) ;
		$PBS::pbs_run_information->{WARP_1_5}{VERIFICATION_TIME} = $warp_verification_time ;
		
		my $warp_total_time = tv_interval($t0_warp, [gettimeofday]) ;
		PrintInfo(sprintf("Warp total time: %0.2f s.\n", $warp_total_time)) ;
		$PBS::pbs_run_information->{WARP_1_5}{TOTAL_TIME} = $warp_total_time ;
		}
		
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
			
		# we can't  generate a warp file while warping.
		# The warp configuration (pbsfiles md5) would be truncated
		# to the files used during the warp
		delete $pbs_config->{GENERATE_WARP1_5_FILE} ;
		
		# much of the "normal" node attributes are stripped in warp nodes
		# let the rest of the system know about this (ex graph generator)
		$pbs_config->{IN_WARP} = 1 ;
		my ($build_result, $build_message) ;
		my $new_dependency_tree ;
		
		eval
			{
			#~ PBS::Digest::FlushMd5Cache() ;
			
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
			# TODO: note that the synch should be by file not global
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
else
	{
	#eurk hack we could dispense with!
	# this is not needed but the subpses are travesed an extra time
	
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

return(@build_result) ;
}

#-----------------------------------------------------------------------------------------------------------------------

sub GenerateWarpFile
{
# indexing the node name  saves another 10% in size
# indexing the location name saves another 10% in size

my ($targets, $dependency_tree, $inserted_nodes, $pbs_config, $warp_configuration) = @_ ;

$warp_configuration = PBS::Warp::GetWarpConfiguration($pbs_config, $warp_configuration) ; #$warp_configuration can be undef or from a warp file

PrintInfo("Generating warp file.               \n") ;
my $t0_warp_generate =  [gettimeofday] ;

my ($warp_signature, $warp_signature_source) = PBS::Warp::GetWarpSignature($targets, $pbs_config) ;
my $warp_path = $pbs_config->{BUILD_DIRECTORY} . '/warp1_5';
mkpath($warp_path) unless(-e $warp_path) ;

(my $original_arguments = $pbs_config->{ORIGINAL_ARGV}) =~ s/[^0-9a-zA-Z_-]/_/g ;
my $warp_info_file= "$warp_path/Pbsfile_${warp_signature}_${original_arguments}" ;
open(WARP_INFO, ">", $warp_info_file) or die qq[Can't open $warp_info_file: $!] ;
close(WARP_INFO) ;

my $warp_file= "$warp_path/Pbsfile_$warp_signature.pl" ;

my $global_pbs_config = # cache to reduce warp file size
	{
	  BUILD_DIRECTORY    => $pbs_config->{BUILD_DIRECTORY}
	, SOURCE_DIRECTORIES => $pbs_config->{SOURCE_DIRECTORIES}
	} ;
	
my $number_of_nodes_in_the_dependency_tree = keys %$inserted_nodes ;

my ($nodes, $node_names, $insertion_file_names) = WarpifyTree1_5($inserted_nodes, $global_pbs_config) ;

open(WARP, ">", $warp_file) or die qq[Can't open $warp_file: $!] ;
print WARP PBS::Log::GetHeader('Warp', $pbs_config) ;

local $Data::Dumper::Purity = 1 ;
local $Data::Dumper::Indent = 1 ;
local $Data::Dumper::Sortkeys = undef ;

#~ print WARP Data::Dumper->Dump([$warp_signature_source], ['warp_signature_source']) ;

print WARP Data::Dumper->Dump([$global_pbs_config], ['global_pbs_config']) ;

print WARP Data::Dumper->Dump([ $nodes], ['nodes']) ;

print WARP "\n" ;
print WARP Data::Dumper->Dump([$node_names], ['node_names']) ;

print WARP "\n\n" ;
print WARP Data::Dumper->Dump([$insertion_file_names], ['insertion_file_names']) ;

print WARP "\n\n" ;
print WARP Data::Dumper->Dump([$warp_configuration], ['warp_configuration']) ;
print WARP "\n\n" ;
print WARP Data::Dumper->Dump([$VERSION], ['version']) ;
print WARP Data::Dumper->Dump([$number_of_nodes_in_the_dependency_tree], ['number_of_nodes_in_the_dependency_tree']) ;

print WARP "\n\n" ;


print WARP 'return $nodes, $node_names, $global_pbs_config, $insertion_file_names,
	$version, $number_of_nodes_in_the_dependency_tree, $warp_configuration;';
	
close(WARP) ;

if($pbs_config->{DISPLAY_WARP_TIME})
	{
	my $warp_generation_time = tv_interval($t0_warp_generate, [gettimeofday]) ;
	PrintInfo(sprintf("Warp total time: %0.2f s.\n", $warp_generation_time)) ;
	$PBS::pbs_run_information->{WARP_1_5}{GENERATION_TIME} = $warp_generation_time ;
	}
}

#-----------------------------------------------------------------------------------------------------------------------

sub WarpifyTree1_5
{
my $inserted_nodes = shift ;
my $global_pbs_config = shift ;

my ($package, $file_name, $line) = caller() ;

my (%nodes, @node_names, %nodes_index) ;
my (@insertion_file_names, %insertion_file_index) ;

for my $node (keys %$inserted_nodes)
	{
	# this doesn't work with LOCAL_NODES
	
	if(exists $inserted_nodes->{$node}{__VIRTUAL})
		{
		$nodes{$node}{__VIRTUAL} = 1 ;
		}
	else
		{
		# here some attempt to start handling AddDependency and micro warps
		#$nodes{$node}{__DIGEST} = GetDigest($inserted_nodes->{$node}) ;
		}
		
	if(exists $inserted_nodes->{$node}{__FORCED})
		{
		$nodes{$node}{__FORCED} = 1 ;
		}

	if(!exists $inserted_nodes->{$node}{__VIRTUAL} && $node =~ /^\.(.*)/)
		{
		($nodes{$node}{__LOCATION}) = ($inserted_nodes->{$node}{__BUILD_NAME} =~ /^(.*)$1$/) ;
		}
		
	#this can also be reduced for a +/- 10% reduction
	if(exists $inserted_nodes->{$node}{__INSERTED_AT}{ORIGINAL_INSERTION_DATA}{INSERTING_NODE})
		{
		$nodes{$node}{__INSERTED_AT}{INSERTING_NODE} = $inserted_nodes->{$node}{__INSERTED_AT}{ORIGINAL_INSERTION_DATA}{INSERTING_NODE}
		}
	else
		{
		$nodes{$node}{__INSERTED_AT}{INSERTING_NODE} = $inserted_nodes->{$node}{__INSERTED_AT}{INSERTING_NODE} ;
		}
	
	$nodes{$node}{__INSERTED_AT}{INSERTION_RULE} = $inserted_nodes->{$node}{__INSERTED_AT}{INSERTION_RULE} ;
	
	if(exists $inserted_nodes->{$node}{__DEPENDED_AT})
		{
		if($inserted_nodes->{$node}{__INSERTED_AT}{INSERTION_FILE} ne $inserted_nodes->{$node}{__DEPENDED_AT})
			{
			$nodes{$node}{__DEPENDED_AT} = $inserted_nodes->{$node}{__DEPENDED_AT} ;
			}
		}
		
	#reduce amount of data by indexing Insertion files (Pbsfile)
	my $insertion_file = $inserted_nodes->{$node}{__INSERTED_AT}{INSERTION_FILE} ;
	
	unless (exists $insertion_file_index{$insertion_file})
		{
		push @insertion_file_names, $insertion_file ;
		$insertion_file_index{$insertion_file} = $#insertion_file_names ;
		}
		
	$nodes{$node}{__INSERTED_AT}{INSERTION_FILE} = $insertion_file_index{$insertion_file} ;
	
	if
		(
		   $inserted_nodes->{$node}{__PBS_CONFIG}{BUILD_DIRECTORY}  ne $global_pbs_config->{BUILD_DIRECTORY}
		|| !Compare($inserted_nodes->{$node}{__PBS_CONFIG}{SOURCE_DIRECTORIES}, $global_pbs_config->{SOURCE_DIRECTORIES})
		)
		{
		$nodes{$node}{__PBS_CONFIG}{BUILD_DIRECTORY} = $inserted_nodes->{$node}{__PBS_CONFIG}{BUILD_DIRECTORY} ;
		$nodes{$node}{__PBS_CONFIG}{SOURCE_DIRECTORIES} = [@{$inserted_nodes->{$node}{__PBS_CONFIG}{SOURCE_DIRECTORIES}}] ; 
		}
		
	if(exists $inserted_nodes->{$node}{__BUILD_DONE})
		{
		if(exists $inserted_nodes->{$node}{__VIRTUAL})
			{
			$nodes{$node}{__MD5} = 'VIRTUAL' ;
			}
		else
			{
			if(exists $inserted_nodes->{$node}{__INSERTED_AT}{INSERTION_TIME})
				{
				# this is a new node
				if(defined $inserted_nodes->{$node}{__MD5} && $inserted_nodes->{$node}{__MD5} ne 'not built yet')
					{
					$nodes{$node}{__MD5} = $inserted_nodes->{$node}{__MD5} ;
					}
				else
					{
					if(defined (my $current_md5 = GetFileMD5($inserted_nodes->{$node}{__BUILD_NAME})))
						{
						$nodes{$node}{__MD5} = $inserted_nodes->{$node}{__MD5} = $current_md5 ;
						}
					else
						{
						die ERROR("Can't open '$node' to compute MD5 digest: $!") ;
						}
					}
				}
			else
				{
				# use the old md5
				$nodes{$node}{__MD5} = $inserted_nodes->{$node}{__MD5} ;
				}
			}
		}
	else
		{
		$nodes{$node}{__MD5} = 'not built yet' ; 
		}
		
	unless (exists $nodes_index{$node})
		{
		push @node_names, $node ;
		$nodes_index{$node} = $#node_names;
		}
		
	for my $dependency (keys %{$inserted_nodes->{$node}})
		{
		next if $dependency =~ /^__/ ;
		
		push @{$nodes{$dependency}{__DEPENDENT}}, $nodes_index{$node} ;
		}
		
	if (exists $inserted_nodes->{$node}{__TRIGGER_INSERTED})
		{
		$nodes{$node}{__TRIGGER_INSERTED} = $inserted_nodes->{$node}{__TRIGGER_INSERTED} ;
		}
	}
	
return(\%nodes, \@node_names, \@insertion_file_names) ;
}

#-----------------------------------------------------------------------------------------------------------------------

1 ;

__END__
=head1 NAME

PBS::Warp::Warp1_5  -

=head1 DESCRIPTION

=head2 EXPORT

None.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=head1 SEE ALSO

B<PBS::Information>.

=cut
