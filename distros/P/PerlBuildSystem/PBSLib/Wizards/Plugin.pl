# WIZARD_GROUP PBS
# WIZARD_NAME  plugin
# WIZARD_DESCRIPTION template for a pbs plugin
# WIZARD_ON

print <<'EOP' ;

=head1 Plugin 

This plugin handles the following PBS defined switches:

=over 2

=item  --

=item --

=item --

=back

=cut

use PBS::PBSConfigSwitches ;
use PBS::Information ;
use Data::TreeDumper ;

#-------------------------------------------------------------------------------

my $my_flag ;
my @my_flag_list ;

PBS::PBSConfigSwitches::RegisterFlagsAndHelp
	(
	  'xxxxx|long_xxxxx'
	, \$my_flag
	, "short description."
	, 'documentation'
	
	, 'xxxxx|long_xxxxx=s'
	, \@my_flag_list
	, "short description."
	, 'documentation'
	) ;
	

*****************************************************************
You must set the pluggin name as well as the argument it receives
and remove these 2 lines as they will not compile
*****************************************************************

sub PluginName
{
my ($pbs_config, $package_alias, $config_snapshot, $config, $source_directories, $dependency_rules) = @_ ;

if(defined $pbs_config->{})
	{
	}

if($pbs_config->{})
	{
	}
}

#-------------------------------------------------------------------------------

1 ;

EOP

