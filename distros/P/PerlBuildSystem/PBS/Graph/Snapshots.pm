package PBS::Graph::Snapshots ;
use PBS::Debug ;

use 5.006 ;
use strict ;
use warnings ;

use Data::Dumper ;
use Data::TreeDumper ;
use File::Path ;

use PBS::Output ;
use PBS::Constants ;
use PBS::GraphViz;

require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw() ;
our $VERSION = '0.02' ;

#-------------------------------------------------------------------------------

sub GenerateSnapshots
{
my (
	  $trees, $inserted_nodes
	, $graph
	, $pbs_shapshots_directory
	, $inserted_graph_nodes
	, $inserted_edges
	, $inserted_configs
	, $inserted_pbs_configs
	) = @_ ;
	
PrintInfo("PBS Snapshots Maker $VERSION\n") ;
#~ PrintInfo DumpTree($inserted_nodes) ;

$graph->add_node
	({
	  shape => 'box'
	, name => '__NODE_INFORMATION'
	, label => 'PBS'
	, color => 'blue'
	, fontsize => 10
	}) ;
	

#~ PrintInfo DumpTree($graph) ;

# make all the nodes and edges invisible to start with
my @times ;
my %invisible_nodes ;

for my $node_name (keys %$inserted_nodes)
	{
	my $time ;
	
	if(exists $inserted_nodes->{$node_name}->{__INSERTED_AT}{ORIGINAL_INSERTION_DATA})
		{
		$time = $inserted_nodes->{$node_name}->{__INSERTED_AT}{ORIGINAL_INSERTION_DATA}{INSERTION_TIME} ;
		}
	else
		{
		$time = $inserted_nodes->{$node_name}->{__INSERTED_AT}{INSERTION_TIME} ;
		}
		
	push @times, $time ;
	
	if(exists $graph->{NODES}{$node_name})
		{
		$graph->{NODES}{$node_name}{__STYLE_BACKUP}  = $graph->{NODES}{$node_name}{style} ;
		$graph->{NODES}{$node_name}{style}           = 'invis' ;
		
		$graph->{NODES}{$node_name}{__INVISIBLE}++ ;
		
		$invisible_nodes{$time} = $graph->{NODES}{$node_name} ;
		}
	} 

my %invisible_edges ;
for my $edge (@{$graph->{EDGES}})
	{
	$invisible_edges{$edge} = $edge ;
	
	$edge->{__STYLE_BACKUP} = $edge->{style} ;
	$edge->{style}          = 'invis' ;
	}
	
#~ PrintInfo DumpTree($graph) ;

mkpath($pbs_shapshots_directory) ;

my $image_index = 0 ;
my $image_index_zeroed = sprintf("%05d", $image_index) ;
my $file_name = "$pbs_shapshots_directory/$image_index_zeroed.png" ;

$graph->as_png($file_name) ;
$image_index++ ;

# make the nodes visible one by one
my $time_frames = @times ;
my $time_index = 1 ;

for my $time (@times)
	{
	my $node_inserted ;
	my $node_information ; # to be displayed in the graph
	
	for my $node_time (sort keys %invisible_nodes)
		{
		if(($node_time - .00001) <= $time)
			{
			my $node = $invisible_nodes{$node_time} ; #graph node not PBS node!
			my $node_name = $node->{name} ; #graph nodes
			
			# code which is commented out allows the display of a node only if a parent is visible
			#~ my $parent_is_visible = 0 ;
			
			#~ my @node_parents = PBS::Information::GetParentsNames($inserted_nodes->{$node_name}) ;
			
			#~ if(@node_parents)
				#~ {
				#~ for my $parent_name (@node_parents)
					#~ {
					#~ next unless exists $graph->{NODES}{$parent_name} ;
					
					#~ if(exists $graph->{NODES}{$parent_name}{__INVISIBLE})
						#~ {
						#~ PrintDebug("node '$node_name' parent '$parent_name' is NOT visible\n") ;
						#~ }
					#~ else
						#~ {
						#~ PrintDebug("node '$node_name' parent '$parent_name' is visible\n") ;
						#~ $parent_is_visible++ ;
						#~ }
					#~ }
				#~ }
			#~ else
				#~ {
				#~ $parent_is_visible++ ;
				#~ }
				
			#~ if($parent_is_visible)
			if(1)
				{
				$node->{style} = $node->{__STYLE_BACKUP} ;
				
				delete $node->{__INVISIBLE} ;
				delete $invisible_nodes{$node_time} ;
				$node_inserted++ ;
				
				#~ print DumpTree $inserted_nodes->{$node_name}{__INSERTED_AT}, $node_name ;
				
				my ($inserting_rule, $inserting_node) ;
				
				if(exists $inserted_nodes->{$node_name}{__INSERTED_AT}{ORIGINAL_INSERTION_DATA})
					{
					$inserting_rule = $inserted_nodes->{$node_name}{__INSERTED_AT}{ORIGINAL_INSERTION_DATA}{INSERTION_RULE} ;
					$inserting_rule .= ' (' ;
					$inserting_rule .= $inserted_nodes->{$node_name}{__INSERTED_AT}{ORIGINAL_INSERTION_DATA}{INSERTION_FILE};
					$inserting_rule .= ')' ;
					
					$inserting_node = $inserted_nodes->{$node_name}{__INSERTED_AT}{ORIGINAL_INSERTION_DATA}{INSERTING_NODE} ;
					}
				else
					{
					$inserting_rule = $inserted_nodes->{$node_name}{__INSERTED_AT}{INSERTION_RULE} ;
					$inserting_rule .= ' (' ;
					$inserting_rule .= $inserted_nodes->{$node_name}{__INSERTED_AT}{INSERTION_FILE} ;
					$inserting_rule .= ')' ;
					
					$inserting_node = $inserted_nodes->{$node_name}{__INSERTED_AT}{INSERTING_NODE} ;
					}
					
				my $current_node_information .= "$inserting_node => $inserting_rule => $node_name.\n" ;
				if($current_node_information =~ /^__/)
					{
					$current_node_information = 'PBS' ;
					}
				
				$node_information .= "[$time_index/$time_frames] $current_node_information" ;
				}
			}
		else
			{
			last ;
			}
		}
		
	while(my ($edge_index, $edge) = each  %invisible_edges)
		{
		if
			(
			exists $graph->{NODES}{$edge->{to}}{__INVISIBLE} 
			|| exists $graph->{NODES}{$edge->{from}}{__INVISIBLE}
			)
			{
			# at least one invisible node
			}
		else
			{
			$edge->{style} = $edge->{__STYLE_BACKUP} ;
			delete $invisible_edges{$edge_index} ;
			}
		}
		
	$graph->{NODES}{__NODE_INFORMATION}{label} = $node_information ;
	
	if($node_inserted)
		{
		$image_index_zeroed = sprintf("%08d", $image_index) ;
		$file_name          = "$pbs_shapshots_directory/$image_index_zeroed.png" ;
		
		PrintInfo("Writting frame $time_index of $time_frames to '$file_name'.\n") ;
		$graph->as_png($file_name) ;
		
		$image_index++ ;
		}
	else
		{
		PrintInfo("Skipping frame $time_index of $time_frames.\n") ;
		}
		
	$time_index++ ;
	}
}

#-------------------------------------------------------------------------------

1 ;

__END__
=head1 NAME

PBS::Graph::Snapshots -

=head1 DESCRIPTION

Helper module to B<PBS::Graph>. I<GenerateHtmlGraph> generates a serie of images representing the dependencie tree
for each time a node is inserted.

=head2 EXPORT

None.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=head1 SEE ALSO

	B<PBS::Graph>.
	B<--gtg> and B<--gtg_tn>
	B<--gtg_snapshots>.

=cut
