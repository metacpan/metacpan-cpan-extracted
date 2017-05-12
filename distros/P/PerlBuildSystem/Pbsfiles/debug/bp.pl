
# define breakpoint in PBS debugger

use PBS::Debug ;

AddProjectBreakpoints() ; # define our breakpoints
ActivateBreakpoints('trigger_info', 'hi') ;
#~ ActivateBreakpoints('insert3') ;
#~ ActivateBreakpoints('build') ;
#~ ActivateBreakpoints('snapshot') ;

#-----------------------------------------------------------------------------------------

1 ;

#-----------------------------------------------------------------------------------------

sub AddProjectBreakpoints
{
AddBreakpoint
	(
	  'trigger_info'
	, TYPE => 'DEPEND'
	, TRIGGERED => 1
	, POST => 1
	, USE_DEBUGGER => 1
	#~ , ACTIVE => 1
	, ACTIONS =>
		[
		sub
			{
			my %data = @_ ;
			use Data::TreeDumper ;
			
			PrintDebug("Breakpoint 'trigger_info': rule '$data{RULE_NAME}' on node '$data{NODE_NAME}'.\n") ;
			#~ PrintDebug(DumpTree(\@_)) ;
			}
		#~ , sub
			#~ {
			#~ PrintDebug("Breackpoint 1 action 2.\n") ;
			#~ }
		]
	) ;

AddBreakpoint
	(
	  'hi'
	, TYPE => 'DEPEND'
	, PRE => 1
	#~ , ACTIVE => 1
	, ACTIONS =>
		[
		sub
			{
			PrintDebug("Breakpoint 'hi'.\n") ;
			}
		]
	) ;

AddBreakpoint
	(
	  'insert3'
	, NODE_REGEX => '3'
	, TYPE => 'INSERT'
	, POST => 1
	, USE_DEBUGGER => 1
	#~ , ACTIVE => 1
	, ACTIONS =>
		[
		sub
			{
			PrintDebug("Breakpoint 'insert3'.\n") ;
			
			my %data = @_ ;
			use Data::TreeDumper ;
			
			local $Data::TreeDumper::maxdepth = 1 ;
			#~ PrintDebug(DumpTree(\%data)) ;
			PrintDebug(DumpTree(\$data{NODE_NAME})) ;
			}
		]
	) ;

AddBreakpoint
	(
	  'build'
	, TYPE => 'BUILD'
	, USE_DEBUGGER => 1
	, ACTIVE => 1
	, PRE => 1
	, ACTIONS =>
		[
		sub
			{
			PrintDebug("Breakpoint 'build'.\n") ;
			
			my %data = @_ ;
			use Data::TreeDumper ;
			
			PrintDebug("About to build node '$data{NODE_NAME}'.\n") ;
			
			local $Data::TreeDumper::Maxdepth = 1 ;
			PrintDebug(DumpTree({@_})) ;
			}
		]
	) ;

AddBreakpoint
	(
	  'snapshot'
	, TYPE => 'TREE'
	, POST => 1
	#~ , USE_DEBUGGER => 1
	, ACTIONS =>
		[
		sub
			{
			PrintDebug("Breakpoint 'snapshot'.\n") ;
			my %data = @_ ;
			
			use Data::TreeDumper ;
			local $Data::TreeDumper::maxdepth = 1 ;
			
			next if $data{TREE}{__NAME} =~ /^__/ ;
			next if exists $data{TREE}{__INSERTED_AT}{ORIGINAL_INSERTION_DATA} ;
			
			PrintDebug(DumpTree($data{TREE}, "created tree:'$data{TREE}{__NAME}'.\n")) ;
			PrintDebug("\n") ;
			}
		]
	) ;
}



