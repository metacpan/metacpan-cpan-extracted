# WIZARD_GROUP PBS
# WIZARD_NAME  creator with bells and wistles
# WIZARD_DESCRIPTION template for a creator sub
# WIZARD_ON

print <<'EOP' ;
PbsUse('Configs/gcc') ; # this should also trigger the re-creation of the node

#---------------------------------------------------------------------------------------
# example Pbsfile using the creator
#---------------------------------------------------------------------------------------

ExcludeFromDigestGeneration('source' => 'dependency') ;
AddRule [VIRTUAL], 'all',   [ 'all' => 'A' ], BuildOk("All finished.");

AddRule 'objects', [[\&Creator] => 'A' => 'dependency_to_A', 'dependency_2_to_A'] ;

#---------------------------------------------------------------------------------------

use PBS::Constants ;
use Data::TreeDumper ;
use File::Path ;
use Digest::MD5 qw(md5_hex) ;

#---------------------------------------------------------------------------------------

# TODO: make this a generic Creator builder that takes a sub, a list of commands or a builder!
# remember it is possible to generate a builder from the Rules module

#TODO: make this private by having the digest generator take it as argument
# note that it is also used in the digest checker

my $CREATOR_VERSION = 'anything specific to this creator version 1' ; # will be checked

sub Creator
{
# this creator verifies the dependencies that are passed by the rule definition 
# and will regenerate the $dependent if needed

#the created object must be created in the proper out directory as it is not a source
# when the node is created, it trigger so parents can also be build

my
(
  $dependent_to_check
, $config
, $tree
, $inserted_nodes
, $dependencies         # rule local
, $builder_override     # rule local
) = @_ ;

my ($triggered, @my_dependencies) ;

if(defined $dependencies && @$dependencies && $dependencies->[0] == 1 && @$dependencies > 1)
	{
	# previous depender defined dependencies
	$triggered       = $dependencies->[0] ;
	@my_dependencies = @{$dependencies}[1 .. @$dependencies - 1] ;
	
	if(NEED_REBUILD == CheckCreatorDigest($dependent_to_check, $tree, \@my_dependencies))
		{
		my $file_to_build = GetNodeBuildName($tree) ;
		
		my ($basename, $path, $ext) = File::Basename::fileparse($file_to_build, ('\..*')) ;
		mkpath($path) unless(-e $path) ;
		
		# verify the dependencies digest before creating the node
		GenerateCreatorDigest($dependent_to_check, $tree, \@my_dependencies, 0) ;
		
		RunShellCommands("touch $file_to_build") ;
		
		WriteCreatorDigest($dependent_to_check, $tree, \@my_dependencies) ;
		
		push @$dependencies, PBS::Depend::FORCE_TRIGGER("$dependent_to_check digest rebuilt.") ;
		}
	}

#this makes it unnecessay (and checked) that a rule with creator also has a builder.
$builder_override = GenerateCreatorBuilder("test creator builder", $tree->{__LOAD_PACKAGE}) ;

return($dependencies, $builder_override) ;
}

#---------------------------------------------------------------------------------------

sub CheckCreatorDigest
{
my ($dependent_to_check, $tree, $dependencies) = @_ ;

my $dependency_file_name = GetCreatorDependencyFileName($dependent_to_check, $tree) ;
my $dependency_file_needs_update = ! NEED_REBUILD ;

if(-e $dependency_file_name)
	{
	our ($digest, $creator_version) ;
	
	if(do $dependency_file_name) 
		{
		my %dependency_md5 ;
		
		unless('HASH' eq ref $digest)
				{
				PrintWarning("Creator: '$dependent_to_check' [Empty].\n") ;
				$dependency_file_needs_update = NEED_REBUILD ;
				}
				
		$creator_version = '' unless defined $creator_version;
		
		unless($CREATOR_VERSION eq $creator_version)
				{
				PrintWarning("Creator: '$dependent_to_check' [Version mismatch].\n") ;
				$dependency_file_needs_update = NEED_REBUILD ;
				}
				
		my $package_digest = PBS::Digest::GetPackageDigest($tree->{__LOAD_PACKAGE}) ;
		for my $key (keys %$package_digest) 
			{
			$dependency_md5{$key} = $package_digest->{$key} ;
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
				my $dependency_md5 ;
				
				if(defined ($dependency_md5 = PBS::Digest::GetFileMD5($dependency)))
					{
					$dependency_md5{$dependency} = $dependency_md5 ;
					}
				else
					{
					PrintInfo("Creator: Can't compute MD5 for '$dependency' (found in dependency file)! Rebuilding.\n") ;
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
my ($dependent_to_check, $tree, $dependencies, $display_info) = @_ ;

if ($display_info)
	{
	PrintInfo "Generating '$dependent_to_check' creator dependency file" ;
	}

my %dependency_file_digest ;
my %dependency_md5 ;

for my $dependency (@$dependencies)
	{
	unless(exists $dependency_md5{$dependency})
		{
		my $dependency_md5 ;
		
		if(defined ($dependency_md5 = PBS::Digest::GetFileMD5($dependency)))
			{
			$dependency_md5{$dependency} = $dependency_md5 ;
			}
		else
			{
			#TODO: Give better information file::line ...
			PrintError("Creator: Can't compute dependency '$dependency' MD5 while generating digest for '$dependent_to_check'!\n") ;
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

my ($build_name, $is_alternative_source, $other_source_index) = PBS::Check::LocateSource($node->{__NAME}, $build_directory, $source_directories) ;

return($build_name) ;
}

#---------------------------------------------------------------------------------------

sub WriteCreatorDigest
{
my ($dependent_to_check, $tree, $dependencies) = @_ ;

my $dependency_file_name = GetCreatorDependencyFileName($dependent_to_check, $tree) ;

push @$dependencies, GetNodeBuildName($tree) ;
my $creator_digest = GenerateCreatorDigest($dependent_to_check, $tree, $dependencies, 1) ;

my $creator_dump = Data::Dumper->Dump([$CREATOR_VERSION], ['creator_version']) . "\n" ;

PBS::Digest::WriteDigest($dependency_file_name, "Generated by Creator $CREATOR_VERSION.", $creator_digest, $creator_dump, 1) ;
}

#---------------------------------------------------------------------------------------

sub GenerateCreatorBuilder
{
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
		, sub{return(1, $name) ;} #$builder_definition
		#, $node_subs
		) ;

return($rule) ;
}

EOP


