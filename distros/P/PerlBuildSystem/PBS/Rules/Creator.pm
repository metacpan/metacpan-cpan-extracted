
package PBS::Rules::Creator;

use 5.006 ;

use strict ;
use warnings ;
use Carp ;
 
require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw(GenerateCreator) ;
our $VERSION = '0.01' ;

#-------------------------------------------------------------------------------

use File::Basename ;
use Getopt::Long ;
use Cwd ;
use Data::TreeDumper ;
use File::Path ;
use Digest::MD5 qw(md5_hex) ;

#-------------------------------------------------------------------------------

use PBS::Constants ;
use PBS::Depend ;
use PBS::PBSConfig ;
use PBS::Output ;
use PBS::Rules::Builders ;

#---------------------------------------------------------------------------------------

sub GenerateCreator
{
my $commands = shift ;
my $other_info_to_check = shift ;

return
	(
	sub
		{
		return(DefaultCreator(@_, $commands, $other_info_to_check)) ;
		}
	) ;
}

#---------------------------------------------------------------------------------------

sub DefaultCreator
{
# this creator verifies the dependencies that are passed by the rule definition 
# and will regenerate the $dependent if needed

my
(
  $dependent_to_check
, $config
, $tree
, $inserted_nodes
, $dependencies     # rule local
, $builder_override # rule local
, $rule_definition

# added by GenerateCreator wrapper
, $commands
, $other_info_to_check
) = @_ ;

my $rule_info = "'$rule_definition->{NAME}' @ '$rule_definition->{FILE}:$rule_definition->{LINE}'" ;
   
my ($triggered, @my_dependencies) ;

if(defined $dependencies && @$dependencies && $dependencies->[0] == 1 && @$dependencies > 1)
	{
	# previous depender defined dependencies
	$triggered       = $dependencies->[0] ;
	@my_dependencies = @{$dependencies}[1 .. @$dependencies - 1] ;
	
	my $need_rebuild = CheckCreatorDigest
				(
				  $dependent_to_check
				, $tree
				, \@my_dependencies # MD5 will be generated for these
				, $other_info_to_check
				) ;
	
	if(NEED_REBUILD == $need_rebuild)
		{
		DisplayNodeCreationInfo($tree, $rule_info) ;
		
		my $file_to_build = GetNodeBuildName($tree) ;
		
		my ($basename, $path, $ext) = File::Basename::fileparse($file_to_build, ('\..*')) ;
		mkpath($path) unless(-e $path) ;
		
		# verify the dependencies digest before creating the node
		GenerateCreatorDigest($dependent_to_check, $tree, \@my_dependencies, 0, $rule_info) ;
		
		my ($builder_sub) = GenerateBuilder # other elements returned by this sub are not valid at this point
					(
					  undef #shell
					, $commands
					, $tree->{__LOAD_PACKAGE}
					, $rule_definition->{NAME}
					, $rule_definition->{FILE}
					, $rule_definition->{LINE}
					) ;
				
		#TODO: missing debugger hooks here
		
		my ($build_result, $build_message) ;
		eval
		{
		my @located_dependencies = map {GetBuildName($_, $tree->{__PBS_CONFIG})} @my_dependencies ;
		
		#TODO: compute the triggered node
		my @located_triggered_dependencies = @located_dependencies ;
		
		($build_result, $build_message) = $builder_sub->
							(
							  $tree->{__CONFIG}
							, GetNodeBuildName($tree)
							, \@located_dependencies
							, \@located_triggered_dependencies #$triggered_dependencies
							, $tree
							, {} # not known at this time $inserted_nodes
							) ;
		} ;
		
		die ERROR("Faild creation of '$dependent_to_check' with $rule_info!\n" . DumpTree($@, 'Exception:')) if $@;
		
		unless(defined $build_result || $build_result == BUILD_SUCCESS || $build_result == BUILD_FAILED)
			{
			$build_result = BUILD_FAILED ;
			die ERROR "Faild creation of '$dependent_to_check' with creator $rule_info!\n" ;
			}
		
		WriteCreatorDigest
			(
			  $dependent_to_check
			, $tree
			, \@my_dependencies
			, $other_info_to_check
			, $rule_info
			) ;
		
		push @$dependencies, PBS::Depend::FORCE_TRIGGER("$dependent_to_check digest rebuilt.") ;
		}
	}

#this makes it unnecessay (and checked) that a rule with creator also has a builder.
$builder_override = GenerateCreatorBuilder($rule_definition->{NAME} . '_' . $dependent_to_check, $tree->{__LOAD_PACKAGE}) ;

return($dependencies, $builder_override) ;
}

#---------------------------------------------------------------------------------------

