
=head1 Synopsis

This is a B<PBS> (Perl Build System) module.

=head1 When is 'Rules/BuildSystem.pm' used?

=head1 What 'Rules/C.pm' does.

=cut

use strict ;
use warnings ;

use PBS::PBS ;
use PBS::Rules ;

#-------------------------------------------------------------------------------

PbsUse('Rules/C_depender') ;
PbsUse('MetaRules/FirstAndOnlyOneOnDisk') ;

use PBS::Plugin ;
sub IncludeSourceDirectoriesInIncludePath
{
my ($shell_command_ref, $tree, $dependencies, $triggered_dependencies) = @_ ;

if($$shell_command_ref =~ /%CFLAGS_INCLUDE/)
	{
	my $cflags_include = GetCFileIncludePaths($tree);
	
	$$shell_command_ref =~ s/%CFLAGS_INCLUDE/$cflags_include/ ;
	}
} ;

my $pbs_config = GetPbsConfig() ;
PBS::Plugin::LoadPluginFromSubRefs($pbs_config, '+001C.pm', 'EvaluateShellCommand' =>
	\&IncludeSourceDirectoriesInIncludePath) ;

# todo
# remove from C_FLAGS_INCLUDE all the repository directories, it's is not a mistake to leave them but it look awkward
# to have the some include path twice on the command line

unless(GetConfig('CDEFINES'))
	{
	my @defines = %{GetPbsConfig()->{COMMAND_LINE_DEFINITIONS}} ;
	if(@defines)
		{
		AddCompositeDefine('CDEFINES', @defines) ;
		}
	else
		{
		AddConfig('CDEFINES', '') ;
		}
	}
	
#-------------------------------------------------------------------------------

my %config = GetConfig() ; # remove a few hundred function call by using a hash

my $c_defines = $config{CDEFINES} ;
AddNodeVariableDependencies(qr/\.o$/, CDEFINES => $c_defines) ;

AddConfigTo('BuiltIn', 'CFLAGS_INCLUDE:LOCAL' => '') unless($config{CFLAGS_INCLUDE}) ;
	
#-------------------------------------------------------------------------------

ExcludeFromDigestGeneration( 'cpp_files' => qr/\.cpp$/) ;
ExcludeFromDigestGeneration( 'c_files'   => qr/\.c$/) ;
ExcludeFromDigestGeneration( 's_files'   => qr/\.s$/) ;
ExcludeFromDigestGeneration( 'h_files'   => qr/\.h$/) ;
ExcludeFromDigestGeneration( 'libs'      => qr/\.a$/) ;
ExcludeFromDigestGeneration( 'inc files' => qr/\.inc$/ ) ;
ExcludeFromDigestGeneration( 'msxml.tli' => qr/msxml\.tli$/ ) ;
ExcludeFromDigestGeneration( 'msxml.tlh' => qr/msxml\.tlh$/ ) ;

#-------------------------------------------------------------------------------

my $c_compiler_host = $config{C_COMPILER_HOST} ;

my $check_c_files = GetConfig('CHECK_C_FILES:SILENT_NOT_EXISTS') || 0 ;

if ($check_c_files)
  {
    AddRuleTo 'BuiltIn', 'c_objects', [ '*/*.o' => '*.c' ]
	, [ GetConfig('CC_SYNTAX'),
	   "rsm %DEPENDENCY_LIST",
	   "splint %CFLAGS_INCLUDE -I%PBS_REPOSITORIES %DEPENDENCY_LIST || true" ];
  }
else
  {
    AddRuleTo 'BuiltIn', 'c_objects', [ '*/*.o' => '*.c' ]
	, GetConfig('CC_SYNTAX') ;
  }

	
#-------------------------------------------------------------------------------

$c_compiler_host = $config{C_COMPILER_HOST} ;

AddRuleTo 'BuiltIn', 'cpp_objects', [ '*/*.o' => '*.cpp' ]
	, GetConfig('CXX_SYNTAX') ;

#-------------------------------------------------------------------------------

my $as_compiler_host = $config{AS_COMPILER_HOST} ;

AddRuleTo 'BuiltIn', 's_objects', [ '*/*.o' => '*.s' ]
	, GetConfig('AS_SYNTAX') ;

#-------------------------------------------------------------------------------

AddRuleTo 'BuiltIn', [META_RULE], 'o_cs_meta',
	[\&FirstAndOnlyOneOnDisk, ['cpp_objects', 'c_objects', 's_objects'], 'c_objects'] ;

#~ PbsUse 'Rules/C_DependAndBuild' ;

#-------------------------------------------------------------------------------

1 ;

