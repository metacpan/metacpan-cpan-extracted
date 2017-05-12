package PBS::Rules::Builders ;

use PBS::Debug ;

use 5.006 ;

use strict ;
use warnings ;
use Data::TreeDumper ;
use Carp ;
 
require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw(GenerateBuilder) ;
our $VERSION = '0.01' ;

use File::Basename ;

use PBS::Shell ;
use PBS::PBSConfig ;
use PBS::Output ;
use PBS::Constants ;
use PBS::Rules ;
use PBS::Plugin;

#-------------------------------------------------------------------------------

sub GenerateBuilder
{
my ($shell, $builder, $package, $name, $file_name, $line) = @_ ;

my @builder_node_subs_and_type ;

if(defined $builder)
	{
	for (ref $builder)
		{
		($_ eq '' || $_ eq 'ARRAY') and do
			{
			@builder_node_subs_and_type = GenerateBuilderFromStringOrArray(@_) ;
			last ;
			} ;
			
		($_ eq 'CODE') and do
			{
			@builder_node_subs_and_type = GenerateBuilderFromSub(@_) ;
			last ;
			} ;
			
		die ERROR "Invalid Builder definition for '$name' at '$file_name:$line'\n" ;
		}
	}
	
	
return(@builder_node_subs_and_type) ;
}

#-------------------------------------------------------------------------------

sub GenerateBuilderFromStringOrArray
{
# generate sub that runs a shell command from the definition given in the Pbsfile

my ($shell, $builder, $package, $name, $file_name, $line) = @_ ;

$shell = new PBS::Shell() unless defined $shell ;
 
my $shell_commands ;
if(ref $builder eq '')
	{
	$shell_commands = [$builder] ; # single string
	}
else
	{
	$shell_commands = $builder ; # array of strings and perl sub refs
	}

my $builder_uses_perl_sub ;
# we must mark the rule as meta rules shall not be marked as builders using sub if the used slave rule doesn't use a sub!

for (@$shell_commands)
	{
	if(ref $_ eq '')
		{
		next ;
		}
		
	if(ref $_ eq 'CODE')
		{
		$builder_uses_perl_sub++ ;
		next ;
		}
		
	die ERROR "Invalid command for '$name' at '$file_name:$line'\n" ;
	}

my @node_subs_from_builder_generator ;

my %rule_type ;
unless($builder_uses_perl_sub)
	{
	my $shell_command_generator =
		# nadim 12 june 2005, let's try to minimize  memory consumption
		# more can be done but this was an easy testl
		sub 
		{
		return
			(
			ShellCommandGenerator
				(
				$shell_commands, $name, $file_name, $line
				, @_
				)
			) ;
		} ;
			
	$rule_type{SHELL_COMMANDS_GENERATOR} = $shell_command_generator ;
	
	push @node_subs_from_builder_generator,
		sub # node_sub
		{
		my (
		  $dependent_to_check
		, $config
		, $tree
		, $inserted_nodes
		) = @_ ;
		
		$tree->{__SHELL_COMMANDS_GENERATOR} = $shell_command_generator ;
		push @{$tree->{__SHELL_COMMANDS_GENERATOR_HISTORY}}, "rule '$name' @ '$file_name:$line'";
		} ;
	}
	
# nadim 12 june 2005, let's try to minimize  memory consumption
# more can be done but this was an easy test
my $generated_builder = 
	sub 
	{
	return
		(
		BuilderFromStringOrArray
			(
			$shell_commands, $shell, $package, $name, $file_name, $line
			, @_
			)
		) ;
	} ;

return($generated_builder, \@node_subs_from_builder_generator, \%rule_type) ;
}

#-------------------------------------------------------------------------------

# nadim 12 june 2005, let's try to minimize  memory consumption
sub ShellCommandGenerator
{
my (
# these could be computed from the tree (if the information is pushed before this sub is called)
$shell_commands, $name, $file_name, $line

# this is passed by pbs when inserting nodes
, $tree
) = @_;

my @evaluated_shell_commands ;
for my $shell_command (@{[@$shell_commands]}) # use a copy of @shell_commands, perl bug ???
	{
	push @evaluated_shell_commands, EvaluateShellCommandForNode
						(
						$shell_command
						, "rule '$name' at '$file_name:$line'"
						, $tree
						) ;
	}
	
return(@evaluated_shell_commands) ;
}

