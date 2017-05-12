AddConfig 'OPTIMIZE_FLAG_1::OVERRIDE_PARENT' => 'O2' ;
AddConfig 'OPTIMIZE_FLAG_2::LOCAL' => 'O2' ;
AddConfig 'OPTIMIZE_FLAG_3' => 'O2' ;
AddConfig UNDEF_FLAG => undef ;

AddRule '1', [ 'child' => qw(childs_wife grand_daughter grand_son)] ;

AddRule 'grand_son',
	{
	  NODE_REGEX => 'grand_son'
	, PBSFILE => './grand_son.pl'
	, PACKAGE => 'grand_son'
	} ;
	

AddRule 'grand_daughter',
	{
	  NODE_REGEX => 'grand_daughter'
	, PBSFILE => './grand_daughter.pl'
	, PACKAGE => 'grand_daughter'
	} ;

