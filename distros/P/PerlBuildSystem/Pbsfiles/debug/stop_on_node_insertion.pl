AddBreakpoint
	(
	  'insertion breakpoint test'
	, NODE_REGEX => '.'
	, TYPE => 'INSERT'
	, POST => 1
	#~ , USE_DEBUGGER => 1
	, ACTIVE => 1
	, ACTIONS =>
		[
		sub
			{
			my %data = @_ ;
			use Data::TreeDumper ;
			
			local $Data::TreeDumper::maxdepth = 1 ;
			#~ PrintDebug DumpTree(\%data, "Inserted node '$data{NODE_NAME}'", MAX_DEPTH => 2) ;
			
			PrintUser "Inserted node '$data{NODE_NAME}'." ;
			my $answer = <STDIN> ;
			}
		]
	) ;
 
