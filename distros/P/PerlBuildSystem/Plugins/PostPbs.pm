
=head1 Plugin PostPbs

This plugin defined subs that are automatically run after pbs.

=cut

use PBS::PBSConfigSwitches ;
use PBS::Information ;
use Data::TreeDumper ;

#-------------------------------------------------------------------------------

#~ my $my_flag ;
#~ my @my_flag_list ;

#~ PBS::PBSConfigSwitches::RegisterFlagsAndHelp
	#~ (
	  #~ 'xxxxx|long_xxxxx'
	#~ , \$my_flag
	#~ , "short description."
	#~ , 'documentation'
	
	#~ , 'xxxxx|long_xxxxx=s'
	#~ , \@my_flag_list
	#~ , "short description."
	#~ , 'documentation'
	#~ ) ;
	

#~ sub PostPbs
#~ {
#~ my ($build_success, $pbs_config, $dependency_tree, $inserted_nodes) = @_ ;

#~ if(defined $pbs_config->{A})
	#~ {
	#~ }

#~ if($pbs_config->{B})
	#~ {
	#~ }
#~ }

#-------------------------------------------------------------------------------

1 ;

