
=head1 Plugin CreateDump

This plugin handles the following PBS defined switches:

=over 2

=item  --dump

=back

=cut

use PBS::PBSConfigSwitches ;
use PBS::Information ;
use Data::TreeDumper ;

#-------------------------------------------------------------------------------

sub CreateDump
{
my ($pbs_config, $dependency_tree, $inserted_nodes, $build_sequence, $build_node) = @_ ;

if($pbs_config->{DUMP})
	{
	eval "use PBS::Log;" ; 
	die $@ if $@ ;
	
	PBS::Log::GeneratePbsDump($dependency_tree, $inserted_nodes, $pbs_config) ;
	}
}

#-------------------------------------------------------------------------------

1 ;

