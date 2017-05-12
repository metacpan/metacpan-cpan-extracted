
AddConfig a => 1 ;

AddRule 'all', [ all => 'same_configs', 'different_PBS__config', 'different_configs'] ;

AddRule 'subpbs',
	{
	  NODE_REGEX => 'different_PBS__config'
	, PBSFILE => 'subpbs2.pl'
	, PACKAGE => 'different_PBS__config'
	, BUILD_DIRECTORY => '/here'
	} ;

AddRule 'locked_subpbs',
	{
	  NODE_REGEX => 'different_configs'
	, PBSFILE => 'subpbs3.pl'
	, PACKAGE => 'different_configs'
	, BUILD_DIRECTORY => '/here'
	} ;

