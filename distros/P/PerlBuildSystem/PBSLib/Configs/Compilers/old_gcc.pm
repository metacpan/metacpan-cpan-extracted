
use strict ;
use warnings ;

use PBS::Config ;

use Devel::Depend::Cpp 0.05 ;

#-------------------------------------------------------------------------------

PBS::Config::AddConfigTo 'BuiltIn',
	(
	 # commands
	  CC              => 'gcc'
	, LD              => 'ld'
	, CPP             => 'cpp'	
	, CXX             => 'g++'
	, AR              => 'ar'
	, AS              => 'as'
	, OBJDUMP         => 'objdump -h'

	# flags
	, DEPEND_FLAGS    => '-MM'
	, OPTIMIZE_CFLAGS => '-O2'
	, WFLAGS          => '-Wall -Wshadow -Wpointer-arith -Wcast-qual -Wcast-align '
								. '-Wwrite-strings -Wstrict-prototypes -Wmissing-prototypes '
								. '-Wmissing-declarations -Wredundant-decls -Wnested-externs -Winline'
	, MODULE_CFLAGS   => '-D_MODULE '
	, CFLAGS          => '%OPTIMIZE_CFLAGS %WFLAGS %MODULE_CFLAGS'
	) ;

#-------------------------------------------------------------------------------
1 ;