sub DisplayNodeCreationInfo
{
my $node = shift ;
my $rule_info = shift ;

my $pbs_config = $node->{__PBS_CONFIG} ;

my $no_output = defined $PBS::Shell::silent_commands && defined $PBS::Shell::silent_commands_output ;
$no_output = 0 if($pbs_config->{BUILD_AND_DISPLAY_NODE_INFO} || scalar(@{$pbs_config->{DISPLAY_NODE_INFO}})) ;
$no_output = 1 if defined $pbs_config->{DISPLAY_NO_BUILD_HEADER} ;

unless($no_output)
	{
	my $name = $node->{__NAME} ;
	my $build_name = GetNodeBuildName($node) ;
	$rule_info = 'Creator ' . $rule_info . "\n" ;
	
	my $node_header ;
	if(defined $pbs_config->{DISPLAY_NODE_BUILD_NAME})
		{
		$node_header = "Creating node '$name' [$build_name]:\n" ;
		}
	else
		{
		$node_header = "Creating node '$name':\n" ;
		}
	
	my $columns = length($rule_info) > length($node_header) ? length($rule_info) : length($node_header) ;
	my $separator = '#' . ('-' x ($columns - 1)) . "\n"  ;
	
	$node_header = $separator . $node_header  . $rule_info . $separator ;
	
	PrintInfo $node_header ;
	}
	
#TODO: Log
}

#---------------------------------------------------------------------------------------

sub CheckCreatorDigest
{
my ($dependent_to_check, $tree, $dependencies, $other_elements) = @_ ;

my $dependency_file_name = GetCreatorDependencyFileName($dependent_to_check, $tree) ;
my $dependency_file_needs_update = ! NEED_REBUILD ;

if(-e $dependency_file_name)
	{
	our ($digest) ;
	
	if(do $dependency_file_name) 
		{
		my %dependency_md5 ;
		
		unless('HASH' eq ref $digest)
				{
				PrintWarning("Creator: '$dependent_to_check' [Empty].\n") ;
				$dependency_file_needs_update = NEED_REBUILD ;
				}
				
		my $package_digest = PBS::Digest::GetPackageDigest($tree->{__LOAD_PACKAGE}) ;
		for my $key (keys %$package_digest) 
			{
			$dependency_md5{$key} = $package_digest->{$key} ;
			}
		
		for my $key (keys %$other_elements) 
			{
			$dependency_md5{$key} = $other_elements->{$key} ;
			}
			
		for my $dependency (keys %$digest)
			{
			last if $dependency_file_needs_update ;
			
			if(exists $dependency_md5{$dependency})
				{
				# compare with cached MD5
				if($digest->{$dependency} ne $dependency_md5{$dependency})
					{
					$dependency_file_needs_update = NEED_REBUILD ;
					last ;
					}
				}
			else
				{
				$dependency = GetBuildName($dependency, $tree->{__PBS_CONFIG}) ;
				
				my $dependency_md5 ;
				
				if(defined ($dependency_md5 = PBS::Digest::GetFileMD5($dependency)))
					{
					$dependency_md5{$dependency} = $dependency_md5 ;
					}
				else
					{
					PrintInfo("Creator: Can't compute MD5 for '$dependency' (found in dependency file)! Rebuilding!\n") ;
					$dependency_file_needs_update = NEED_REBUILD ;
					last ;
					}
					
				if($digest->{$dependency} ne $dependency_md5{$dependency})
					{
					if(defined $tree->{__PBS_CONFIG}{DISPLAY_C_DEPENDENCY_INFO})
						{
						PrintInfo("Creator: '$dependent_to_check' [MD5 difference]: '$dependency'.\n") ;
						}
						
					$dependency_file_needs_update = NEED_REBUILD ;
					last ;
					}
				}
			}
		}
	else
		{
		PrintWarning "Creator: Couldn't parse '$dependency_file_name': $@" if $@;
		$dependency_file_needs_update = NEED_REBUILD ;
		}
		
	}
else
	{
	if(defined $tree->{__PBS_CONFIG}{DISPLAY_C_DEPENDENCY_INFO})
		{
		PrintInfo("Creator: '$dependent_to_check' [No digest file].\n") ;
		}
		
	$dependency_file_needs_update = NEED_REBUILD ;
	}

return($dependency_file_needs_update) ;
}

#---------------------------------------------------------------------------------------

sub GenerateCreatorDigest
{
my ($dependent_to_check, $tree, $dependencies, $display_info, $caller_info) = @_ ;

if ($display_info)
	{
	PrintInfo "Creator: Generating creator digest for '$dependent_to_check' at rule $caller_info.\n" ;
	}

my %dependency_file_digest ;
my %dependency_md5 ;

for my $dependency (@$dependencies)
	{
	unless(exists $dependency_md5{$dependency})
		{
		$dependency = GetBuildName($dependency, $tree->{__PBS_CONFIG}) ;
		my $dependency_md5 ;
		
		if(defined ($dependency_md5 = PBS::Digest::GetFileMD5($dependency)))
			{
			$dependency_md5{$dependency} = $dependency_md5 ;
			}
		else
			{
			PrintError("Creator: Can't compute '$dependency' MD5 while generating digest for '$dependent_to_check' at rule $caller_info!\n") ;
			die ;
			}
		}
		
	$dependency_file_digest{$dependency} = $dependency_md5{$dependency} ;
	}

my $package_digest = PBS::Digest::GetPackageDigest($tree->{__LOAD_PACKAGE}) ;
for my $key (keys %$package_digest) 
	{
	$dependency_file_digest{$key} = $package_digest->{$key} ;
	}
	
return(\%dependency_file_digest) ;
}

