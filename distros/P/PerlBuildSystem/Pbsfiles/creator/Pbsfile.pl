=test

change the created node
change one of the dependencies
remove one of the dependencies
change the PbsUse
change the Pbsfile
remove the creator digest
change a md5 in the creator digest
modify the digest so it is not valid perl
change the version, is it needed? isn't the creator link to the pbsfile enough?

Creator rule with builder
Extra builder for node with creator
composite of above two


=cut

use Data::TreeDumper ;
#---------------------------------------------------------------------------------------

PbsUse('Configs/gcc') ; # this should also trigger the re-creation of the node

#---------------------------------------------------------------------------------------
# example Pbsfile using the creator
#---------------------------------------------------------------------------------------

ExcludeFromDigestGeneration('source' => 'dependency') ;
AddRule [VIRTUAL], 'all', [ 'all' => 'A', 'B'], BuildOk("All finished.") ;

#~ my $creator = GenerateCreator
		#~ (
		#~ # commands (as for a builder)
		#~ [
		  #~ "touch %FILE_TO_BUILD %DEPENDENCY_LIST" 
		#~ , "echo hi there"  
		#~ #, sub { PrintDebug DumpTree(\@_, 'Creator sub:', MAX_DEPTH => 2) ; return(1, "OK") }
		#~ ] ,
		#~ # other_info_to_check  and their values
		#~ #{
		#~ #__touch_version => 'anything specific to this creator version 1'
		#~ #} 
		#~ ) ;

#~ AddRule 'A creator', [[$creator] => 'A' => 'dependency_to_A', 'dependency_2_to_A'] ;

# new improved way to declare creators, must have builder
AddRule [CREATOR], 'objects', ['A' => 'dependency_to_A', 'dependency_2_to_A']
	=> "touch %FILE_TO_BUILD" ;

#~ AddRule 'B', ['B'] ;
AddRule 'B', ['B'], sub { PrintDebug "Building B\n" ; return(1, "OK") } ;

# OOPS! creators are run in the oposit order. how do we create a node that is dependent on a created node
# the rule order becomes very important here!

# tests
# creator with builder => expect overriding itself
#~ AddRule 'objects', [[\&Creator] => 'A' => 'dependency_to_A', 'dependency_2_to_A'], sub{PrintDebug" Builder\n" ; return(1,'hi')} ;

# 2 rules for the same node, one is a creator => expect [CREATOR] in ouput
#~ AddRule 'objects', [[\&Creator] => 'A' => 'dependency_to_A', 'dependency_2_to_A'] ;
#~ AddRule 'objects2', ['A'], sub{PrintDebug" Builder in rule that is not creator\n" ; return(1,'hi')} ;

# creator with builder => expect overriding itself
# 2 rules for the same node, one is a creator => expect [CREATOR] in ouput
#~ AddRule 'objects', [[\&Creator] => 'A' => 'dependency_to_A', 'dependency_2_to_A'], sub{1,"hi"} ;
#~ AddRule 'objects2', ['A'], sub{PrintDebug" Builder in rule that is not creator\n" ; return(1,'hi')} ;

	
#---------------------------------------------------------------------------------------

