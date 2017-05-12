
# define breakpoint in PBS debugger

use PBS::Debug ;
use Data::TreeDumper ;

AddBreakpoint
	(
	  'variable info'
	, TYPE => 'VARIABLE'
	, ACTIVE => 1
	#~ , PACKAGE_REGEX => 'grand_son'
	, ACTIONS =>
		[
		sub
			{
			PrintDebug(DumpTree({@_}, "variable breakpoint:")) ;
			}
		]
	) ;
