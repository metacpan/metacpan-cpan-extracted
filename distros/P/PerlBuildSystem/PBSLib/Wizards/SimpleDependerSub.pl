# WIZARD_GROUP PBS
# WIZARD_NAME  depender
# WIZARD_DESCRIPTION template for a depender sub
# WIZARD_ON

print <<'EOP' ;
use File::Basename ;

sub Depender
{
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

# Extra information for builders can be embedded in the node to build. Check "node subs"

# nodes starting with '__' are private to pbs and should not be depended (ex virtual root)
return($dependencies, $builder_override) if $dependent_to_check =~ /^__/ ;

my $build_directory    = $tree->{__PBS_CONFIG}{BUILD_DIRECTORY} ;
my $source_directories = $tree->{__PBS_CONFIG}{SOURCE_DIRECTORIES} ;

my ($triggered, @my_dependencies) ;

if(defined $dependencies && @$dependencies && $dependencies->[0] == 1 && @$dependencies > 1)
	{
	# previous depender defined dependencies
	$triggered       = shift @{$dependencies} ;
	@my_dependencies = @{$dependencies} ;
	}
	
# if we want to add dependencies
my ($basename, $path, $ext) = File::Basename::fileparse($dependent_to_check, ('\..*')) ;
my $name = $basename . $ext ;
$path =~ s/\/$// ;

push @my_dependencies, "$path/..." ;
$triggered = 1 ;

unshift @my_dependencies, $triggered ;

return(\@my_dependencies, $builder_override) ;
}

#
# since version 0.28_10, $builder overrides are complete rule defintions
# meta rules are already handled properly as they return the slave rule that matched
# if you want to override a builder, check the documentation properly
#

EOP


