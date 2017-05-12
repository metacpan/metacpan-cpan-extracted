=head1 PBSFILE USER HELP

Test digest node specific attributes  through subs as arguments

=head2 Top rules

=over 2 

=item * 'all'

=back

=cut

#~ AddConfig(USE_C_DEPENDER_SIMPLE => 1) ;
AddConfig(C_DEPENDER_SYSTEM_INCLUDES => 1) ;

use Devel::Depend::Cpp ;

PbsUse('Configs/Compilers/gcc') ;

#~ PbsUse('Configs/gcc') ;
PbsUse('Rules/C') ;

AddRule [VIRTUAL], 'all', ['all' => 'a.out'], BuildOk('') ;

AddRule 'a.out', ['a.out' => 'main.o', 'world.o']
	, "%CC -o %FILE_TO_BUILD %DEPENDENCY_LIST" ;


# add some node specific data, the node already matches another rule
AddNodeConfigVariableDependencies(qr/world.o/, 'OPTIMIZE_CFLAGS') ;

AddRule 'world.o', ['world.o']	, undef
	# the job is done here
	, [
           \&ChangePbsConfig
	  , \&ChangeConfig
	  , \&CheckConfig
	  #~, VerySpecialBuilderArguments('do this', 'do that')
	  #~, SetOptimizationOption('-O2')
	  #~, BuildShell($shell)
	  #~, \&ForceLocalShell
	  ] ;

sub ForceLocalShell
{
my (
  $dependent_to_check
, $config
, $tree
, $inserted_nodes
) = @_ ;

$tree->{__SHELL_OVERRIDE} = new PBS::Shell(USER_INFO => 'Forced local shell')  ;
$tree->{__SHELL_ORIGIN}   =  __FILE__ . __LINE__ ;
}

sub BuildShell
{
my $shell = shift || new PBS::Shell(USER_INFO => 'Test argument shell') ; # or find it in the config or whatever we please

return sub
	{
        my (
          $dependent_to_check
        , $config
        , $tree
        , $inserted_nodes
        ) = @_ ;
 	
	$tree->{__SHELL_OVERRIDE} = $shell ;
	$tree->{__SHELL_ORIGIN}   =  __FILE__ . __LINE__ ;
	}
}

sub VerySpecialBuilderArguments
{
my @definition_time_arguments = @_ ;

return sub
	{
        my (
          $dependent_to_check
        , $config
        , $tree
        , $inserted_nodes
        ) = @_ ;
	
	#set the arguments expected by our special builder
	$tree->{__VERY_SPECIAL_BUILDER_ARGUMENTS} = [@definition_time_arguments] ;
	
	use Data::TreeDumper ;
	PrintDebug DumpTree $tree ;
	}
}

sub ChangeConfig
{
my
        (
          $dependent_to_check
        , $config
        , $tree
        , $inserted_nodes
        ) = @_ ;

$tree->{__CONFIG} = {%{$tree->{__CONFIG}}} ; # config is share get our own copy (note! this is not deep)

$tree->{__CONFIG}{OPTIMIZE_CFLAGS} = '-O6' ;
$tree->{__CONFIG}{CDEFINES} = '-Wall' ;
$tree->{__CONFIG}{CFLAGS} = PBS::Config::EvalConfig
				(
				  '%OPTIMIZE_CFLAGS %WFLAGS'
				, $tree->{__CONFIG}
				, 'CFLAGS'
				, "config override at " . __FILE__ . __LINE__
				) ;
}


sub CheckConfig
{
my
        (
          $dependent_to_check
        , $config
        , $tree
        , $inserted_nodes
        ) = @_ ;

use Data::TreeDumper ;
PrintDebug DumpTree $tree->{__CONFIG} ;
}



sub ChangePbsConfig
{
my
        (
          $dependent_to_check
        , $config
        , $tree
        , $inserted_nodes
        ) = @_ ;

$tree->{__PBS_CONFIG} = {%{$tree->{__PBS_CONFIG}}} ; # config is share get our own copy (note! this is not deep)

$tree->{__PBS_CONFIG}{BUILD_AND_DISPLAY_NODE_INFO}++ ;
$tree->{__PBS_CONFIG}{DISPLAY_NODE_ORIGIN}++ ;
$tree->{__PBS_CONFIG}{DISPLAY_NODE_DEPENDENCIES}++ ;
$tree->{__PBS_CONFIG}{DISPLAY_NODE_BUILD_CAUSE}++ ;
$tree->{__PBS_CONFIG}{DISPLAY_NODE_BUILD_RULES}++ ;
$tree->{__PBS_CONFIG}{DISPLAY_NODE_BUILDER_ARGUMENTS}++ ;
$tree->{__PBS_CONFIG}{DISPLAY_NODE_BUILDER}++ ;
$tree->{__PBS_CONFIG}{DISPLAY_NODE_BUILD_POST_BUILD_COMMANDS}++ ;

undef $tree->{__PBS_CONFIG}{DISPLAY_NO_BUILD_HEADER} ;
}
