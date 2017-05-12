
use strict ;
use warnings ;
use Data::TreeDumper ;
use PBS::Triggers ;
use File::Spec ;

#-------------------------------------------------------------------------------

# this module overrides the build in AddRule (and al.) to allow us to define with a simpler regex
# than perl regex.
#
# it matches rules that are not meta builder and that have a simple text definition for the dependent
# it otherwise passes its arguments to PBS::AddRule

# '*' will be replaced by './.*' on the dependent side
# '*' will be replaced by '$basename' on the dependcy side

my $display_simplified_rule_transformation = 1 ;

#-------------------------------------------------------------------------------

sub SimplifiedAddTrigger
{
my ($package, $file_name, $line) = caller() ;
my $location = "#line $line '$file_name" ;

my($name, $triggered_node_and_triggers) = @_ ;
my ($triggered_node, @triggers) = @$triggered_node_and_triggers ;

PrintDebug DumpTree(\@_, "SimplifiedAddTriggers") if $display_simplified_rule_transformation ;

for my $trigger (@triggers)
	{
	PrintDebug ref $trigger  . "\n" ;
	unless('Regexp' eq ref $trigger)
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
			PrintError($build_message) ;
			PbsDisplayErrorWithContext($file_name,$line) ;
			die ;
			}
			
		my $original = $trigger ;
		$trigger = qr/^$trigger_path_regex$trigger_prefix_regex$trigger_regex$/ ;
		
		if($display_simplified_rule_transformation)
			{
			PrintDebug "Replacing '$original' by '$trigger' in SimplifiedAddTriggers rule '$name' at '$file_name,$line'\n" ;
			}
		}
	}

eval <<"EOE" ;
$location
PBS::Triggers::AddTrigger(\$name, [\$triggered_node, \@triggers]) ;
EOE
	die $@ if $@ ;
}	

#-------------------------------------------------------------------------------

sub SimplifiedAddSubpbsRule
{
my ($package, $file_name, $line) = caller() ;
my $location = "#line $line '$file_name" ;

my ($name, $node_regex, $Pbsfile, $pbs_package, @other_setup_data) = @_ ;

unless('Regexp' eq ref $node_regex)
	{
	PrintDebug DumpTree(\@_, "SimplifiedAddSubpbsRule") if $display_simplified_rule_transformation ;
	
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
			PrintDebug "Replacing '$original' by '$node_regex' in SimplifiedAddSubpbsRule rule '$name' at '$file_name,$line'\n" ;
			}
		
		eval <<"EOE" ;
$location
		PBS::Rules::AddSubpbsRule(\$name, \$node_regex, \$Pbsfile, \$pbs_package, \@other_setup_data) ;
EOE
		die $@ if $@ ;
		}
	else
		{	
		Carp::carp ERROR($build_message) ;
		PbsDisplayErrorWithContext($file_name,$line) ;
		die ;
		}
	}
else
	{
	eval <<"EOE" ;
	$location
	PBS::Rules::AddSubpbsRule(\$name, \$node_regex, \$Pbsfile, \$pbs_package, \@other_setup_data) ;
EOE
	die $@ if $@ ;
	}
}

#-------------------------------------------------------------------------------

sub SimplifiedAddRule
{
my ($package, $file_name, $line) = caller() ;
my $location = "#line $line '$file_name" ;

my ($types, $name, $creator, $dependent, $dependencies, $builder, $node_subs) = ParseRule($file_name, $line, @_) ;

my $is_meta_rule = grep{ $_ eq META_RULE } @$types ;

if('' eq ref $dependent and !$is_meta_rule)
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
		Carp::carp ERROR($dependency_regex_message) ;
		PbsDisplayErrorWithContext($file_name,$line) ;
		die ;
		}
		
	my $sub_dependent_regex = qr/^$dependent_path_regex($dependent_prefix_regex)$dependent_regex$/ ;
	
	if($display_simplified_rule_transformation)
		{
		PrintDebug "Replacing '$dependent' by '$sub_dependent_regex' in rule '$name' at '$file_name,$line'\n" ;
		}
	
	$dependencies = GeneratePurePerlTypeDependencies($dependencies) ;
	
	my $dependent_and_dependencies = [$sub_dependent_regex, @$dependencies];
	unshift @$dependent_and_dependencies, $creator if($creator) ;
		
	eval <<"EOE" ;
$location
	PBS::Rules::AddRule(\$types, \$name, \$dependent_and_dependencies, \$builder, \$node_subs) ;
EOE
	die $@ if $@ ;
	}
else	
	{
	eval "#line $line '$file_name'\n" . "PBS::Rules::AddRule(\@_) ;" ;
	die $@ if $@ ;
	}
} ;

#-------------------------------------------------------------------------------

{
no warnings 'redefine' ;

*AddRule = \&SimplifiedAddRule ;
*AddTrigger = \&SimplifiedAddTrigger ;
*AddSubpbsRule = \&SimplifiedAddSubpbsRule ;
}

#-------------------------------------------------------------------------------

sub GeneratePurePerlTypeDependencies
{
my ($dependencies) = @_ ;

for my $dependency (@$dependencies)
	{
	if('' eq ref $dependency)
		{
		PrintDebug "Replacing dependency '$dependency' by " if($display_simplified_rule_transformation) ;
		
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
			
		PrintDebug "'$dependency'\n" if($display_simplified_rule_transformation) ;
		}
	}

return ($dependencies);
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

return(0, 'Empty Regex definition') if $dependent_regex_definition eq '' ;

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

1 ;

