
package PBS::DefaultBuild ;
use PBS::Debug ;

use Data::Dumper ;
use strict ;
use warnings ;

use 5.006 ;
 
require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw(DefaultBuild) ;
our $VERSION = '0.04' ;

use Data::TreeDumper;
use Time::HiRes qw(gettimeofday tv_interval) ;

use PBS::Depend ;
use PBS::Check ;
use PBS::Output ;
use PBS::Constants ;
use PBS::Information ;
use PBS::Plugin ;

#-------------------------------------------------------------------------------

sub DefaultBuild
{
my $Pbsfile            = shift ;
my $package_alias      = shift ;
my $load_package       = shift ;
my $pbs_config         = shift ;
my $rules_namespaces   = shift ;
my $rules              = shift ; 
my $config_namespaces  = shift ;
my $config_snapshot    = shift ;
my $build_directory    = $pbs_config->{BUILD_DIRECTORY} ;
my $source_directories = $pbs_config->{SOURCE_DIRECTORIES} ;
my $targets            = shift ; # a rule to build the targets exists in 'Builtin' this  argument is not used
my $inserted_nodes     = shift ;
my $dependency_tree    = shift ;
my $build_point        = shift ;
my $build_type         = shift ;

my ($package, $file_name, $line) = caller() ;

my $t0_depend = [gettimeofday];

my $config           = { PBS::Config::ExtractConfig($config_snapshot, $config_namespaces)	} ;
my $dependency_rules = [PBS::Rules::ExtractRules($rules, @$rules_namespaces)];

RunPluginSubs($pbs_config, 'PreDepend', $pbs_config, $package_alias, $config_snapshot, $config, $source_directories, $dependency_rules) ;

PrintInfo("** Depending [$package_alias/$PBS::PBS::Pbs_call_depth] **          \n") unless $pbs_config->{DISPLAY_NO_STEP_HEADER} ;
PrintInfo("=> Creating dependency tree for $dependency_tree->{__NAME} [$package_alias/$PBS::PBS::Pbs_call_depth]:\n") if defined $pbs_config->{DISPLAY_DEPEND_START} ;

PBS::Depend::CreateDependencyTree
	(
	  $Pbsfile
	, $package_alias
	, $load_package
	, $pbs_config
	, $dependency_tree
	, $config
	, $inserted_nodes
	, $dependency_rules
	) ;

PrintInfo("<= Depend done [$package_alias/$PBS::PBS::Pbs_call_depth/$PBS::Depend::BuildDependencyTree_calls]\n") if $pbs_config->{DISPLAY_DEPEND_START} ;

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

return(BUILD_SUCCESS, 'Dependended successfuly') if(DEPEND_ONLY == $build_type) ;

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

my $pbs_runs = PBS::PBS::GetPbsRuns() ;
my $plural = $pbs_runs > 1 ? 's' : '' ;
PrintInfo("Processed $pbs_runs Pbsfile$plural.                \n");

if($pbs_config->{DISPLAY_TOTAL_DEPENDENCY_TIME})
	{
	PrintInfo(sprintf("Total dependency time: %0.2f s.\n", tv_interval ($t0_depend, [gettimeofday]))) ;
	
	$PBS::C_DEPENDER::c_dependency_time ||= 0 ;
	PrintInfo(sprintf("   C depender time: %0.2f s.\n", $PBS::C_DEPENDER::c_dependency_time)) ;

	$PBS::C_DEPENDER::c_files ||= 0 ;
	my $file_plural = '' ; $file_plural = 's' if $PBS::C_DEPENDER::c_files > 1 ;
	
	$PBS::C_DEPENDER::c_files_cached ||= 0 ;
	my $cache_verb = 'was' ; $cache_verb = 'were' if $PBS::C_DEPENDER::c_files_cached > 1 ;
	
	PrintInfo("   C depender: $PBS::C_DEPENDER::c_files file$file_plural of which $PBS::C_DEPENDER::c_files_cached $cache_verb cached.\n") ;
	}

PrintInfo("\n** Checking **\n") unless $pbs_config->{DISPLAY_NO_STEP_HEADER} ;
my ($build_node, @build_sequence, %trigged_nodes) ;

if($build_point eq '')
	{
	$build_node = $dependency_tree ;
	}
else
	{
	# composite node
	if(exists $inserted_nodes->{$build_point})
		{
		$build_node = $inserted_nodes->{$build_point} ;
		}
	else
		{
		my $local_name = './' . $build_point ;
		if(exists $inserted_nodes->{$local_name})
			{
			$build_node = $inserted_nodes->{$local_name} ;
			$build_point = $local_name ;
			}
		else
			{
			PrintError("No such build point: '$build_point'.\n") ;
			DisplayCloseMatches($build_point, $inserted_nodes) ;
			die ;
			}
		}
	}
	
my $t0_check = [gettimeofday];

eval
	{
	my $nodes_checker = RunUniquePluginSub($pbs_config, 'GetNodeChecker') ;
	PBS::Check::CheckDependencyTree
		(
		  $build_node # start of the tree
		, $inserted_nodes
		, $pbs_config
		, $config
		, $nodes_checker
		, undef # single node checker
		, \@build_sequence
		, \%trigged_nodes
		) ;
	
	print "       \r" ;
	
	# check if any triggered top node has been left outside the build
	for my $node_name (keys %$inserted_nodes)
		{
		next if $inserted_nodes->{$node_name}{__NAME} =~ /^__/ ;
		
		unless(exists $inserted_nodes->{$node_name}{__CHECKED})
			{
			#~PrintWarning("Node '$inserted_nodes->{$node_name}{__NAME}' wasn't checked!\n") ;
			
			if(exists $inserted_nodes->{$node_name}{__TRIGGER_INSERTED})
				{
				PrintInfo("\n** Checking Trigger Inserted '$inserted_nodes->{$node_name}{__NAME}' **\n") unless $pbs_config->{DISPLAY_NO_STEP_HEADER} ;
				my @triggered_build_sequence ;
				
				PBS::Check::CheckDependencyTree
					(
					  $inserted_nodes->{$node_name}
					, $inserted_nodes
					, $pbs_config
					, $config
					, $nodes_checker
					, undef # single node checker
					, \@triggered_build_sequence
					, \%trigged_nodes
					) ;
				
				push @build_sequence, @triggered_build_sequence ;
				}
			}
		}
	} ;

if($pbs_config->{DISPLAY_CHECK_TIME})
	{
	PrintInfo(sprintf("Total Check time: %0.2f s.\n", tv_interval ($t0_check, [gettimeofday]))) ;
	}

# die later if check failed (ex: cyclic tree), run visualisation plugins first
my $check_failed = $@ ;

RunPluginSubs($pbs_config, 'PostDependAndCheck', $pbs_config, $dependency_tree, $inserted_nodes, \@build_sequence, $build_node) ;

#~ return(BUILD_FAILED, $check_failed) if $check_failed ;
die $check_failed if $check_failed ;

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

$dependency_tree->{__BUILD_SEQUENCE} = \@build_sequence ;

return(BUILD_SUCCESS, 'Generated build sequence', \@build_sequence) if(DEPEND_AND_CHECK == $build_type) ;

#-------------------------------------------------------------------------------
#-------------------------------------------------------------------------------

if(defined $pbs_config->{INTERMEDIATE_WARP_WRITE} && 'CODE' eq ref $pbs_config->{INTERMEDIATE_WARP_WRITE})
	{
	$pbs_config->{INTERMEDIATE_WARP_WRITE}->($dependency_tree, $inserted_nodes) ;
	}


unless($pbs_config->{DISPLAY_NO_STEP_HEADER})
	{
	PrintInfo("\n** Building ") ;
	PrintInfo("'$build_point' ") if $build_point ne '' ;
	PrintInfo("**\n") ;
	}

# we must get the number of nodes in the tree from the tree itself as we might have multiple %inserted_nodes if
# subpbses are run in LOCALE_NODES mode
my $number_of_nodes_in_the_dependency_tree = 0 ;
my $node_counter = sub 
			{
			my $tree = shift ;
			if('HASH' eq ref $tree && exists $tree->{__NAME})
				{
				$number_of_nodes_in_the_dependency_tree++ if($tree->{__NAME} !~ /^__/) ;
				
				return('HASH', $tree, grep {! /^__/} keys %$tree) ; # tweak to run faster
				}
			else
				{
				return(undef) ; # prune
				}
			} ;
		
DumpTree($dependency_tree, '', NO_OUTPUT => 1, FILTER => $node_counter) ;
		
PrintInfo("Number of nodes in the dependency tree: $number_of_nodes_in_the_dependency_tree nodes.\n") ;

#~ PBS::Digest::FlushMd5Cache() ;

my ($build_result, $build_message) ;

if($pbs_config->{DO_BUILD})
	{
	($build_result, $build_message) = PBS::Build::BuildSequence
										(
										  $pbs_config
										, \@build_sequence
										, $inserted_nodes
										) ;
	if($build_result == BUILD_SUCCESS)
		{
		PrintInfo("Build Done.\n") ;
		}
	else
		{
		PrintError("Build failed.\n") ;
		}
		
	}
else
	{
	($build_result, $build_message) = (BUILD_SUCCESS, 'DO_BUILD not set') ;
	PrintInfo("Build skipped. Done.\n") ;
	
	while(my ($debug_flag, $value) = each %$pbs_config) 
		{
		if($debug_flag =~ /^DEBUG/ && defined $value)
			{
			PrintInfo("Debug flag '$debug_flag' is set. Use --fb to force build.\n") ;
			last ;
			}
		}
	}
	
RunPluginSubs($pbs_config, 'CreateDump', $pbs_config, $dependency_tree, $inserted_nodes, \@build_sequence, $build_node) ;
RunPluginSubs($pbs_config, 'CreateLog', $pbs_config, $dependency_tree, $inserted_nodes, \@build_sequence, $build_node) ;

return($build_result, $build_message) ;
}

#-------------------------------------------------------------------------------

1 ;

__END__
=head1 NAME

PBS::DefaultBuild  -

=head1 SYNOPSIS

  use PBS::DefaultBuild ;
  DefaultBuild(....) ;
  
=head1 DESCRIPTION

The B<DefaultBuild> sub drives the build process by calling the B<depend>, B<check> and B<build> steps defined by B<PBS>,
it also displays information requested by the user (through the commmand line and via plugins). 

B<DefaultBuild> can be overridden by a user defined sub within a B<Pbsfile>.

=head2 EXPORT

None by default.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=head1 SEE ALSO

B<PBS> reference manual

=cut
