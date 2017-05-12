
# This example shows how to generate multiple node with a single command.

PbsUse 'Builders/SingleRunBuilder' ;

AddRule [VIRTUAL], "all",['all' => 'A', 'A_B', 'A_C'], BuildOk() ;

AddRule "A_or_B", [qr/A/]
	=> SingleRunBuilder("touch  %FILE_TO_BUILD_PATH/A %FILE_TO_BUILD_PATH/A_B %FILE_TO_BUILD_PATH/A_C") ;


=using a sub
AddRule "A_or_B", [qr/A/], SingleRunBuilder(\&Builder) ;

sub Builder 
{
#~ my ($config, $file_to_build, $dependencies) = @_ ;
#~ RunShellCommands("touch $file_to_build ${file_to_build}_B ${file_to_build}_C") ;

my ($config, $file_to_build, $dependencies, $triggering_dependencies, $file_tree, $inserted_nodes) = @_ ;
my ($package, $file_name, $line) = caller() ;


use PBS::Rules::Builders ;

RunShellCommands
	(
	PBS::Rules::Builders::EvaluateShellCommandForNode
		(
		  "touch  %FILE_TO_BUILD_PATH/A %FILE_TO_BUILD_PATH/A_B %FILE_TO_BUILD_PATH/A_C"
		, "SingleRunBuilder called at '$file_name:$line'" #$shell_command_info
		, $file_tree
		, $dependencies
		, $triggering_dependencies
		)
	) ;
}
=cut

=ideas
# or 

AddRule "A_or_B", [qr/A/]
	=> SingleRunBuilder
		(
		sub Builder 
			{
			my ($config, $file_to_build, $dependencies) = @_ ;
			
			RunShellCommands("touch $file_to_build ${file_to_build}_B ${file_to_build}_C") ;
			}
		) ;

# this would be neat in the future
AddRule "A_or_B", [qr/A/]
	=> "touch %FILE_TO_BUILD %{FILE_TO_BUILD}_B %{FILE_TO_BUILD}_C"
		=> SingleRunBuilder # node sub

AddRule "files to build together"
	=> Dependents('file1', 'file2')
	=> "touch %FILE_TO_BUILD %{FILE_TO_BUILD}_B %{FILE_TO_BUILD}_C"
		=> SingleRunBuilder # node sub

AddRule "files to build together"
	=> Dependents('file1', 'file2')
	=> Builder("touch %FILE_TO_BUILD %{FILE_TO_BUILD}_B %{FILE_TO_BUILD}_C", SingleRunBuilder) ;

AddRule "files to build together"
	=> Dependents('file1', 'file2')
	=> SingleRunBuilder("touch %FILE_TO_BUILD %{FILE_TO_BUILD}_B %{FILE_TO_BUILD}_C") ;

AddRule "A_or_B", [qr/A/]
	=>  [
	    "touch %FILE_TO_BUILD %{FILE_TO_BUILD}_B %{FILE_TO_BUILD}_C",
	    "another command",
	    \&SomeSub
	    ]
	    => SingleRunBuilder # node sub working on the builder level
	=> \&OtherNodeSub

#but then some smart guy would want all the dependents and the dependencies for his builder!
#so $file_to_build, $dependencies should be in a tuple
sub Builder 
{
my ($nodes) = @_ ; # possibly multiple nodes for a multi node builder
...
}

=cut

