
=head1 Plugin  EvaluateShellCommand

Let the Build system author evaluate shell commands before they are run.  This allows
her to add variables like %SOME_SPECIAL_VARIABLE without interfering with PBS.

%PBS_REPOSITORIES is handled in this plugin. The default handling replaces %PBS_REPOSITORIES
with the path to the node to be build in each source directory. 

Special handling of repositories and include paths is left to the user (thus this user modifiable plugin) as there
is no consensus about which of those has precedence. building object nodes through a perl sub is another solution
where the user has total control.

=over 2

=item  --evaluate_shell_command_verbose

=back

=cut

use PBS::PBSConfigSwitches ;
use PBS::PBSConfig ;
use PBS::Information ;
use Data::TreeDumper ;

#-------------------------------------------------------------------------------

my $evaluate_shell_command_verbose ;

PBS::PBSConfigSwitches::RegisterFlagsAndHelp
	(
	  'evaluate_shell_command_verbose'
	, \$evaluate_shell_command_verbose
	, "Will display the transformation this plugin does."
	, ''
	) ;
	
use PBS::Build::NodeBuilder ;

#-------------------------------------------------------------------------------

sub EvaluateShellCommand
{
my ($shell_command_ref, $tree, $dependencies, $triggered_dependencies) = @_ ;

if($evaluate_shell_command_verbose)
	{
	PrintDebug "'EvaluateShellCommand' plugin handling '$tree->{__NAME}' shell command:\n      $$shell_command_ref\n" ;
	}

my @repository_paths = PBS::Build::NodeBuilder::GetNodeRepositories($tree) ;

# handle %PBS_REPOSITORIES
my %pbs_repositories_replacements ;

while($$shell_command_ref =~ /([^\s]+)?\%PBS_REPOSITORIES/g)
	{
	my $prefix = $1 || '' ;
	
	next if exists $pbs_repositories_replacements{"${prefix}\%PBS_REPOSITORIES"} ;
	
	my $replacement = '';
	for my $repository_path (@repository_paths)
		{
		if($evaluate_shell_command_verbose)
			{
			PrintDebug "      repository: $repository_path\n" ;
			}
			
		$replacement .= "$prefix$repository_path ";
		}
		
	$pbs_repositories_replacements{"${prefix}\%PBS_REPOSITORIES"} = $replacement ;
	}
	
for my $field_to_replace (keys %pbs_repositories_replacements)
	{
	$$shell_command_ref =~ s/$field_to_replace/$pbs_repositories_replacements{$field_to_replace}/g ;
	}

if($evaluate_shell_command_verbose)
	{
	PrintDebug "   => $$shell_command_ref\n\n" ;
	}
}

#-------------------------------------------------------------------------------

1 ;

