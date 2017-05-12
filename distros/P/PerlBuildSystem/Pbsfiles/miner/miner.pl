

=head1 PBSFILE USER HELP

Test configuration correctness

=head2 Top rules

=over 2 

=item * 'all'

=back

=cut


AddConfig 
	(
	  'NADIM' => 'hi'
	, 'MULTIPLE_CC::LOCKED' => 'miner_multiple_cc'
	, 'MULTIPLE_CC::FORCE::UNLOCKED' => 'miner_multiple_cc_12'
	, 'MULTIPLE_CC::FORCE::UNLOCKED' => 'miner_multiple_cc-13'
	) ;

#~ PbsUse('Configs/gcc') ;
#~ use Data::Dumper ;
#~ print Dumper({GetConfig()}) ;
#~ die ;

PbsUse('Configs/default_gcc') ;
use Data::Dumper ;
AddConfigTo
	(
	  'Project'
	, 'USB' => 1
	, 'BT'  => 1
	, 'extra_something' => 1
	) ;
# or
# PbsUse('/projects/hugin/config.pm')
#PbsUse(GetConfig('PROJECT_CONFIG_FILE')) ; # defined at top level

#~ print Dumper({GetConfigFrom('Project')}) ;
#~ die ;

AddRule [VIRTUAL], 'all', ['all' => 'a1.o', 'a2.o', 'a3.o', 'b1.o', 'b2.o', 'b3.o'], BuildOk("Builder1") ;
AddRule 'all2', ['all'], BuildOk("Builder2") ;

if(GetConfigFrom('Project', 'USB'))
	{
	PrintInfo("Adding usb.o to all\n") ;
	AddRule 'all3', ['all' => 'usb/usb.o'] ;
	AddRule 'usb', {NODE_REGEX => '*/usb.o', PBSFILE => './Pbsfiles/miner_usb.pl', PACKAGE => 'USB'} ;
	}

AddRule 'a1', {NODE_REGEX => 'a1.o', PBSFILE => './Pbsfiles/miner_2.pl', PACKAGE => 'M2', BUILD_DIRECTORY => '/axis/bd_a1/'} ;
AddRule 'a2', {NODE_REGEX => 'a2.o', PBSFILE => './Pbsfiles/miner_2.pl', PACKAGE => 'M2', BUILD_DIRECTORY => '/axis/bd_a1/'} ;
AddRule 'a3', {NODE_REGEX => 'a3.o', PBSFILE => './Pbsfiles/miner_2.pl', PACKAGE => 'M2', BUILD_DIRECTORY => '/axis/bd_ax1/'} ;

for ('b1', 'b2', 'b3')
	{
	AddRule $_, {NODE_REGEX => "$_.o", PBSFILE => './Pbsfiles/miner_3.pl', PACKAGE => 'M3', BUILD_DIRECTORY => '/axis/bd_b1/'} ;
	}

#-------------------------------------------------------------------------------
PbsUse('UserBuild/BuildSequenceMiner') ;
PbsUse('UserBuild/Multiple_O_Compile') ;

sub Build
{
my ($build_result, $build_message) = BuildSequenceMiner
													(
													  [@_]
													, [\&Multiple_O_Compile]
													) ;
													
PrintInfo("Build done.\n") ;

return($build_result, $build_message) ;
}



