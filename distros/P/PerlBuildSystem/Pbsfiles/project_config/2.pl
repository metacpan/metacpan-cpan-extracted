
PbsUse('Configs/CheckProjectConfig') ;
	
AddRule '2>3', [ 2 => '3', '5'] ;

AddRule 'sub2>3',
	{
	  NODE_REGEX => '3'
	, PBSFILE => './dev/3.pl'
	, PACKAGE => '3'
	#~ , BUILD_DIRECTORY => '/here/' #example to see difference in graph
	} ;
	
AddRule '2>4', [ 2 => '4'] ;
AddRule 'sub2>4',
	{
	  NODE_REGEX => '4'
	, PBSFILE => './dev/3.pl'
	, PACKAGE => '3'
	#~ , COMMAND_LINE_DEFINITIONS => {'hi' => 'there'}
	, BUILD_DIRECTORY => '/here/' #example to see difference in graph
	} ;

