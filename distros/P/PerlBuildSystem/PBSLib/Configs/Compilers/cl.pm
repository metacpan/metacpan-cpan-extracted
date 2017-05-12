#AddConditionalConfigTo('BuiltIn', 'SPECIAL_CFLAGS' => '', \&ConfigVariableNotDefined) ;

use Devel::Depend::Cl 0.04 ;

PBS::Config::AddConfigTo 'BuiltIn',
	(
	# commands
  	  CC              => 'cl.exe'
	, LD              => 'link.exe'
	, LDFLAGS         => '-NOLOGO -SUBSYSTEM:WINDOWS -MACHINE:X86 ' 
								. (
									GetConfig('COMPILER_DEBUG') 
										? '-DEBUG' 
										: ''
									)
	, CPP             => 'cl.exe'
	, CXX             => 'cl.exe'
	, AR              => 'lib.exe'
	, AS              => 'ml.exe'
	, OBJDUMP         => ''
	
	# flags
	, ARFLAGS         => ''
	, DEPEND_FLAGS    => ''
	, WFLAGS          => ''
	, OPTIMIZE_CFLAGS => '-MT -Ox'
	, DEBUG_CFLAGS    => '-MTd -Zi -RTC1'
	, CFLAGS          => '-nologo %WFLAGS ' 
									. (
										GetConfig('COMPILER_DEBUG') 
											? '%DEBUG_CFLAGS' 
											: '%OPTIMIZE_CFLAGS'
										)
	, CXXFLAGS        => '%CFLAGS -GR -EHsc'
	
	# defines
	, OPTIMIZE_CDEFINES => '-DNDEBUG'
	, DEBUG_CDEFINES  => '-D_DEBUG'
	, CDEFINES        => '-DWIN32 -D_WINDOWS -D_MBCS ' 
								. (
									GetConfig('COMPILER_DEBUG') 
										? '%DEBUG_CDEFINES' 
										: '%OPTIMIZE_CDEFINES'
									)
	
	# resource compiler
	, RC_DEFINES       => '',
	, RC_FLAGS         => '',
	, RC_FLAGS_INCLUDE => '',
	
	# syntax
	, CC_SYNTAX      => "%%CC %%CFLAGS -Fd%%BUILD_DIRECTORY/ %%CDEFINES %%CFLAGS_INCLUDE -Fo%%FILE_TO_BUILD -c %%DEPENDENCY_LIST"
	, CXX_SYNTAX     => "%%CXX %%CXXFLAGS -Fd%%BUILD_DIRECTORY/ %%CDEFINES %%CFLAGS_INCLUDE -Fo%%FILE_TO_BUILD -c %%DEPENDENCY_LIST"
	, AS_SYNTAX      => "%%AS %%ASFLAGS %%ASDEFINES %%ASFLAGS_INCLUDE -I%%PBS_REPOSITORIES -Fo%%FILE_TO_BUILD %%DEPENDENCY_LIST"
	
	# extensions
	, EXE_EXT      => '.exe'
	, O_EXT        => '.obj'
	, A_EXT        => '.lib'
	, SO_EXT       => '.dll'
	) ;


#-------------------------------------------------------------------------------
1 ;
