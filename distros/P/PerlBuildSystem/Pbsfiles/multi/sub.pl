
AddRule 'test', ['*.lib' => 'a', 'b', 'c'], "touch %FILE_TO_BUILD" ;

if(GetConfig('EXTRA_OBJECT_FILES'))
	{
	AddRule('extra_object_file', ['*.lib' => 'd']) ;
	AddRule('d', ['d'], "touch %FILE_TO_BUILD") ;
	}

AddRule 'dep1', ['a' => 'a.dep'], "touch %FILE_TO_BUILD" ;
AddRule 'dep2', ['b' => 'a.dep'], "touch %FILE_TO_BUILD" ;

AddRule 'c', ['c'], "touch %FILE_TO_BUILD" ;
AddRule 'dep', ['a.dep'], "touch %FILE_TO_BUILD" ;

