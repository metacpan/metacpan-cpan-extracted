
=head1 SimplifyRuke

PBS only accepts pure perl rules since 0.29. It is possible to write a plugin to allow
user to defined rule syntax. This plugin defines a simplified format.

note: AR ... [dependent => './dependency'] ;
the ./ in the dependency definition forces it to be from the pbs root.

=cut

#-------------------------------------------------------------------------------

use Data::TreeDumper ;
use PBS::Constants ;

my $display_simplified_rule_transformation ;

PBS::PBSConfigSwitches::RegisterFlagsAndHelp
	(
	  'display_simplified_rule_transformation'
	, \$display_simplified_rule_transformation
	, "Display debugging data about simplified rule transformation to pure perl rule."
	, ''
	) ;

#-------------------------------------------------------------------------------

sub AddTrigger
{
my ($file_name, $line, $trigger_definition) = @_ ;

PrintDebug DumpTree(\@_, "Plugin AddTrigger") if $display_simplified_rule_transformation ;

my $name = shift @$trigger_definition ;
my $triggered_and_triggering = shift @$trigger_definition ;

if('ARRAY' eq ref $triggered_and_triggering)
	{
	# $triggered_node at first posotion
	
	my $last_triggering_nodes = @$triggered_and_triggering - 1 ;
	for my $trigger (@$triggered_and_triggering[1 .. $last_triggering_nodes])
		{
		my 
			(
			  $build_ok, $build_message
			, $trigger_path_regex
			, $trigger_prefix_regex
			, $trigger_regex
			) = BuildDependentRegex($trigger) ;
			
		unless($build_ok)
			{
			PrintError("Invalid rule at '$file_name:$line' $build_message\n") ;
			PbsDisplayErrorWithContext($file_name,$line) ;
			die ;
			}
			
		my $original = $trigger ;
		$trigger = qr/^$trigger_path_regex$trigger_prefix_regex$trigger_regex$/ ;
		
		if($display_simplified_rule_transformation)
			{
			PrintDebug "Replacing '$original' by '$trigger' in trigger rule '$name' at '$file_name,$line'\n" ;
			}
		}
	}

return($name, $triggered_and_triggering) ;
}	

#-------------------------------------------------------------------------------

sub AddSubpbsRule
{
# called with arguments ($name, $node_regex, $Pbsfile, $pbs_package, @other_setup_data)
# or ($node_regex, $Pbsfile), $name and $pbs_package will be generate
# less than 2 arguments or 3 arguments is considered an error

my ($file_name, $line, $rule_definition) = @_ ;
my ($name, $node_regex, $Pbsfile, $pbs_package, @other_setup_data);

if(@$rule_definition < 2 || @$rule_definition == 3)
	{
	die "   Not enough arguments to AddSubpbsRule called at '$file_name:$line'.\n" 
		. "      Simplified AddSubpbsRule[s] either take 2 arguments (regex and pbsfile)\n"
		. "      or 4 arguments (name, regex, pbsfile, package) and optional arguments.\n" ;
	}
elsif(@$rule_definition == 2)
	{
	($node_regex, $Pbsfile, $pbs_package) = @$rule_definition ;
	$pbs_package = $name = "$node_regex | $Pbsfile" ; 
	}
else
	{
	($name, $node_regex, $Pbsfile, $pbs_package, @other_setup_data) = @$rule_definition ;
	}

unless('Regexp' eq ref $node_regex)
	{
	PrintDebug DumpTree(\@_, "Plugin AddSubpsRule") if $display_simplified_rule_transformation ;
	my 
		(
		  $build_ok, $build_message
		, $dependent_path_regex
		, $dependent_prefix_regex
		, $dependent_regex
		) =  BuildDependentRegex($node_regex) ;
		
	if($build_ok)
		{
		my $original = $node_regex ;
		$node_regex = qr/$dependent_path_regex$dependent_prefix_regex$dependent_regex/ ;	
		
		if($display_simplified_rule_transformation)
			{
			PrintDebug "Replacing '$original' by '$node_regex' in subpbs rule '$name' at '$file_name,$line'\n" ;
			}
		
		}
	else
		{	
		PrintError("Invalid rule at '$file_name:$line' $build_message\n") ;
		PbsDisplayErrorWithContext($file_name,$line) ;
		die ;
		}
	}

return($name, $node_regex, $Pbsfile, $pbs_package, @other_setup_data) ;
}

