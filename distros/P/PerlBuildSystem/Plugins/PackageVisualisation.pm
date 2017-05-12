

=head1 Plugin PackageVisualisation

This plugin handles the following PBS defined switches:

=over 2

=item  --dc

=item --dca

=item --dur

=item --dsd

=item --dbs

=back

=cut

use PBS::PBSConfigSwitches ;
use PBS::Information ;
use Data::TreeDumper ;

#-------------------------------------------------------------------------------

sub PreDepend
{
my ($pbs_config, $package_alias, $config_snapshot, $config, $source_directories, $dependency_rules) = @_ ;

if(defined $pbs_config->{DISPLAY_SOURCE_DIRECTORIES})
	{
	PrintInfo
		(
		DumpTree
			(
			  $source_directories
			, "source directories:"
			)
		) ;
	}
if($pbs_config->{DISPLAY_CONFIGURATION})
		{
		PrintInfo
			(
			DumpTree
				(
				  $config
				, "Config for '$package_alias':"
				)
			) ;
		}
		
if($pbs_config->{DISPLAY_CONFIGURATION_ALL})
		{
		PrintInfo
			(
			DumpTree
				(
				$config_snapshot
				, "Config namespaces for '$package_alias':"
				)
			) ;
		}
		
if(defined $pbs_config->{DISPLAY_USED_RULES}) #only the rules configured in
	{
	if(defined $pbs_config->{DISPLAY_USED_RULES_NAME_ONLY})
		{
		PrintInfo "Used dependency rules:\n" ;
		for my $rule (@$dependency_rules)
			{
			PrintInfo "\t$rule->{NAME} $rule->{ORIGIN}\n" ;
			}
		}
	else
		{
		PrintInfo
			(
			DumpTree
				(
				  $dependency_rules
				, "Used dependency rules:"
				)
			) ;
		}
	}
}

#-------------------------------------------------------------------------------

1 ;
