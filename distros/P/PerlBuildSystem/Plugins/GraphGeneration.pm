

=head1 Plugin GraphGeneration

This plugin handles the following PBS defined switches:

=over 2

=item  --gtg

=item --gtg_p

=back

=cut

use PBS::PBSConfigSwitches ;
use PBS::Information ;
use Data::TreeDumper ;

#-------------------------------------------------------------------------------

sub PostDependAndCheck
{
my ($pbs_config, $dependency_tree, $inserted_nodes, $build_sequence, $build_node) = @_ ;

# find the inserted roots
my @trigger_inserted_roots ;
for my $node_name (keys %$inserted_nodes)
	{
	if(exists $inserted_nodes->{$node_name}{__TRIGGER_INSERTED})
		{
		push @trigger_inserted_roots, $inserted_nodes->{$node_name} ;
		}
	}
	
my $graph_title = '' ;
$graph_title .= "Partial Tree!\n" if($build_node != $dependency_tree) ;
$graph_title .= "Pbsfile: '$pbs_config->{PBSFILE}'" ;
	
if
	(
	   defined $pbs_config->{GENERATE_TREE_GRAPH} 
	|| defined $pbs_config->{GENERATE_TREE_GRAPH_SVG}
	|| defined $pbs_config->{GENERATE_TREE_GRAPH_HTML}
	|| defined $pbs_config->{GENERATE_TREE_GRAPH_SNAPSHOTS}
	)
	{
	eval "use PBS::Graph"; die $@ if $@ ;
	
	PBS::Graph::GenerateTreeGraphFile
		(
		  [$build_node, @trigger_inserted_roots], $inserted_nodes
		, $pbs_config->{GENERATE_TREE_GRAPH}
		, $graph_title
		, $pbs_config
		) ;
	}

if(defined $pbs_config->{GENERATE_TREE_GRAPH_DISPLAY_PACKAGE})
	{
	eval "use PBS::Graph" ; die $@ if $@ ;
	
	PBS::Graph::GenerateTreeGraphFile
		(
		  [$dependency_tree, @trigger_inserted_roots], $inserted_nodes
		, $pbs_config->{GENERATE_TREE_GRAPH_DISPLAY_PACKAGE}
		, $graph_title
		, $pbs_config
		) ;
	}
}

#-------------------------------------------------------------------------------

1 ;
