
=head1 C_DependAndBuildDepender.pm

This modules overrides the way PBS generates dependencies to allow the generation
of the object files while generating dependencies.

This is usefull when compiling with Microsoft 'cl' which takes as much time to 
generated dependencies and object code as it takes to only generate dependencies.
This effectively halves the build time with 'cl'.

That is done by first replacing the C Depender and generating a $PreprocessorDepend which is
used by the generic C dependency generator.

=depend_flow
 
 +---------------------------+
 | PBS::CreateDependencyTree |
 +---------------------------+
   |
 -------------------------------------------------------------    depend only   --------------------------------------------------------------
   |
   |   +----------+     +------------------+     +------------------------+     +------------------------+     +---------------------------+
   +-> | Depender | +-> | C_SourceDepender | --> | GenerateDependencyFile | +-> |   $PreprocessorDepend  | --> | Devel::Depend::Cl::Depend |
       +----------+ |   +------------------+     +------------------------+ |   +------------------------+     +---------------------------+
                    |             ^                                         |
                    |             |                                         |
                    |             |                                         |
 ----------------------------------------------------   depend and build simulteanously   ----------------------------------------------------
                    |             |                                         |
                    |             |                                         |
                    |   +--------------------------+                        |
                    +-> | C_DependAndBuildDepender |                        |
                        +--------------------------+                        |
                          |  ^                                              |
                          v  |                                              |
                        +-----------------------------------+               |   +------------------------+     +--------------------------------+
                        |   Generate $PreprocessorDepend2   |               +-> |  $PreprocessorDepend2  | --> | Devel::Depend::Cl::RunAndParse |
                        +-----------------------------------+                   +------------------------+     +--------------------------------+
	

=cut

use Time::HiRes qw(gettimeofday tv_interval) ;
use PBS::Rules::Builders ;

# Replcae the depender defined in Rules/C_Depender with our own rule
ReplaceRuleTo 'BuiltIn', [POST_DEPEND], 'C_dependencies', \&C_DependAndBuildDepender, \&C_Builder ;

sub C_DependAndBuildDepender
{
# This depender is only a proxy around the 'normal' depender
# The 'normal' depender handles cache verification and dependency generation
# the dependency generation uses $PreprocessorDepend. We override $PreprocessorDepend
# to change the behaviour of the dependency generator

my
	(
	  $dependent_to_check
	, $config
	, $tree
	, $inserted_nodes
	, $dependencies         # rule local
	, $builder_override     # rule local
	, $rule_definition  # for introspection
	) = @_ ;

return([0, 'not a .c/.cpp file']) unless $dependent_to_check =~ /\.c(pp)?$/ ;

# we need information about the object file to be build
(my $object_file = $tree->{__NAME}) =~ s/\.c(pp)?$/.o/ ;

my @dependencies ;

if(exists $inserted_nodes->{$object_file})
	{
	# verify an object file node corresponding to the C/Cpp file exists
	my $object_node = $inserted_nodes->{$object_file} ;
	
	# compute where the object file will be put
	my $build_directory    = $object_node->{__PBS_CONFIG}{BUILD_DIRECTORY} ;
	my $source_directories = $object_node->{__PBS_CONFIG}{SOURCE_DIRECTORIES} ; 
	my $name               = $object_node->{__NAME} ;
	
	my ($full_name) = PBS::Check::LocateSource($name, $build_directory, $source_directories) ;
	$object_node->{__BUILD_NAME} = $full_name ;
	
	# save the 'normal' dependency generator
	my $previous_pre_processor = $PreprocessorDepend ;
	
	# generate a pre processor that will also generate an object file
	my $is_rebuild = 0 ;
	$PreprocessorDepend = GeneratePreprocessor($object_node, $full_name, \$is_rebuild) ;
	
	# call the 'normal' dependency generator ( verifies cache, ...)
	@dependencies = C_SourceDepender(@_) ;
	
	#if the C file or one of it's  dependency triggered, the object file
	# was also generated. Note that the object file itself is not verified
	# this is done in the object file builder
	
	# let the object file builder that all the verification and digest generation should be 
	# done but not the build
	$object_node->{__BUILD_DONE} = "Build and depended at the same time in 'C_DependAndBuild.pm'." if($is_rebuild) ;
	
	# restore the pre processor
	$PreprocessorDepend = $previous_pre_processor  ;
	}
else
	{
	PrintWarning "C_DependAndBuildDepender: No object file '$object_file' found in dependency graph. Reverting to depend only.\n" ;
	@dependencies = C_SourceDepender(@_) ;
	}

return(@dependencies) ;
}

#----------------------------------------------------------------------

sub GeneratePreprocessor
{
my $object_node = shift || die "No object node argument!\n" ;
my $object_file = shift || die "No object file argument!\n" ;
my $is_rebuild_ref = shift or die  "No rebuild flag argument" ;

# we need to wrap the preprocessor to give it the path of the object file
# and a variable to return its result

return
	(
	sub #preprocessor wrapper
		{
		BuildingPreprocessor($object_node, $object_file, $is_rebuild_ref, @_) ;
		}
	) ;
}

#----------------------------------------------------------------------

sub BuildingPreprocessor
{
my $object_node = shift ;
my $object_file = shift ;
my $is_rebuild_ref = shift ;

# if we're here, we're rebuilding, set the result variable
$$is_rebuild_ref++ ;

my $cpp                     = shift ;
my $file_to_depend          = shift ; #|| confess "No file to depend!\n" ;
my $switches                = shift ;
my $include_system_includes = shift ;
my $add_child_callback      = shift ;
my $display_cpp_output      = shift ;

my $t0 = [gettimeofday];

my $command_definition = '' ;


#extract from our config how we are going to build the node
# this is necessary to give all the necessary flags

if($file_to_depend =~ /\.c$/)
	{
	$command_definition = 'CC_SYNTAX' ;
	}
elsif($file_to_depend =~ /\.cpp$/)
	{
	$command_definition ='CXX_SYNTAX' ;
	}
else
	{
	die ;
	}
	
my $command_to_run = PBS::Rules::Builders::EvaluateShellCommandForNode
			(
			  GetConfig($command_definition) #$shell_command
			, 'hi there' # $shell_command_info
			, $object_node # $tree
			, [$file_to_depend] # $dependencies
			, [$file_to_depend] # $triggered_dependencies
			) ;


# also generate include information when building
$command_to_run .= ' -showIncludes ' ;

my @results = Devel::Depend::Cl::RunAndParse
		(
		  $file_to_depend
		, $command_to_run
		, $include_system_includes
		, $add_child_callback
		, $display_cpp_output
		) ;

# display timeing information
if($object_node->{__PBS_CONFIG}{DISPLAY_C_DEPENDENCY_INFO})
	{
	my $done = "BuildingPreprocessor done." ;
	
	if($object_node->{__PBS_CONFIG}{TIME_BUILDERS})
		{
		$done  .= sprintf(" time: %0.2f", tv_interval ($t0, [gettimeofday])) ;
		}
		
	PrintInfo "$done\n" ;
	}

return(@results) ;
}

#-----------------------------------------------------------------------------------------------------

1 ;
