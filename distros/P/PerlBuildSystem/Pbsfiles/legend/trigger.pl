AddConfig b => 2 ;

AddRule '1',  ['triggered' => 'a'], BuildOk("done") ;
AddRule '2',  ['triggered_2' => 'triggering_2'], BuildOk("done") ;

sub ExportTriggers
{
AddTrigger 'T1', ['triggered' => 'triggering_1'] ;
AddRule 'sub_trigger_Y',
	{
	  NODE_REGEX => 'triggered'
	, PBSFILE => 'trigger.pl'
	, PACKAGE => 'T'
	, BUILD_DIRECTORY => '/somwhere/'
	} ;

AddTrigger 'T2', ['triggered_2' => 'triggering_2'] ;
AddRule 'sub_trigger_Z',
	{
	  NODE_REGEX => 'triggered_2'
	, PBSFILE => 'trigger.pl'
	, PACKAGE => 'T'
	, BUILD_DIRECTORY => '/somwhere/'
	} ;

}

