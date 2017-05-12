# WIZARD_GROUP PBS
# WIZARD_NAME  breakpoint
# WIZARD_DESCRIPTION template for a pbsbreakpoint
# WIZARD_ON

print <<'EOP' ;
use PBS::Debug ;

PBS::Debug::AddBreakpoint
	(
	  'debug breakpoint name here'
	#~ , RULE_REGEX => ''
	#~ , NODE_REGEX => ''
	#~ , PACKAGE_REGEX => ''
	#~ , PBSFILE_REGEX => ''
	#~ , DEPEND => 1
	#~ , TRIGGERED => 1
	#~ , PRE => 1
	#~ , POST => 1
	#~ , BUILD => 1
	#~ , INSERT => 1
	#~ , USE_DEBUGGER => 1
	#~ , ACTIVE => 1
	, ACTIONS =>
		[
		sub
			{
			my %data = @_ ;
			use Data::TreeDumper ;
			
			#~ PrintInfo("Breackpoint 1 action 1.\n") ;
			PrintDebug("PBS breakpoint: rule '$data{RULE_NAME}' on node '$data{NODE_NAME}'.\n") ;
			#~ PrintDebug(DumpTree(\@_)) ;
			}
		#~ , sub
			#~ {
			#~ PrintDebug("Breackpoint 1 action 2.\n") ;
			#~ }
		]
	) ;
EOP


