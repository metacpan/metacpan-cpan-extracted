sub SingleRunBuilder
{
# this can be used when a single command builds multiple nodes and
# we don't want the command to be run multiple times
# an example is generating a swig wrapper and swig perl module

my ($package, $file_name, $line) = caller() ;

my $builder ;

if(@_ == 1)
	{
	if('CODE' eq ref $_[0])
		{
		$builder = $_[0] ;
		}
	elsif('' eq ref $_[0])
		{
		my $command = $_[0] ;
		
		$builder = 
			sub
			{
			my ($config, $file_to_build, $dependencies, $triggering_dependencies, $file_tree) = @_ ;
			my ($package, $file_name, $line) = caller() ;
			
			use PBS::Rules::Builders ;
			RunShellCommands
				(
				PBS::Rules::Builders::EvaluateShellCommandForNode
					(
					  $command
					, "SingleRunBuilder called at '$file_name:$line'"
					, $file_tree
					, $dependencies
					, $triggering_dependencies
					)
				) ;
			}
		}
	else
		{
		die ERROR "Error: SingleRunBuilder only accepts a single sub ref or string argument at '$file_name:$line'." ;
		}
	}
else
	{
	die ERROR "Error: SingleRunBuilder only accepts a single argument at '$file_name:$line'." ;
	}

my @already_built ;

return
	(
	sub
		{
		my ($config, $file_to_build, $dependencies) = @_ ;
		
		unless(@already_built)
			{
			push @already_built, $file_to_build ;
			return($builder->(@_)) ;
			}
		else
			{
			push @already_built, $file_to_build ;
			return(1, "SingleRunBuilder @ '$file_name:$line' was already run") ;
			}
		}
	) ;
}

#----------------------------------------------------------------------------------------------------------

1; 