#-------------------------------------------------------------------------------

# nadim 12 june 2005, let's try to minimize  memory consumption
sub BuilderFromStringOrArray
{
#this is generated but it should be possible to generate it at node build  time
my($shell_commands, $shell, $package, $name, $file_name, $line) = splice(@_, 0, 6) ;

# the rest is generic and we should generate a sub for each rule  but reuse
my ($config, $file_to_build, $dependencies, $triggering_dependencies, $tree, $inserted_nodes) = @_ ;

my $node_shell = $shell ;
my $is_node_local_shell = '' ;

if(exists $tree->{__SHELL_OVERRIDE})
	{
	if(defined $tree->{__SHELL_OVERRIDE})
		{
		$node_shell = $tree->{__SHELL_OVERRIDE} ;
		$is_node_local_shell = ' [N]'
		}
	else
		{
		Carp::carp ERROR("Node defined shell override for node '$tree->{__NAME}' exists but is not defined!\n") ;
		die ;
		}
	}
	
$tree->{__SHELL_INFO} = $node_shell->GetInfo() ; # :-) doesn't help as this might not be in the root process
if($tree->{__PBS_CONFIG}{DISPLAY_SHELL_INFO})
	{
	PrintWarning "Using shell$is_node_local_shell: '$tree->{__SHELL_INFO}' " ;
	
	if(exists $tree->{__SHELL_ORIGIN} && $tree->{__PBS_CONFIG}{ADD_ORIGIN})
		{
		PrintWarning "set at $tree->{__SHELL_ORIGIN}" ;
		}
		
	print "\n" ;
	}
	
for my $shell_command (@{[@$shell_commands]}) # use a copy of @shell_commands, perl bug ???
	{
	if('CODE' eq ref $shell_command)
		{
		my @result = $node_shell->RunPerlSub($shell_command, @_) ;
		
		if($result[0] == 0)
			{
			# command failed
			return(@result) ;
			}
			
		}
	else
		{
		my $command = EvaluateShellCommandForNode
						(
						$shell_command
						, "rule '$name' at '$file_name:$line'"
						, $tree
						, $dependencies
						, $triggering_dependencies
						) ;
						
		$node_shell->RunCommand($command) ;
		}
	}
	
return(1 , "OK Building $file_to_build") ;
}

#-------------------------------------------------------------------------------

sub GenerateBuilderFromSub
{
my ($shell, $builder, $package, $name, $file_name, $line) = @_ ;

$shell = new PBS::Shell() unless defined $shell ;
 
my $generated_builder = 
	sub
	{ 
	return(BuilderFromSub($shell, $builder, $package, $name, $file_name, $line, @_)) ;
	} ;

my %rule_type ;

return($generated_builder, undef, \%rule_type) ;
}

#-------------------------------------------------------------------------------

# nadim 12 june 2005, let's try to minimize  memory consumption
sub BuilderFromSub
{
# note that this sub does very little. it only does some display to finally call the suplied sub

# could be computed at node build time
my ($shell, $builder, $package, $name, $file_name, $line) = splice(@_, 0, 6) ;

my ($config, $file_to_build, $dependencies, $triggering_dependencies, $tree, $inserted_nodes) = @_ ;

my $node_shell = $shell ;
my $is_node_local_shell = '' ;

if(exists $tree->{__SHELL_OVERRIDE})
	{
	if(defined $tree->{__SHELL_OVERRIDE})
		{
		$node_shell = $tree->{__SHELL_OVERRIDE} ;
		$is_node_local_shell = ' [N]'
		}
	else
		{
		Carp::carp ERROR("Node defined shell for node '$tree->{__NAME}' exists but is not defined!\n") ;
		die ;
		}
	}
	
$tree->{__SHELL_INFO} = $node_shell->GetInfo() ; # :-) doesn't help as this might not be in the root process
	
if($tree->{__PBS_CONFIG}{DISPLAY_SHELL_INFO})
	{
	PrintWarning "Using shell$is_node_local_shell: '$tree->{__SHELL_INFO}' " ;
	
	if(exists $tree->{__SHELL_ORIGIN} && $tree->{__PBS_CONFIG}{ADD_ORIGIN})
		{
		PrintWarning "set at $tree->{__SHELL_ORIGIN}" ;
		}
		
	print "\n" ;
	}
	
return
	(
	$node_shell->RunPerlSub($builder, @_)
	) ;
} ;

