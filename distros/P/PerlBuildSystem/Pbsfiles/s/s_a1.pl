=head1 PBSFILE USER HELP

Test configuration correctness

=head2 Top rules

=over 2 

=item * 'all'

=back

=cut

#~ AddConfig 'a' => '1' ;

AddRule 'all', ['all' => 'a', 'b', 'somewhere/c'] ;

AddRule 'a', {NODE_REGEX =>'a', PBSFILE => './Pbsfiles/s/s_b1.pl', PACKAGE => 'B1'} ;#, BUILD_DIRECTORY => '/bd_b1/'} ;
AddRule 'b', {NODE_REGEX =>'b', PBSFILE => './Pbsfiles/s/s_b2.pl', PACKAGE => 'B2', BUILD_DIRECTORY => '/bd_b2/'} ;

AddRule 'c', 
	{
	  NODE_REGEX =>'*/c'
	, PBSFILE => './Pbsfiles/s/s_b3.pl'
	, PACKAGE => 'B3'
	, BUILD_DIRECTORY => '/xxx/'
	#~ , DEBUG_DISPLAY_DEPENDENCIES => 1
	} ;


#-------------------------------------------------------------------------------

PbsUse('UserBuild/BuildSequenceMiner') ;
PbsUse('UserBuild/Multiple_O_Compile') ;

