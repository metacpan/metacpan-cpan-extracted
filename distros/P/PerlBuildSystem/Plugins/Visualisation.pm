

=head1 Plugin Visualisation

This plugin handles the following PBS defined switches:

=over 2

=item  --a

=item  --dni

=item  --dar

=item --dac

=item --files

=item --files_extra

=item --dbs

=back

=cut

use PBS::PBSConfigSwitches ;
use PBS::Information ;
use Data::TreeDumper ;

#-------------------------------------------------------------------------------

sub PostDependAndCheck
{
my ($pbs_config, $dependency_tree, $inserted_nodes, $build_sequence) = @_ ;

if($pbs_config->{DISPLAY_PBSUSE_STATISTIC})
	{
	PrintInfo2(PBS::PBS::GetPbsUseStatistic()) ;
	}
	
if(defined $pbs_config->{DEBUG_DISPLAY_PARENT})
	{
	my $local_child = $pbs_config->{DEBUG_DISPLAY_PARENT} ;
	$local_child = "./$local_child" unless $local_child =~ /^[.\/]/ ;
	
	my $DependenciesOnly = sub
							{
							my $tree = shift ;
							
							if('HASH' eq ref $tree)
								{
								return( 'HASH', undef, sort grep {! /^__/} keys %$tree) ;
								}
							
							return (Data::TreeDumper::DefaultNodesToDisplay($tree)) ;
							} ;
							
	if(exists $inserted_nodes->{$local_child})
		{
		PrintInfo
			(
			DumpTree
				(
				$inserted_nodes->{$local_child}{__DEPENDENCY_TO}
				, "\n'$local_child' ancestors:"
				, FILTER => $DependenciesOnly
				)
			) ;
		}
	else
		{
		PrintWarning("No such element '$pbs_config->{DEBUG_DISPLAY_PARENT}'\n") ;
		DisplayCloseMatches($pbs_config->{DEBUG_DISPLAY_PARENT}, $inserted_nodes) ;
		}
	}

if(exists $pbs_config->{DISPLAY_NODE_INFO} && @{$pbs_config->{DISPLAY_NODE_INFO}})
	{
	for my $node_name (sort keys %$inserted_nodes)
		{
		for my $node_info_regex (@{$pbs_config->{DISPLAY_NODE_INFO}})
			{
			if($inserted_nodes->{$node_name}{__NAME} =~ /$node_info_regex/)
				{
				PBS::Information::DisplayNodeInformation($inserted_nodes->{$node_name}, $pbs_config) ;
				last ;
				}
			}
		}
	}
	
if(defined $pbs_config->{DEBUG_DISPLAY_ALL_CONFIGURATIONS})
	{
	PBS::Config::DisplayAllConfigs() ;
	}

if(defined $pbs_config->{DISPLAY_ALL_RULES})
	{
	PBS::Rules::DisplayAllRules() ;
	}
   
if(defined $pbs_config->{DEBUG_DISPLAY_ALL_FILES_IN_TREE})
	{
	my @sorted_file_names = sort keys %$inserted_nodes ;
	
	PrintInfo('Number of nodes in the tree: ' . scalar(@sorted_file_names) . "\n") ;
	
	for my $file (@sorted_file_names)
		{
		PrintInfo("$file -> ") ;
		PrintInfo("[R]") unless exists $inserted_nodes->{$file}{__IN_BUILD_DIRECTORY} ;
		PrintInfo("$inserted_nodes->{$file}{__BUILD_NAME}\n") ;
		}
		
	PrintInfo("\n") ;
	}

if(defined $pbs_config->{DEBUG_DISPLAY_ALL_FILES_IN_TREE_EXTRA})
	{
	PrintInfo
		(
		DumpTree
			(
			  $inserted_nodes
			, "Files in dependency tree:"
			)
		) ;
	}

if($pbs_config->{DEBUG_DISPLAY_BUILD_SEQUENCE})
	{
	# Build sequence.
	my $GetBuildNames = sub
				{
				my $tree = shift ;
				return ('HASH', undef, sort grep { /^(__NAME|__BUILD_NAME)/} keys %$tree) if('HASH' eq ref $tree) ;	
				return (Data::TreeDumper::DefaultNodesToDisplay($tree)) ;
				} ;
	
	PrintInfo
		(
		DumpTree
			(
			$build_sequence
			, "\nBuildSequence:"
			, FILTER => $GetBuildNames
			)
		) ;
	}

}

#-------------------------------------------------------------------------------

1 ;