#-------------------------------------------------------------------------------

sub AddRule
{
# this implementation of the AddRule plugin translates simplified rule definition
# to a pure perl rule definition. 

# NOTE: A reference to the original rule is passed and directely manipulated

my ($file_name, $line, $rule_definition) =  @_ ;

PrintDebug DumpTree(\@_, "Plugin AddRule") if $display_simplified_rule_transformation ;

my ($types, $name, $creator, $dependent, $dependencies, $builder, $node_subs) = ParseRule($file_name, $line, @$rule_definition) ;

my $is_meta_rule = grep{ $_ eq META_RULE } @$types ;

if(defined $dependent && '' eq ref $dependent && !$is_meta_rule)
	{
	# compute new arguments to Addrule
	my 
		(
		  $dependency_regex_ok, $dependency_regex_message
		, $dependent_path_regex
		, $dependent_prefix_regex
		, $dependent_regex
		) =  BuildDependentRegex($dependent) ;
		
	unless($dependency_regex_ok)
		{
		PrintError("Invalid rule at '$file_name:$line' $dependency_regex_message\n") ;
		PbsDisplayErrorWithContext($file_name,$line) ;
		die ;
		}
		
	my $sub_dependent_regex = qr/^$dependent_path_regex($dependent_prefix_regex)$dependent_regex$/ ;
	
	if($display_simplified_rule_transformation)
		{
		PrintDebug "Replacing '$dependent' by '$sub_dependent_regex' in rule '$name' at '$file_name,$line'\n" ;
		}
	
	$dependencies = TransformToPurePerlDependencies($dependencies) ;
	
	my $dependent_and_dependencies = [$sub_dependent_regex, @$dependencies];
	unshift @$dependent_and_dependencies, $creator if($creator) ;
	
	@$rule_definition = ($types, $name, $dependent_and_dependencies, $builder, $node_subs) ;
	}
elsif (defined $dependent && 'HASH' eq ref $dependent)
	{
	# allow simplified regex in subpbses
	
	unless('Regexp' eq ref $dependent->{NODE_REGEX})
		{
		my 
			(
			  $build_ok, $build_message
			, $dependent_path_regex
			, $dependent_prefix_regex
			, $dependent_regex
			) =  BuildDependentRegex($dependent->{NODE_REGEX}) ;
			
		if($build_ok)
			{
			my $original = $dependent->{NODE_REGEX} ;
			$dependent->{NODE_REGEX} = qr/$dependent_path_regex$dependent_prefix_regex$dependent_regex/ ;	
			
			if($display_simplified_rule_transformation)
				{
				PrintDebug "Replacing '$original' by '$dependent->{NODE_REGEX}' in subpbs rule '$name' at '$file_name,$line'\n" ;
				}
			
			}
		else
			{	
			PrintError("Invalid rule at  '$file_name:$line' $build_message\n") ;
			PbsDisplayErrorWithContext($file_name,$line) ;
			die ;
			}
		}
	}
}

#-------------------------------------------------------------------------------

