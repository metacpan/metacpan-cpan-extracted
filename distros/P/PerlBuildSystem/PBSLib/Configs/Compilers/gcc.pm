
=head2 GNU toolchain configuration

=head2 Variables you may want to tweak:

=over 2

=item * GENERATE_COVERAGE        if set, adds SPECIAL_CFLAGS to generate coverage

data for gcov.

=item * CC, CPP, CXX, AR, AS,    The commands to use. Each compilter suite configuration

LD, OBJDUMP            is expected to set these.

=item * LDFLAGS                  Mandatory libraries to include when linking the final

executable. LDFLAGS gets tacked onto the end of the link command-line.

=item * WFLAGS                   C-compiler warning flags.

=item * ARFLAGS                  Flags to the archiver command when creating link libraries.

=item * OPTIMIZE_CFLAGS          Optimization options to the C compiler.

=item * CFLAGS, CXXFLAGS         The flags that appear on the C and C++ compiler commandline,

respectively. Typically '%WFLAGS %SPECIAL_CFLAGS %OPTIMIZE_CFLAGS' or similar.

=back

We also use Devel::Depend::Cpp as our depender.

=cut


use Devel::Depend::Cpp 0.08 ;

#-------------------------------------------------------------------------------
my $special_cflags = '-g -ffunction-sections' ;

if(defined GetConfig('GENERATE_COVERAGE:SILENT_NOT_EXISTS'))
{
	$special_cflags .= ' -ftest-coverage -fprofile-arcs' ;
}

AddConfigTo 'BuiltIn', 'SPECIAL_CFLAGS' => $special_cflags ;

PBS::Config::AddConfigTo 'BuiltIn',
	(
	# commands
	  CC              => 'gcc'
	, LD              => 'ld'
	, LDFLAGS         => '-lm'
	, CPP             => 'cpp'
	, CXX             => 'g++'
	, AR              => 'ar'
	, AS              => 'as'
	, OBJDUMP         => 'objdump -h'
	
	# flags
	, ARFLAGS         => 'cru'
	#	 , DEPEND_FLAGS    => '-MM'
	, OPTIMIZE_CFLAGS => '-O2'
	, DEBUG_CFLAGS    => '-g'
	, WFLAGS          => '-Wall -Wshadow -Wpointer-arith -Wcast-qual -Wcast-align '
								. '-Wwrite-strings -Wstrict-prototypes -Wmissing-prototypes '
								. '-Wmissing-declarations -Wredundant-decls -Wnested-externs -Winline'
								
	#~ , CFLAGS          =>	'%WFLAGS %SPECIAL_CFLAGS -fPIC -finput-charset=iso8859-1 '  #gave cc1: error: unrecognized option `-finput-charset=iso8859-1'
	, CFLAGS          =>	'%WFLAGS %SPECIAL_CFLAGS -fPIC ' 
								.	(
									GetConfig('COMPILER_DEBUG:SILENT_NOT_EXISTS') 
										? '%DEBUG_CFLAGS' 
										: '%OPTIMIZE_CFLAGS'
									)
									
	, CXXFLAGS        => '%CFLAGS'
	
	# defines
	, OPTIMIZE_CDEFINES => '-DNDEBUG'
	, DEBUG_CDEFINES    => ''
	, CDEFINES          => '' 
									.	(
										GetConfig('COMPILER_DEBUG:SILENT_NOT_EXISTS')
											? '%DEBUG_CDEFINES' 
											: '%OPTIMIZE_CDEFINES'
										)
	
	# syntax
	, CC_SYNTAX       => "%%CC %%CFLAGS %%CDEFINES %%CFLAGS_INCLUDE -o %%FILE_TO_BUILD -c %%DEPENDENCY_LIST"
	, CXX_SYNTAX      => "%%CXX %%CXXFLAGS %%CDEFINES %%CFLAGS_INCLUDE -o %%FILE_TO_BUILD -c %%DEPENDENCY_LIST"
	, AS_SYNTAX       => "%%AS %%ASFLAGS %%ASDEFINES %%ASFLAGS_INCLUDE -I%%PBS_REPOSITORIES -o %%FILE_TO_BUILD %%DEPENDENCY_LIST"
	
	# extensions
	, EXE_EXT         => ''
	, O_EXT           => '.o'
	, A_EXT           => '.a'
	, SO_EXT          => '.so'
	) ;

#-------------------------------------------------------------------------------
1 ;

