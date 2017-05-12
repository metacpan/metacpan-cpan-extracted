
AddConfig a => 1 ;

AddRule 'all', [ all => 'not_to_rebuild', 'virtual_node', 'forced', 'subpbs', 'depended_in_other_package', 'digest'] ;
AddRule [VIRTUAL], 'v', [ 'virtual_node'] ;
AddRule [FORCED], '1', ['forced' => 'triggering_1', 'triggering_2'] ;
AddRule '2', ['2' => '', 'triggering_2'] ;

AddRule 'x', ['not_to_rebuild' => 'existing_dependency'], BuildOk("not_to_rebuild generated") ;
AddRule 'y', ['existing_dependency'], BuildOk("existing_dependency generated") ;


AddRule 'subpbs',
	{
	  NODE_REGEX => 'subpbs'
	, PBSFILE => 'subpbs.pl'
	, PACKAGE => 'subpbs'
	} ;

ImportTriggers('trigger.pl') ;

