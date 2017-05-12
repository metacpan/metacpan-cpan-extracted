
use strict ;
use warnings ;
use Data::Dumper ;
use Carp ;

use PBS::Output ;
use PBS::Constants;

#--------------------------------------------------------------------------------
sub FirstAndOnlyOneOnDisk
{
use constant NO_DEPENDENCIES_FOR_NODE => 0 ;

my ($dependent, $config, $tree, $inserted_files, $rule_references, $default_rule_name) = @_ ;

return([NO_DEPENDENCIES_FOR_NODE, "Private data can't have dependencies!"]) if $dependent =~ /^__/ ;

my $pbs_config         = $tree->{__PBS_CONFIG} ;
my $build_directory    = $pbs_config->{BUILD_DIRECTORY} ;
my @source_directories = @{$pbs_config->{SOURCE_DIRECTORIES}} ;

my $rule_defining_file_on_disk   = undef ;
my $default_rule_name_definition = undef ;

for my $rule (@$rule_references)
	{
	#~ print "meta running $rule->{NAME}\n" ;
	
	my ($dependency_result, $builder_override) = $rule->{DEPENDER}->($dependent, $config, $tree, $inserted_files, $rule) ;
	
	my ($triggered, @dependencies) = @$dependency_result ;
	
	if(@dependencies > 1)
		{
		PrintError("rule '$rule->{NAME}' defines more than one dependency. 'FirstAndOnlyOneOnDisk' doesn't support this.\n") ;
		die ;
		}
		
	if($triggered)
		{
		#~ PrintDebug "'$dependent' = $rule->{NAME} => $dependencies[0]\n" ;
		#~ print Dumper($pbs_config) ;
		
		my ($full_name) = PBS::Check::LocateSource
									(
									  $dependencies[0]
									, $build_directory
									, \@source_directories
									, $pbs_config->{DISPLAY_SEARCH_INFO} || 0
									, $pbs_config->{DISPLAY_SEARCH_ALTERNATES} || 0
									) ;
		
		my $current_rule_definition = {
												  NAME => $dependencies[0]
												, FULL_NAME => $full_name
												, RULE => $rule
												, BUILDER_OVERRIDE => $builder_override
												} ;
											
		if(-e $full_name)
			{
			if(defined $rule_defining_file_on_disk)
				{
				PrintError("Found '$full_name' on disk for rule '$rule->{NAME}'.\n") ;
				PrintError("But 'FirstAndOnlyOneOnDisk'already found '$rule_defining_file_on_disk->{FULL_NAME}'") ;
				PrintError(" on disk with rule '$rule_defining_file_on_disk->{RULE}{NAME}'.\n") ;
				die ;
				}
			else
				{
				$rule_defining_file_on_disk = $current_rule_definition ;
				}
			}
		
		if(defined $default_rule_name && $default_rule_name eq $rule->{NAME})
			{
			$default_rule_name_definition = $current_rule_definition ;
			}
		}
	}
	
my $rule_definition = $rule_defining_file_on_disk || $default_rule_name_definition ;

if(defined $rule_definition)
	{
	return
		(
		  [1, $rule_definition->{NAME}] 
		, $rule_definition->{BUILDER_OVERRIDE} || $rule_definition->{RULE}
		) ;	
	}
else
	{
	return([NO_DEPENDENCIES_FOR_NODE, 'No dependencies']) ;
	}
} ;

#----------------------------------------------------------------------------------------

1 ;