#---------------------------------------------------------------------------------------

sub GetCreatorDependencyFileName
{
my ($dependent, $tree) = @_ ;

my $build_directory    = $tree->{__PBS_CONFIG}{BUILD_DIRECTORY} ;
my $source_directories = $tree->{__PBS_CONFIG}{SOURCE_DIRECTORIES} ;

my ($dependency_file_name, $is_alternative_source, $other_source_index) 
	= PBS::Check::LocateSource
		(
		  "$dependent.creator_md5"
		, $build_directory
		, $source_directories
		, $tree->{__PBS_CONFIG}{DISPLAY_SEARCH_INFO}
		, $tree->{__PBS_CONFIG}{DISPLAY_SEARCH_ALTERNATES}
		) ;
		
return(CollapsePath($dependency_file_name)) ;
}

#---------------------------------------------------------------------------------------

sub GetNodeBuildName
{
my ($node) = @_ ;

my $build_directory    = $node->{__PBS_CONFIG}{BUILD_DIRECTORY} ;
my $source_directories = $node->{__PBS_CONFIG}{SOURCE_DIRECTORIES} ;

my ($build_name, $is_alternative_source, $other_source_index) 
	= PBS::Check::LocateSource
		(
		  $node->{__NAME}
		, $build_directory
		, $source_directories
		, $node->{__PBS_CONFIG}{DISPLAY_SEARCH_INFO}
		, $node->{__PBS_CONFIG}{DISPLAY_SEARCH_ALTERNATES}
		) ;

return($build_name) ;
}

sub GetBuildName
{
my $name = shift ;
my $pbs_config = shift ;

my $build_directory    = $pbs_config->{BUILD_DIRECTORY} ;
my $source_directories = $pbs_config->{SOURCE_DIRECTORIES} ;

my ($build_name, $is_alternative_source, $other_source_index) = 
	PBS::Check::LocateSource
		(
		$name
		, $build_directory
		, $source_directories
 		, $pbs_config->{DISPLAY_SEARCH_INFO}
		, $pbs_config->{DISPLAY_SEARCH_ALTERNATES}
		) ;

return($build_name) ;
}

#---------------------------------------------------------------------------------------

sub WriteCreatorDigest
{
my ($dependent_to_check, $tree, $dependencies, $other_elements, $caller_info) = @_ ;

my $dependency_file_name = GetCreatorDependencyFileName($dependent_to_check, $tree) ;

push @$dependencies, GetNodeBuildName($tree) ;
my $creator_digest = GenerateCreatorDigest($dependent_to_check, $tree, $dependencies, 1, $caller_info) ;

for my $key (keys %$other_elements) 
	{
	$creator_digest->{$key} = $other_elements->{$key} ;
	}

my $creator_dump = "\n" ;

PBS::Digest::WriteDigest($dependency_file_name, "Generated by Creator $caller_info.", $creator_digest, $creator_dump, 1) ;
}

#---------------------------------------------------------------------------------------

sub GenerateCreatorBuilder
{
# rule with a creator shouldn't need a builder
# but when the creator triggers the node to be created (to trigger it's parents)
# PBS looks for a builder to build the node the creator has already created
# this sub generated a dummy rule that can be passed as a builder override

my $name = shift ;
my $package = shift ;

my $rule = PBS::Rules::RegisterRule
		(
		  __FILE__
		, __LINE__
		, $package
		, "__Creator"
		, [META_SLAVE]  #$rule_types
		, $name
		, sub{die} # $depender_definition
		, sub{return(1, "Creator generated builder '$name', always succeeds.") ;} #$builder_definition
		#, $node_subs
		) ;

push @{$rule->{TYPE}}, CREATOR ;

return($rule) ;
}


#-------------------------------------------------------------------------------
1 ;

__END__
=head1 NAME

PBS::Rules::Creator - Helps with creator generation

=head1 SYNOPSIS

  my $creator = GenerateCreator
  		(
  		# commands (as for a builder)
  		[
  		  "touch %FILE_TO_BUILD %DEPENDENCY_LIST" 
  		, sub { PrintDebug DumpTree(\@_, 'Creator sub:', MAX_DEPTH => 2) ; return(1, "OK") }
  		] ,
  		) ;
  
  AddRule 'A creator', [[$creator] => 'A' => 'dependency_to_A', 'dependency_2_to_A'] ;


=head1 DESCRIPTION

=head2 EXPORT

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=head1 SEE ALSO

B<PBS> reference manual.

=cut
