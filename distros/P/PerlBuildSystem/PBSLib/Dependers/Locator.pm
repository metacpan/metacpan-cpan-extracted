
use File::Basename ;

sub LocateUnique
{
# this function is to be placed in a depender definiton array
# it returns a depender that:
# locates a node in the dependency tree and returns its name
# or dies if no node or multiple matching nodes are found

my $regex = shift ;
my ($package, $file_name, $line) = caller() ;

sub 
	{ 
	my
		(
		  $dependent_to_check
		, $config
		, $tree
		, $inserted_nodes
		, $dependencies
		, $builder_override
		# it is possible to pass extra arguments to the depender from the rule
		) = @_ ;
		
	my $located_node = LocateUniqueNodeInList($regex, $inserted_nodes, $package, $file_name, $line) ;
	
	my @all_dependencies ; 
	
	if(defined $dependencies && @$dependencies && $dependencies->[0] == 1 && @$dependencies > 1)
		{
		# previous depender defined dependencies
		push @$dependencies, $located_node ;
		}
	else
		{
		$dependencies = [1, $located_node] ;
		}
	
	return($dependencies, $builder_override) ;
	} ;
}

#-------------------------------------------------------------------------------

sub LocateUniqueNodeInList
{ 
# locate a unique node or dies

my ($regex, $node_list, $package, $file_name, $line) = @_ ;
	
my @matching_nodes = LocateNodeInList($regex, $node_list) ;
	
if(0 == @matching_nodes)
	{
	PrintError "LocateUnique: '$regex' didn't matched any node @ $file_name:$line!\n" ;
	$file_name =~ s/'//g ;
	PbsDisplayErrorWithContext($file_name, $line) ;
	die ;
	}
else
	{
	if(@matching_nodes == 1)
		{
		return $matching_nodes[0] ;
		}
	else
		{
		PrintError "LocateUnique '$regex' matched more than a node @ $file_name:$line!\n" ;
		
		for (@matching_nodes)
			{
			PrintError "\t$_\n" ;
			}
			
		$file_name =~ s/'//g ;
		PbsDisplayErrorWithContext($file_name, $line) ;
		die ;
		}
	}
}

#-------------------------------------------------------------------------------

sub LocateNodeInList
{ 
# locate all nodes matching a regex

my ($regex, $node_list) = @_ ;
	
my @matching_nodes ;
for my $node_name (keys %$node_list)
	{
	if($node_name =~ $regex)
		{
		push @matching_nodes, $node_name ;
		}
	}

return(@matching_nodes) ;
}	

#-------------------------------------------------------------------------------

sub LocateOrLocal
{
# this function is to be placed in a depender definiton array
# it returns a depender that:
# locates a node in the dependency tree and returns its name
# or dies if no node or multiple matching nodes are found
# if no node matching the regex is found, the second argument
# is evaluated and returned. the second argument can contain
# $path, $name, $basename, $ext

#ex:
# AddRule 'X',  ['*/X' => 'x', 'y', LocateOrLocal('^./node_to_be_found$', '$path/$basename.z')], BuildOk("done") ;

my $regex = shift ;
my $node = shift ;

my ($package, $file_name, $line) = caller() ;

sub 
	{ 
	my
		(
		  $dependent_to_check
		, $config
		, $tree
		, $inserted_nodes
		, $dependencies
		, $builder_override
		# it is possible to pass extra arguments to the depender from the rule
		) = @_ ;
		
	my @matching_nodes = LocateNodeInList($regex, $inserted_nodes) ;
	my $located_node ;
	
	if(@matching_nodes <= 1)
		{
		$located_node = $matching_nodes[0] ; # can be undef
		}
	else
		{
		PrintError "LocateorLocal '$regex' matched more than a node @ $file_name:$line!\n" ;
		
		for (@matching_nodes)
			{
			PrintError "\t$_\n" ;
			}
			
		$file_name =~ s/'//g ;
		PbsDisplayErrorWithContext($file_name, $line) ;
		die ;
		}
		
	unless(defined $located_node)
		{
		my ($basename, $path, $ext) = File::Basename::fileparse($dependent_to_check, ('\..*')) ;
		my $name = $basename . $ext ;
		$path =~ s/\/$// ;
		
		$located_node = eval "\"$node\";" ;
		}
	
	
	my @all_dependencies ; 
	
	if(defined $dependencies && @$dependencies && $dependencies->[0] == 1 && @$dependencies > 1)
		{
		# previous depender defined dependencies
		push @$dependencies, $located_node ;
		}
	else
		{
		$dependencies = [1, $located_node] ;
		}
	
	return($dependencies, $builder_override) ;
	} ;
}

#-------------------------------------------------------------------------------

1 ;

