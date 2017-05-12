
package PBS::Information ;
use PBS::Debug ;

use 5.006 ;
use strict ;
use warnings ;
use Data::Dumper ;
use Data::TreeDumper ;
use Carp ;

require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw(DisplayCloseMatches) ;
our $VERSION = '0.04' ;

use PBS::Output ;
use PBS::Constants ;

#-------------------------------------------------------------------------------

sub DisplayNodeInformation
{
my $file_tree      = shift ;
my $pbs_config     = shift ;
my $name           = $file_tree->{__NAME} ;
my $build_name     = $file_tree->{__BUILD_NAME} || '' ;

my $current_node_info = '' ;
my $log_node_info     = '' ;
my $node_info         = '' ;

my $no_output = defined $PBS::Shell::silent_commands && defined $PBS::Shell::silent_commands_output ;
$no_output = 0 if($pbs_config->{BUILD_AND_DISPLAY_NODE_INFO} || scalar(@{$pbs_config->{DISPLAY_NODE_INFO}})) ;
$no_output = 1 if defined $pbs_config->{DISPLAY_NO_BUILD_HEADER} ;

return if((! defined $pbs_config->{CREATE_LOG}) && $no_output) ;

#----------------------
# header
#----------------------
my $type ='' ;
if($file_tree->{__VIRTUAL} || $file_tree->{__FORCED} || $file_tree->{__LOCAL})
	{
	$type .= '[' ;
	$type .= 'V' if($file_tree->{__VIRTUAL}) ;
	$type .= 'F' if($file_tree->{__FORCED}) ;
	$type .= 'L' if($file_tree->{__LOCAL}) ;
	$type .= '] ' ;
	}
	
if($pbs_config->{DISPLAY_BUILDER_INFORMATION})
	{
	if(PBS::Build::NodeBuilderUsesPerlSubs($file_tree))
		{
		$type .= '<P> ' ;
		}
	else
		{
		$type .= '<S> ' ;
		}
	}
	
my $columns = length("Node $type'$name':") ;
my $separator = INFO ('#' . ('-' x ($columns - 1)) . "\n")  ;
my $node_header = $separator ;

if(defined $pbs_config->{DISPLAY_NODE_BUILD_NAME})
	{
	$node_header .= INFO ("Node $type'$name' [$build_name]:\n") ;
	}
else
	{
	$node_header .= INFO ("Node $type'$name':\n") ;
	}
	
$node_header .= $separator ;

$node_info .= $node_header unless $no_output ;
$log_node_info .= INFO ("Node $type'$name' [$build_name]:\n") if(defined $pbs_config->{CREATE_LOG});

#----------------------
#insertion origin
#----------------------
if(defined $pbs_config->{CREATE_LOG} || defined $pbs_config->{DISPLAY_NODE_ORIGIN})
	{
	$current_node_info = INFO "\tInserted at $file_tree->{__INSERTED_AT}{INSERTION_FILE} " ;
	$current_node_info .= INFO "[$file_tree->{__INSERTED_AT}{INSERTION_PACKAGE}]:" if defined $file_tree->{__INSERTED_AT}{INSERTION_PACKAGE} ;
	$current_node_info .= INFO "$file_tree->{__INSERTED_AT}{INSERTION_RULE}.\n" ;

	$log_node_info .= $current_node_info  if(defined $pbs_config->{CREATE_LOG});

	if(defined $pbs_config->{DISPLAY_NODE_ORIGIN})
		{
		$node_info .= $current_node_info ;
		}
	}
	
#----------------------
# dependencies
#----------------------
my (@dependencies, @located_dependencies) ;
my (@triggered_dependencies, @display_triggered_dependencies, %triggered_dependencies_build_names) ;
my @display_triggered_dependencies_located ;

if(defined $pbs_config->{CREATE_LOG} || $pbs_config->{DISPLAY_NODE_DEPENDENCIES} || $pbs_config->{DISPLAY_NODE_BUILD_CAUSE})
	{
	for (keys %$file_tree)
		{
		next if($_ =~ /^__/) ;
		
		push @dependencies, $file_tree->{$_}{__NAME} ;
		
		if(exists $file_tree->{$_}{__BUILD_NAME})
			{
			push @located_dependencies, $file_tree->{$_}{__BUILD_NAME} ;
			}
		}
		
	if(exists $file_tree->{__TRIGGERED})
		{
		for my $triggered_dependency_data (@{$file_tree->{__TRIGGERED}})
			{
			next if(ref $triggered_dependency_data eq 'PBS_FORCE_TRIGGER') ;
				
			my $dependency_name = $triggered_dependency_data->{NAME} ;
			
			if($dependency_name !~ /^__/ && ! exists $triggered_dependencies_build_names{$dependency_name})
				{
				push @triggered_dependencies, $file_tree->{$dependency_name}{__BUILD_NAME} ;
				
				if('' eq ref $triggered_dependency_data)
					{
					$triggered_dependencies_build_names{$dependency_name} = $file_tree->{$dependency_name}{__BUILD_NAME} ;
					}
				else
					{
					$triggered_dependencies_build_names{$dependency_name} = 'no build name' ;
					}
				}
				
			# only for display
			my $dependency_display_string = $dependency_name . ' (' . $triggered_dependency_data->{REASON} . ')' ;
			
			if
				(
				   $dependency_name =~ /^__/ 
				|| 
					(
					   exists $triggered_dependencies_build_names{$dependency_name}
					&& $triggered_dependencies_build_names{$dependency_name} eq $dependency_name)
					)
				{
				#fine
				}
			else
				{
				push @display_triggered_dependencies_located, "$triggered_dependencies_build_names{$dependency_name}" ;
				}
			
			push @display_triggered_dependencies, $dependency_display_string ;
			}
		}
	
	$current_node_info = INFO ("\tdependencies:\n") ;
	do {$current_node_info .= INFO ("\t\t$_\n") ;} for @dependencies;
	
	#----------------------
	# located dependencies
	#----------------------
	if($pbs_config->{DISPLAY_NODE_INFO_LOCATED})
		{
		$current_node_info .= INFO ("\tidem but located:\n") ;
		do {$current_node_info .= INFO ("\t\t$_\n") ;} for @located_dependencies;
		}
		
	$log_node_info .= $current_node_info if(defined $pbs_config->{CREATE_LOG});
	$node_info     .= $current_node_info if($pbs_config->{DISPLAY_NODE_DEPENDENCIES}) ;
	}
	
#----------------------
#build cause
#----------------------
if(defined $pbs_config->{CREATE_LOG} || $pbs_config->{DISPLAY_NODE_BUILD_CAUSE})
	{
	$current_node_info = INFO ("\trebuild because of:\n") ;
	do {$current_node_info .= INFO ("\t\t$_\n") ;} for @display_triggered_dependencies ;
	
	#----------------------
	#build cause located
	#----------------------
	if($pbs_config->{DISPLAY_NODE_INFO_LOCATED})
		{
		$current_node_info .= INFO ("\tidem but located:\n") ;
		do {$current_node_info .= INFO ("\t\t$_\n") ;} for @display_triggered_dependencies_located ;
		}
		
	$log_node_info .= $current_node_info if defined $pbs_config->{CREATE_LOG} ;
	
	if($pbs_config->{DISPLAY_NODE_BUILD_CAUSE} && @display_triggered_dependencies)
		{
		$node_info .= $current_node_info ;
		}
	}
	
#----------------------
# matching rules
#----------------------
my @rules_with_builders ;
my $builder = 0 ;

if(defined $pbs_config->{CREATE_LOG} || $pbs_config->{DISPLAY_NODE_BUILD_RULES} || $pbs_config->{DISPLAY_NODE_BUILDER})
	{
	my $builder_override ;
		
	for my $rule (@{$file_tree->{__MATCHING_RULES}})
		{
		my $rule_number = $rule->{RULE}{INDEX} ;
		my $dependencies_and_build_rules = $rule->{RULE}{DEFINITIONS} ;
		
		$builder          = $dependencies_and_build_rules->[$rule_number]{BUILDER} ;
		$builder_override = $rule->{RULE}{BUILDER_OVERRIDE} ;
		
		#~ my $rule_dependencies = join ' ', map {$_->{NAME}} @{$rule->{DEPENDENCIES}} ;
		
		#~ my $creator ;
		#~ for my $rule_type (@{$rule->{DEFINITION}{TYPE}})
			#~ {
			#~ $creator++ if(CREATOR eq $rule_type) ;
			#~ }
			
		my $builder_override_tag ;
		if(defined $builder_override)
			{
			if(defined $builder_override->{BUILDER})
				{
				$builder_override_tag = '[BO]' ;
				
				my $rule_info =
					{
					  INDEX => $rule_number
					, DEFINITION => $builder_override
					} ;
					
				$rule_info->{OVERRIDES_OWN_BUILDER}++ if($builder);
				
				push @rules_with_builders, $rule_info ;
				}
			else
				{
				$builder_override_tag = '[B = undef! in Override]' ;
				}
			}
		else
			{
			if(defined $builder)
				{
				push @rules_with_builders, {INDEX => $rule_number, DEFINITION => $dependencies_and_build_rules->[$rule_number] } ;
				}
			}
			
		my $rule_dependencies ;
		if(@{$rule->{DEPENDENCIES}})
			{
			$rule_dependencies = join ' ', map {$_->{NAME}} @{$rule->{DEPENDENCIES}} ;
			}
		else
			{
			$rule_dependencies = 'no derived dependency from this rule' ;
			}
			
		my $rule_tag = '' ;
		$rule_tag .= '[B]'  if defined $builder ;
		$rule_tag .= '[BO]' if defined $builder_override ;
		$rule_tag .= '[S]'  if defined $file_tree->{__INSERTED_AT}{NODE_SUBS} ;
		#~ $rule_tag .= '[CREATOR]' if $creator;
		
		my $rule_info = $dependencies_and_build_rules->[$rule_number]{NAME}
							. $dependencies_and_build_rules->[$rule_number]{ORIGIN} ;
							
		$current_node_info = INFO ("\tmatching rule: #$rule_number$rule_tag '$rule_info'\n") ;
		$current_node_info .= INFO ("\t\t=> $rule_dependencies\n") ;
		
		$log_node_info .= $current_node_info if(defined $pbs_config->{CREATE_LOG}) ;
		$node_info     .= $current_node_info if($pbs_config->{DISPLAY_NODE_BUILD_RULES}) ;
		}
	}
	
#----------------------
# node config
#----------------------
if(defined $pbs_config->{CREATE_LOG} || $pbs_config->{DISPLAY_NODE_CONFIG})
	{
	if(defined $file_tree->{__CONFIG})
		{
		$current_node_info = INFO 
									(
									DumpTree
										(
										$file_tree->{__CONFIG}
										, "Build config"
										, INDENTATION => '        '
										)
									) ;
									
		}
	else
		{
		$current_node_info = '' ;
		}
		
	$log_node_info .= $current_node_info if(defined $pbs_config->{CREATE_LOG}) ;
	$node_info     .= $current_node_info if($pbs_config->{DISPLAY_NODE_CONFIG}) ;
	}
	
#----------------------
#builder
#----------------------
my $more_than_one_builder = 0 ;

# choose last builder if multiple Builders
if(defined $pbs_config->{CREATE_LOG} || $pbs_config->{DISPLAY_NODE_BUILDER})
	{
	if(@rules_with_builders)
		{
		my $rule_used_to_build = $rules_with_builders[-1] ;
		   $builder            = $rule_used_to_build->{DEFINITION}{BUILDER} ;
		
		my $rule_tag = '' ;
		unless(exists $rule_used_to_build->{DEFINITION}{SHELL_COMMANDS_GENERATOR})
			{
			$rule_tag = "[P]" ;
			}
			
		my $rule_info = $rule_used_to_build->{INDEX} 
				. $rule_tag
				. " '"
				. $rule_used_to_build->{DEFINITION}{NAME}
				. $rule_used_to_build->{DEFINITION}{ORIGIN}
				. "'" ;
							
		$current_node_info = INFO ("\tUsing builder from rule: #$rule_info\n") ;
		
		$log_node_info .= $current_node_info if(defined $pbs_config->{CREATE_LOG}) ;
		$node_info     .= $current_node_info if($pbs_config->{DISPLAY_NODE_BUILDER}) ;
		}
	}
		

#-----------------------------------------
# display override information
#-----------------------------------------
if(@rules_with_builders)
	{
	for my $rule (@rules_with_builders)
		{
		# display override information
		
		my $rule_info =  $rule->{DEFINITION}{NAME}
							. $rule->{DEFINITION}{ORIGIN} ;
		
		my $overriden_rule_info = '' ;
		for my $overriden_rule_type (@{$rule->{DEFINITION}{TYPE}})
			{
			if(CREATOR eq $overriden_rule_type)
				{
				$overriden_rule_info .= '[CREATOR] ' ;
				}
			}
			
		# display if the rule generated a  builder override and had builder in its definition.
		my $current_node_info = '' ;
		
		if($rule->{OVERRIDES_OWN_BUILDER} || $rule->{DEFINITION}{BUILDER} != $builder)
			{
			$current_node_info = $node_header if $no_output ; # force a header  when displaying a warning
			}
			
		if($rule->{OVERRIDES_OWN_BUILDER})
			{
			$current_node_info .= WARNING ("\tRule Overrides its own builder: $overriden_rule_info#$rule->{INDEX} '$rule_info'.\n") ;
			}
			
		if($rule->{DEFINITION}{BUILDER} != $builder)
			{
			# override from a rule to another
			$current_node_info .= WARNING ("\tIgnoring Builder from rule: $overriden_rule_info#$rule->{INDEX} '$rule_info'.\n") ;
			}
			
		$log_node_info .= $current_node_info ;
		$node_info     .= $current_node_info ;
		}
	}

#-------------------------------------------------
#display shell and commands if any
#-------------------------------------------------
if(@{$pbs_config->{DISPLAY_BUILD_INFO}})
	{
	#display shell and commands if any
	}
	
#----------------------
# post build
#----------------------
if(defined $pbs_config->{CREATE_LOG} || $pbs_config->{DISPLAY_NODE_BUILD_POST_BUILD_COMMANDS})
	{
	if(defined $file_tree->{__POST_BUILD_COMMANDS})
		{
		$current_node_info = INFO ("\tPost Build Commands:\n") ;
		
		for my $post_build_command (@{$file_tree->{__POST_BUILD_COMMANDS}})
			{
			my $rule_info = $post_build_command->{NAME}
								. $post_build_command->{ORIGIN} ;
			$current_node_info .= INFO ("\t\t$rule_info\n") ;
			}
			
		$log_node_info .= $current_node_info if(defined $pbs_config->{CREATE_LOG}) ;
		$node_info     .= $current_node_info if($pbs_config->{DISPLAY_NODE_BUILD_POST_BUILD_COMMANDS}) ;
		}
	}
	
my $log_handle = $pbs_config->{CREATE_LOG} ;
print $log_node_info if(defined $log_handle) ;

print STDOUT $node_info ;
}

#----------------------------------------------------------------------

sub DisplayCloseMatches
{
# displays the nodes that match a  simple regex

my $node_name = shift ;
my $tree = shift ;

my @matches ;
for (keys %$tree)
	{
	if( $tree->{$_}{__NAME} =~ /$node_name/)
		{
		push @matches, $tree->{$_}{__NAME} ;
		}
	}

if(@matches)
	{
	PrintInfo("PBS found:\n") ;
	
	for (@matches)
		{
		PrintInfo("\t$_\n") ;
		}
	}
}

#-------------------------------------------------------------------------------

sub GetParentsNames
{
my $node = shift ;

map {/^([^:]+)/; $1} grep {! /^__/} keys %{$node->{__DEPENDENCY_TO}} ;
}

#----------------------------------------------------------------------
1 ;

__END__
=head1 NAME

PBS::Information  -

=head1 SYNOPSIS

  use PBS::Information ;
  DisplayNodeInformation($node, $pbs_config) ;

=head1 DESCRIPTION

I<DisplayNodeInformation> print information about a node to STDERR and to the B<PBS> log. The amount of information displayed
depend on the configuration passed to the function. The configuration can be controled through I<pbs> commmand line switches.

=head2 EXPORT

None.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=cut
