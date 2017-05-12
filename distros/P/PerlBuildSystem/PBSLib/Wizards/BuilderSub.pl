# WIZARD_GROUP PBS
# WIZARD_NAME  builder
# WIZARD_DESCRIPTION template for a builder sub
# WIZARD_ON

print <<'EOP' ;
sub Builder
{
my ($config, $file_to_build, $dependencies, $triggering_dependencies, $file_tree, $inserted_nodes) = @_ ;

# use this if your shell command contains PBS expanded variables
use PBS::Rules::Builders ;
RunShellCommands
	(
	PBS::Rules::Builders::EvaluateShellCommandForNode
		(
		  "%CC %CFLAGS %FILE_TO_BUILD"
		, "SingleRunBuilder called at '$file_name:$line'"
		, $file_tree
		, $dependencies
		, $triggering_dependencies
		)
	) ;
  
# use this if you can build the entire command line 
RunShellCommands
	(
	  "$config->{CC} -c -o" 
	, 'ls -lsa'
	) ;
  
# You don't need to return anything if  RunShellCommand is the las command in the builder

#return(0, "Some  error") ;
#return(1, "OK Builder") ;
}

EOP


