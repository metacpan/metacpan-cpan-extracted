
=head1 Plugin CreateLog

This plugin handles the following PBS defined switches:

=over 2

=item  --log

=back

=cut

use PBS::PBSConfigSwitches ;
use PBS::Information ;
use Data::TreeDumper ;

#-------------------------------------------------------------------------------

sub CreateLog
{
my ($pbs_config, $dependency_tree, $inserted_nodes, $build_sequence, $build_node) = @_ ;

if($pbs_config->{CREATE_LOG})
	{
	eval "use PBS::Log;" ; 
	die $@ if $@ ;
	
	PBS::Log::LogTreeData($pbs_config, $dependency_tree, $inserted_nodes, $build_sequence) ;

	PrintInfo("Generated log in '$pbs_config->{LOG_NAME}'.\n") ;
	}
}

#-------------------------------------------------------------------------------

1 ;