#-------------------------------------------------------------------------------

sub EvaluateShellCommandForNode
{
my($shell_command, $shell_command_info, $tree, $dependencies, $triggered_dependencies) = @_ ;

RunPluginSubs($tree->{__PBS_CONFIG}, 'EvaluateShellCommand', \$shell_command, $tree, $dependencies, $triggered_dependencies) ;

my $config = $tree->{__CONFIG} ;
my $file_to_build = $tree->{__BUILD_NAME} || GetBuildName($tree->{__NAME}, $tree);

my @dependencies ;
unless(defined $dependencies)
	{
	#extract them from tree if not passed as argument
	@dependencies = map {$tree->{$_}{__BUILD_NAME} ;} grep { $_ !~ /^__/ && exists $tree->{$_}{__BUILD_NAME}}(keys %$tree) ;
	}
else
	{
	#~ @dependencies = grep {defined $_} @$dependencies ;
	@dependencies = @$dependencies ;
	}

my $dependency_list = join ' ', @dependencies ;

my $build_directory = $tree->{__PBS_CONFIG}{BUILD_DIRECTORY} ;
my $dependency_list_relative_build_directory = join(' ', map({my $copy = $_; $copy =~ s/\Q$build_directory\E[\/|\\]// ; $copy} @dependencies)) ;

my @triggered_dependencies ;

unless(defined $dependencies)
	{
	# build a list of triggering dependencies and weed out doublets
	my %triggered_dependencies_build_names ;
	for my $triggering_dependency (@{$tree->{__TRIGGERED}})
		{
		my $dependency_name = $triggering_dependency->{NAME} ;
		
		if($dependency_name !~ /^__/ && ! exists $triggered_dependencies_build_names{$dependency_name})
			{
			push @triggered_dependencies, $tree->{$dependency_name}{__BUILD_NAME} ;
			$triggered_dependencies_build_names{$dependency_name} = $tree->{$dependency_name}{__BUILD_NAME} ;
			}
		}
	}
else
	{
	@triggered_dependencies = @$triggered_dependencies ;
	}
	
my $triggered_dependency_list = join ' ', @triggered_dependencies ;

my ($basename, $path, $ext) = File::Basename::fileparse($file_to_build, ('\..*')) ;
$path =~ s/\/$// ;

$shell_command =~ s/\%BUILD_DIRECTORY/$build_directory/g ;

$shell_command =~ s/\%FILE_TO_BUILD_PATH/$path/g ;
$shell_command =~ s/\%FILE_TO_BUILD_NAME/$basename$ext/g ;
$shell_command =~ s/\%FILE_TO_BUILD_BASENAME/$basename/g ;
$shell_command =~ s/\%FILE_TO_BUILD_NO_EXT/$path\/$basename/g ;
$shell_command =~ s/\%FILE_TO_BUILD/$file_to_build/g ;

$shell_command =~ s/\%DEPENDENCY_LIST_RELATIVE_BUILD_DIRECTORY/$dependency_list_relative_build_directory/g ;
$shell_command =~ s/\%TRIGGERED_DEPENDENCY_LIST/$triggered_dependency_list/g ;
$shell_command =~ s/\%DEPENDENCY_LIST/$dependency_list/g ;

$shell_command = PBS::Config::EvalConfig($shell_command, $config, "Shell command", $shell_command_info) ;

return($shell_command) ;
}

#-------------------------------------------------------------------------------

sub GetBuildName
{
my ($dependent, $file_tree) = @_ ;

my $build_directory    = $file_tree->{__PBS_CONFIG}{BUILD_DIRECTORY} ;
my $source_directories = $file_tree->{__PBS_CONFIG}{SOURCE_DIRECTORIES} ;

my ($full_name, $is_alternative_source, $other_source_index) = PBS::Check::LocateSource($dependent, $build_directory, $source_directories) ;

return($full_name) ;
}

#-------------------------------------------------------------------------------

1 ;

__END__
=head1 NAME

PBS::Rules::Builders -

=head1 DESCRIPTION

This package provides support function for B<PBS::Rules::Rules>

=head2 EXPORT

Nothing.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=head1 SEE ALSO

B<PBS> reference manual.

=cut