sub ParseRule
{
my ($file_name, $line, @rule_definition) = @_ ;

my ($rule_type, $name, $creator, $dependent, $dependencies, $builder, $node_subs) = (0);

my $first_argument = shift @rule_definition ;

if('ARRAY' eq ref $first_argument)
	{
	$rule_type = $first_argument ;
	$name = shift @rule_definition;
	}
else
	{
	if('' eq ref $first_argument)
		{
		$name = $first_argument ;
		$rule_type = [UNTYPED] ;
		}
	else
		{
		Carp::carp ERROR("Invalid rule at '$file_name:$line'. Expecting a string or an array ref as first argument.") ;
		PbsDisplayErrorWithContext($file_name,$line) ;
		die ;
		}
	}

my $is_meta_rule = grep{ $_ eq META_RULE } @$rule_type ;

(my $depender_and_dependencies, $builder, $node_subs) = @rule_definition ;

if('ARRAY' eq ref $depender_and_dependencies and !$is_meta_rule)
	{
	($dependent, my @dependencies) = @$depender_and_dependencies ;
	
	if('ARRAY' eq ref $dependent)
		{
		$creator = $dependent ;
		$dependent = shift @dependencies ;
		}
		
	$dependencies = \@dependencies ;
	}
else
	{
	$dependent = $depender_and_dependencies ;
	}
	
return ($rule_type, $name, $creator, $dependent, $dependencies, $builder, $node_subs) ;
}

#-------------------------------------------------------------------------------

sub BuildDependentRegex
{
# Given a simplified dependent definition, this sub creates a perl regex

my $dependent_regex_definition = shift ;
my $error_message   = '' ;

if((! defined $dependent_regex_definition) || $dependent_regex_definition eq '')
	{
	return(0, 'Empty Regex definition') ;
	}

my ($dependent_name, $dependent_path, $dependent_ext) = File::Basename::fileparse($dependent_regex_definition,('\..*')) ;
$dependent_path =~ s|\\|/|g;

my $dependent_regex = $dependent_name . $dependent_ext ;
unless(defined $dependent_regex)
	{
	$error_message = "Invalid dependency definition" ;
	}
	
my $dependent_path_regex = $dependent_path ;
$dependent_path_regex =~ s/(?<!\\)\./\\./g ;

if($dependent_path_regex =~ tr/\*/\*/ > 1)
	{
	$error_message = "Error: only one '*' allowed in path specification $dependent_regex." ;
	}
	
$dependent_path_regex =~ s/\*/.*/ ;
$dependent_path_regex = '\./(?:.*/)*' if $dependent_path_regex eq '\./.*/' ;

if(!File::Spec->file_name_is_absolute($dependent_path_regex) && $dependent_path_regex !~ /^\\\.\// && $dependent_path_regex !~ /^\.\*/)
	{
	$dependent_path_regex = './' . $dependent_path_regex ;
	}
	
if($dependent_regex =~ /^.[^\*]*\*/)
	{
	$error_message = "Error: '*' only allowed at first position in dependent specification '$dependent_regex'." ;
	}
	
my $dependent_prefix_regex = '' ;
if($dependent_regex =~ s/^\*//)
	{
	$dependent_prefix_regex = '[^/]*' ;
	}
	
# finaly escape special characters
# $dependent_path_regex is a regex with *, we don't want to escape it.
# $dependent_prefix_regex is a regex with *, we don't want to escape it.
$dependent_regex = quotemeta($dependent_regex) ;

return
	(
	  $error_message eq ''
	, $error_message
	, $dependent_path_regex
	, $dependent_prefix_regex
	, $dependent_regex
	) ;
}

#-------------------------------------------------------------------------------

sub TransformToPurePerlDependencies
{
my ($dependencies) = @_ ;

for my $dependency (@$dependencies)
	{
	if(defined $dependency && '' eq ref $dependency)
		{
		if($display_simplified_rule_transformation)
			{
			PrintDebug "Replacing dependency '$dependency' by " ;
			}
			
		$dependency =~ s/\*/\[basename\]/gi ;
		$dependency =~ s/\[name\]/\$name/gi ;
		$dependency =~ s/\[basename\]/\$basename/gi ;
		$dependency =~ s/\[path\]/\$path/gi ;
		$dependency =~ s/\[ext\]/\$ext/gi ;
		
		if($dependency =~ /^\.\// || $dependency =~ /^\$path/ || File::Spec->file_name_is_absolute($dependency))
			{
			# OK path set
			}
		else
			{
			$dependency = "\$path/$dependency" ;
			}
			
		if($display_simplified_rule_transformation)
			{
			PrintDebug "'$dependency'\n" ;
			}
		}
	}

return ($dependencies);
}

#-------------------------------------------------------------------------------

1 ;

