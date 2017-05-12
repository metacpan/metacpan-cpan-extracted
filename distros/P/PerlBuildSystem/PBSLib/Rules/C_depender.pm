
=head1 'Rules/C_depender.pm'

This is a B<PBS> (Perl Build System) module.

=head1 When is ''Rules/C_depender.pm' used?

Whenever  C or CPP files need to be depended. This module is automatically used when 'Rules/C.pm' is used.

=head1 What 'Rules/C_depender.pm' does.

It adds a rule to start the   C depender whenevenra C or CPP node is added to the dependency graph.

it also add a rule to "build" C files. The build does nothing and is there merely to handle the case where
I<PBS> finds a dependency (a header file) must be rebuild thus forcing  the rebuild of the C node too.

=head1 How does the C depender work?

The C depender first checks to see if a C dependency cache exists for the C file to depend. If the cache exists,
it is read, verified and a dependency graph regenerated from the cache.

If the cache file doesn't exist, The 'PreprocessorDepend' is called to find which header files the C file depends on. 

'PreprocessorDepend' must be defined in your config.

A graph is generated from the dependencies and it is serialized into a cache with the MD5 of all the nodes in
the dependency graph.

The dependency graph is then merged with the global dependency graph. I finally returns the direct
dependencies to the C file. As the nodes have already been merged, I<PBS> will only link to those dependencies.

Since the header files are also considered source, we need to tell I<PBS> that the C file must be "rebuild". This is
done by returning "__PBS_FORCE_TRIGGER::" as one of the dependencies.

The C depender , which is a normal depender,  merges the dependency nodes directely in the dependency graph.
It also implements a distrubuted cache on the behalf of PBS. When a cache is regenerated, it cannot be used before
successfull build is done. The C depender doesn't know about when a successfull build has occured and it must 
relly on PBS for the synchronisation.. The C depender doesn't know about what file depends on a C file. It could
be an object file or any other file. The dependency could also be indirect.

TODO: __PBS_SYNCHRONIZE:
explain how the synchronizing works
explain how we use the unsynchronized cache to not redepend 

=cut

use strict ;
use warnings ;
use Data::TreeDumper ;

use PBS::PBS ;
use PBS::Depend ;
use PBS::PBSConfig ;
use PBS::Digest;
use PBS::Rules ;
use PBS::Output ;
use PBS::Warp ;
use PBS::Warp::Warp1_5 ;

use File::Basename ;
use File::Path ;
use Carp ;
use Time::HiRes qw(gettimeofday tv_interval) ;

use Digest::MD5 qw(md5_hex) ;

our $VERSION = '0.12' ;

#-------------------------------------------------------------------------------

#~ # verify PreprocessorDepend is defined in the current package
#~ # since $PreprocessorDepend is a 'my' variable that might or might not exists
#~ # we can not use it directly as perl would complain about an unexisting variable 
#~ # at compile time. We go through hoops to check if the variable exists.

my $C_Depender_PreprocessorDepend ;
eval "\$C_Depender_PreprocessorDepend = \$PreprocessorDepend" ;

if($@)
	{
	PrintError "Error in package '" . __PACKAGE__ . "': '\$PreprocessorDepend' must be defined for the C depender to work!\n"
		. "Did you forget to use a depending module defining '\$PreprocessorDepend' in your config?\n"
		. "   ex: use Devel::Depend::Cpp ;\n\n" ;
	
	$@ = "" ;
	die "";
	}

#-------------------------------------------------------------------------------
# This depender is not part of PBS, it is user defined, this means that you can replace it as you wish

# c files dependencies are handled by the following rule.
# unlike make, the dependencies for a c file are not considered to be the dependencies for 
# the corresponding object file. If a dependency to a c file forces it rebuild, a fake
# builder is called. if the c file is itself the dependency to an object file, it will be rebuild

AddRuleTo 'BuiltIn', [POST_DEPEND], 'C_dependencies', \&C_SourceDepender, \&C_Builder ;

#-------------------------------------------------------------------------------

sub C_SourceDepender
{
# the depend is done with the help of the compiler. The dependencies are md5'ed
# and thorougly verified. --ncd makes this depender return 0 dependencies.

#~ PrintDebug "2/ " . __PACKAGE__ .  "  C_SourceDepender"  . \&PreprocessorDepend . "\n" ;

my $dependent      = shift ; 
my $config         = shift ; 
my $file_tree      = shift ;
my $inserted_nodes = shift ;

return([0, 'not a .c/.cpp file']) unless $dependent =~ /\.c(pp)?$/ ;

# rules can (and are) be called multiple times for the same node, PBS uses
# this system to verify linked nodes with localy defined rules
if
	(
	exists $file_tree->{__INSERTED_AT} 
	&& exists $file_tree->{__INSERTED_AT}{INSERTION_FILE} 
	&& $file_tree->{__INSERTED_AT}{INSERTION_FILE} eq '__C_DEPENDER'
	)
	{
	PrintWarning "C Depender: You have included a C file ($dependent) from another C file! Compile the C file or change its extention to remove this warning. Also try -dd.\n" ;
	return([0, 'already depended and merged']);
	}
	
my $c_file_config  = $file_tree->{__CONFIG}; 

if(defined $file_tree->{__PBS_CONFIG}{NO_C_DEPENDENCIES})
	{
	return([0, 'no_c_dependencies flag is set.']) ;
	}
else
	{
	my $t0_depend = [gettimeofday];
	
	Check_C_DependerConfig($c_file_config) ; #dies on error
	
	my $build_directory    = $file_tree->{__PBS_CONFIG}{BUILD_DIRECTORY} ;
	my $source_directories = $file_tree->{__PBS_CONFIG}{SOURCE_DIRECTORIES} ;
	
	my ($full_name, $is_alternative_source, $other_source_index) = PBS::Check::LocateSource($dependent, $build_directory, $source_directories) ;
	
	my $source_directory ;
	
	if($is_alternative_source)
		{
		$source_directory = $source_directories->[$other_source_index] ;
		}
	else
		{
		$source_directory = $build_directory ;
		}
			
	my $dependency_file_name ;
	($dependency_file_name, $is_alternative_source, $other_source_index) 
		= PBS::Check::LocateSource
			(
			  "$dependent.depend"
			, $build_directory
			, $source_directories
			, $file_tree->{__PBS_CONFIG}{DISPLAY_SEARCH_INFO}
			, $file_tree->{__PBS_CONFIG}{DISPLAY_SEARCH_ALTERNATES}
			) ;
			
	$dependency_file_name = CollapsePath($dependency_file_name) ;
	
	# C files with full path get their dependency file in the same path as the 
	# C file defeating the output path
	if(File::Spec->file_name_is_absolute($dependent))
		{
		my ($volume,$directories,$file) = File::Spec->splitpath($dependent);
		$dependency_file_name = "$build_directory/ROOT${directories}$file.depend" ;
		}
	
	my @dependencies = () ;
	
	if(-e $full_name)
		{
		#~ my $t0_VerifyAndGenerateDependencies = [gettimeofday];
		
		@dependencies = VerifyAndGenerateDependencies
					(
					  $c_file_config
					, $dependent
					, $full_name
					, $dependency_file_name
					, $source_directory
					, $source_directories
					, $file_tree->{__PBS_CONFIG}{DISPLAY_C_DEPENDENCIES}
					, $file_tree
					, $inserted_nodes
					) ;
					
		#~ PrintDebug "VerifyAndGenerateDependencies time: " . tv_interval ($t0_VerifyAndGenerateDependencies, [gettimeofday]) . "\n" ;
		}
	else
		{
		PrintError("C_depender: Can't depend a non existing C file: '$dependent' [$full_name].") ;
		PrintError("\nInserted at $file_tree->{__INSERTED_AT}{INSERTION_FILE}\n");
		
		if(-e $dependency_file_name)
			{
			print WARNING("C_depender: Removing '$dependency_file_name'\n") ;
			unlink($dependency_file_name) ;
			}
		die ;
		}
		
	$file_tree->{__FIXED_BUILD_NAME} = $full_name ;  # used in Check.pm
	
	$PBS::C_DEPENDER::c_dependency_time += tv_interval ($t0_depend, [gettimeofday]) ;
	$PBS::C_DEPENDER::c_files++ ;
	
	return([1, @dependencies]) ;
	}
}

#-------------------------------------------------------------------------------

sub GetDependenciesOnly
{
# this is a Data::TreeDumper filter

my $tree = shift ;

return( 'HASH', undef, sort grep {! /^__/} keys %$tree) if('HASH' eq ref $tree) ;
return (Data::TreeDumper::DefaultNodesToDisplay($tree)) ;
} ;

#-------------------------------------------------------------------------------

sub VerifyAndGenerateDependencies
{
# Verify the validity of the data found in the digest file and merges the nodes

my $config                 = shift ;
my $dependent              = shift ;
my $file_to_depend         = shift ;
my $dependency_file_name   = shift ;
my $source_directory       = shift ;
my $source_directories     = shift ;
my $display_c_dependencies = shift ;
my $tree                   = shift ;
my $inserted_nodes         = shift ;

my @first_level_dependencies = () ;

#~ PrintInfo "=> $dependency_file_name \n" ;

my ($dependency_file_needs_update, $pbs_include_tree) = Verify_C_FileDigest($file_to_depend, $dependency_file_name, $config, $tree) ;

#~ PrintDebug "'$dependency_file_name' => $dependency_file_needs_update\n" ;

# the commented lines would make the dependency cache depend on the PBS run config
# although it is not wrong, it is overkill
#~ my $signature = PBS::Warp::GetWarpSignature([$file_to_depend], $tree->{__PBS_CONFIG}) ;
#~ my $unsynchronized_dependency_file_name = "${dependency_file_name}_$signature" ;

my $unsynchronized_dependency_file_name = "${dependency_file_name}_unsynchronized" ;

if($dependency_file_needs_update)
	{
	if(-e $unsynchronized_dependency_file_name)
		{
		# check if a valid un-synched cache exists (a rather high probability)
		
		my ($unsynched_dependency_file_needs_update, $unsynched_pbs_include_tree) = Verify_C_FileDigest($file_to_depend, $unsynchronized_dependency_file_name , $config, $tree) ;
		if($unsynched_dependency_file_needs_update)
			{
			if(defined $tree->{__PBS_CONFIG}{DISPLAY_C_DEPENDENCY_INFO})
				{
				PrintInfo "   Verifying unsynchronized cache ... Invalid, regenerating.\n" ;
				}
				
			# regenerate cache, merge, tag as unsynched
			@first_level_dependencies = 
				(
				GenerateDependencyFile
						(
						  $config
						, $dependent
						, $file_to_depend
						, $unsynchronized_dependency_file_name # regenerate
						, $source_directory
						, $source_directories
						, $display_c_dependencies
						, $tree
						, $inserted_nodes
						)
						
				, PBS::Depend::FORCE_TRIGGER("$file_to_depend digest rebuilt.")
				, PBS::Depend::SYNCHRONIZE
					(
					  $unsynchronized_dependency_file_name
					, $dependency_file_name
					, "Synchronized C cache file for '%s'\n"
					)
				) ;
			}
		else
			{
			if(defined $tree->{__PBS_CONFIG}{DISPLAY_C_DEPENDENCY_INFO})
				{
				PrintInfo "   Verifying unsynchronized cache ... Valid.\n" ;
				}
			
			@first_level_dependencies = 
				(
				MergeDependencyCache
					(
					  $file_to_depend
					, $dependent
					, $display_c_dependencies
					, $tree
					, $inserted_nodes
					, $unsynched_pbs_include_tree
					)
				, PBS::Depend::FORCE_TRIGGER("$file_to_depend digest rebuilt.")
				, PBS::Depend::SYNCHRONIZE
					(
					  $unsynchronized_dependency_file_name
					, $dependency_file_name
					, "Synchronized C cache file for '%s'\n"
					)
				) ;
			}
		}
	else
		{
		@first_level_dependencies  =
			(
			GenerateDependencyFile
				(
				  $config
				, $dependent
				, $file_to_depend
				, $unsynchronized_dependency_file_name
				, $source_directory
				, $source_directories
				, $display_c_dependencies
				, $tree
				, $inserted_nodes
				)
			, PBS::Depend::FORCE_TRIGGER("$file_to_depend digest rebuilt.")
			, PBS::Depend::SYNCHRONIZE
				(
				  $unsynchronized_dependency_file_name
				, $dependency_file_name
				, "Synchronized C cache file for '%s'\n"
				)
			) ;
		}
	}
else
	{
	@first_level_dependencies = MergeDependencyCache
					(
					  $file_to_depend
					, $dependent
					, $display_c_dependencies
					, $tree
					, $inserted_nodes
					, $pbs_include_tree
					) ;
					
	if(-e $unsynchronized_dependency_file_name)
		{
		# trigger
		push @first_level_dependencies, PBS::Depend::FORCE_TRIGGER("$file_to_depend found synchronized and unsynchronized cache.") ;
		unlink $unsynchronized_dependency_file_name ;
		}
	}
	
return(@first_level_dependencies) ;
}

sub MergeDependencyCache
{
my
(
  $file_to_depend
, $dependent
, $display_c_dependencies
, $tree
, $inserted_nodes
, $pbs_include_tree
) = @_ ;

$PBS::C_DEPENDER::c_files_cached++ ;

if($display_c_dependencies)
	{
	PrintInfo(DumpTree($pbs_include_tree->{$file_to_depend}, "'$dependent' includes (cache):", FILTER => \&GetDependenciesOnly)) ;
	print "\n" ;
	}
	
my $time = Time::HiRes::time() ;

my @dependencies ;
for my $key (keys %{$pbs_include_tree->{$file_to_depend}})
	{
	if($key !~ /^__/)
		{
		push @dependencies, $key ;
		
		MergeNode($pbs_include_tree->{$file_to_depend}{$key}, $inserted_nodes, $time, $tree->{__LOAD_PACKAGE}) ;
		}
	}
	
return(@dependencies) ;
}

#-------------------------------------------------------------------------------

sub Is_C_FileDigestOk
{
my $c_file          = shift ; 
my $config          = shift ; # for C flags
my $dependency_tree = shift ;

Check_C_DependerConfig($config) ; #dies on error

my $build_directory    = $dependency_tree->{__PBS_CONFIG}{BUILD_DIRECTORY} ;
my $source_directories = $dependency_tree->{__PBS_CONFIG}{SOURCE_DIRECTORIES} ;

my ($located_c_file)  = PBS::Check::LocateSource($c_file, $build_directory, $source_directories) ;
my ($dependency_file) = PBS::Check::LocateSource("$c_file.depend", $build_directory, $source_directories) ;

$dependency_file = CollapsePath($dependency_file) ;

my ($dependency_file_needs_update) = Verify_C_FileDigest($located_c_file, $dependency_file, $config, $dependency_tree) ;

return(!$dependency_file_needs_update) ;
}

#-------------------------------------------------------------------------------

sub Verify_C_FileDigest
{
my $file_to_depend       = shift ;
my $dependency_file_name = shift ;
my $config               = shift ;
my $tree                 = shift ;


my $dependency_file_needs_update = 0 ;

our ($c_depender_version, $root_node, $nodes, $node_names, $global_pbs_config, $insertion_file_names) ;

$root_node = 'C DEPENDER: UNDEFINED ROOT NODE' ;

if(-e $dependency_file_name)
	{
	our $digest ;
	
	($c_depender_version, $root_node, $nodes, $node_names, $global_pbs_config, $insertion_file_names) = map {undef} (1 .. 10) ;
	
	if(do $dependency_file_name) 
		{
		unless('HASH' eq ref $digest)
				{
				PrintWarning("C_depender: '$file_to_depend' [Empty].\n") ;
				$dependency_file_needs_update++ ;
				}
				
		$c_depender_version = -1 unless defined $c_depender_version ;
		
		unless($VERSION == $c_depender_version)
				{
				PrintWarning("C_depender: '$file_to_depend' [Version mismatch].\n") ;
				$dependency_file_needs_update++ ;
				}
				
		my $c_file_md5 ;
		unless (defined ($c_file_md5 = PBS::Digest::GetFileMD5($file_to_depend)))
			{
			PrintError("C_depender: Can't compute MD5 for '$file_to_depend'.") ;
			die ;
			}
			
		my $expected_digest = GetStandard_C_Digest($config, $c_file_md5) ;
		
		for my $dependency (keys %$digest)
			{
			last if $dependency_file_needs_update ;
			
			if(exists $digest->{$dependency} && exists $expected_digest->{$dependency})
				{
				# verify CC, CFLAGS_INCLUDE, ... see above
				if
					(
					   (defined $digest->{$dependency} && ! defined $expected_digest->{$dependency})
					|| (! defined $digest->{$dependency} && defined $expected_digest->{$dependency})
					|| (
							   (defined $digest->{$dependency} && defined $expected_digest->{$dependency})
							&& ($digest->{$dependency} ne $expected_digest->{$dependency})
						)
					)
					{
					if(defined $tree->{__PBS_CONFIG}{DISPLAY_C_DEPENDENCY_INFO})
						{
						PrintInfo("C_depender: '$file_to_depend' [difference]:\n   [$dependency].\n") ;
						}
						
					$dependency_file_needs_update++ ;
					last ;
					}
				}
			else
				{
				if(exists $C_dependencies_cache::dependency_md5{$dependency})
					{
					if($digest->{$dependency} ne $C_dependencies_cache::dependency_md5{$dependency})
						{
						if(defined $tree->{__PBS_CONFIG}{DISPLAY_C_DEPENDENCY_INFO})
							{
							PrintInfo("C_depender: '$file_to_depend' [MD5 difference]:\n   [$dependency].\n") ;
							}
						$dependency_file_needs_update++ ;
						last ;
						}
					}
				else
					{
					my $dependency_md5 ;
					
					if(defined ($dependency_md5 = PBS::Digest::GetFileMD5($dependency)))
						{
						$C_dependencies_cache::dependency_md5{$dependency} = $dependency_md5 ;
						}
					else
						{
						PrintInfo("C_depender: Can't compute MD5 for '$dependency' (found in dependency file)! Rebuilding.\n") ;
						$dependency_file_needs_update++ ;
						last ;
						}
						
					if($digest->{$dependency} ne $C_dependencies_cache::dependency_md5{$dependency})
						{
						if(defined $tree->{__PBS_CONFIG}{DISPLAY_C_DEPENDENCY_INFO})
							{
							PrintInfo("C_depender: '$file_to_depend' [MD5 difference]\n   [$dependency].\n") ;
							}
							
						$dependency_file_needs_update++ ;
						last ;
						}
					}
				}
			}
		
		unless($dependency_file_needs_update)
			{
			#rebuild the warpified nodes
			for my $node (keys %$nodes)
				{
				# rebuild the build name
				if(exists $nodes->{$node}{__LOCATION})
					{
					$nodes->{$node}{__BUILD_NAME} = $nodes->{$node}{__LOCATION} . substr($node, 1) ;
					}
				else
					{
					$nodes->{$node}{__BUILD_NAME} = $node ;
					}
					
				# rebuild the data PBS needs from the warp file
				# note that the node is marked as build but not as checked!
				# even C dependencies must be rechecked to catch cyclic header file include
				# __BUILD_DONE is set so Warp can generate md5 for the node, an included node triggers,
				# which can happend if no ExcludeFromDigest was set properly, The checker will remove __BUILD_DONE
				
				$nodes->{$node}{__NAME} = $node ;
				$nodes->{$node}{__BUILD_DONE} = "in C depender (1)" ;
				$nodes->{$node}{__DEPENDED}++ ;
				
				$nodes->{$node}{__PBS_CONFIG} = $global_pbs_config unless exists $nodes->{$node}{__PBS_CONFIG} ;
				
				$nodes->{$node}{__INSERTED_AT}{INSERTION_FILE} = $insertion_file_names->[$nodes->{$node}{__INSERTED_AT}{INSERTION_FILE}] ;
				$nodes->{$node}{__INSERTED_AT}{INSERTION_RULE} = 'CACHE' ;
				
				unless(exists $nodes->{$node}{__DEPENDED_AT})
					{
					$nodes->{$node}{__DEPENDED_AT} = $nodes->{$node}{__INSERTED_AT}{INSERTION_FILE} ;
					}
					
				# rebuild the tree
				for my $parent_index (@{$nodes->{$node}{__DEPENDENT}})
					{
					if(defined $tree->{__PBS_CONFIG}{DEBUG_DISPLAY_PARENT})
						{
						# set needed information for --ancestor to work properly on c dependencies nodes
						
						#~ PrintDebug "$node_names->[$parent_index] => $node\n" ;
						
						# keep parent relationship
						my $parent_name = $node_names->[$parent_index] ;
						
						# make sure next operation doesn't link to an undefined list
						$nodes->{$parent_name}{__DEPENDENCY_TO} = {} unless exists $nodes->{$parent_name}{__DEPENDENCY_TO} ;
						
						if($parent_name !~ /\.c$/)
							{
							$nodes->{$node}{__DEPENDENCY_TO}{$parent_name} = $nodes->{$parent_name}{__DEPENDENCY_TO} ;
							}
						}
						
					$nodes->{$node_names->[$parent_index]}{$node} = $nodes->{$node} ;
					}
				}
			}
		}
	else
		{
		PrintWarning "C_depender: Couldn't parse '$dependency_file_name': $@" if $@;
		$dependency_file_needs_update++ ;
		}
		
	}
else
	{
	if(defined $tree->{__PBS_CONFIG}{DISPLAY_C_DEPENDENCY_INFO})
		{
		PrintInfo("C_depender: '$file_to_depend'. [Not found].\n");
		}
		
	$dependency_file_needs_update++ ;
	}

return($dependency_file_needs_update, {$root_node => $nodes->{$root_node}}) ;
}

#-------------------------------------------------------------------------------

sub GetCFileIncludePaths
{
my ($tree) = @_;
	
my $pbs_config = $tree->{__PBS_CONFIG};

my @source_directories = @{ $pbs_config->{SOURCE_DIRECTORIES} };

my $config = $tree->{__CONFIG};
my @include_paths = split(/\s*-I\s*/, $config->{CFLAGS_INCLUDE});
# Remove the empty element before the first -I
shift @include_paths;

my $dependent = $tree->{__NAME};
my $dependent_path = (File::Basename::fileparse($dependent))[1] ;

my $result = '';

# Add the dependent path, to make includes like: #include "header" work
for my $include_path ($dependent_path, @include_paths)
	{
	$include_path =~ s~/$~~ ;
	$include_path =~ s|^"||;
	$include_path =~ s|"$||;
	$include_path =~ s/^\s+// ;
	$include_path =~ s/\s+$// ;
	
	if (File::Spec->file_name_is_absolute($include_path))
		{
		$result .= qq| -I "$include_path"|;
		}
	else
		{
		for my $source_directory (@source_directories)
			{
			$result .= ' -I "' . CollapsePath("$source_directory/$include_path") . '"';
			}
		}
	}
	
return $result;
}

#-------------------------------------------------------------------------------

sub GenerateDependencyFile
{
my $config                 = shift ;
my $dependent              = shift ;
my $file_to_depend         = shift ;
my $dependency_file_name   = shift ;
my $source_directory       = shift ;
my $source_directories     = shift ;
my $display_c_dependencies = shift ;
my $tree                   = shift ;
my $inserted_nodes         = shift ;

Check_C_DependerConfig($config) ;

# Create the path for the dependency file if necessary
File::Path::mkpath((File::Basename::fileparse($dependency_file_name))[1]) ;

my $depend_switches = "$config->{CDEFINES} " . GetCFileIncludePaths($tree);

my @dependencies ;

my $depend_info = '' ;
if (defined $tree->{__PBS_CONFIG}{SHOW_C_DEPENDING})
	{
	$depend_info = "Generating '$file_to_depend' dependency file" ;
	$depend_info .= " with: $depend_switches" if(defined $tree->{__PBS_CONFIG}{DISPLAY_C_DEPENDENCY_INFO}) ;
	$depend_info .= "\n" ;
	
	PrintInfo($depend_info) ;
#	unless defined $PBS::Shell::silent_commands ;
	}

my $c_file_md5 ;
unless (defined ($c_file_md5 = PBS::Digest::GetFileMD5($file_to_depend)))
	{
	PrintInfo($depend_info) if defined $PBS::Shell::silent_commands ;
	PrintError("C_depender: Can't compute MD5 for C file: '$file_to_depend'. ") ;
	die ;
	}
	
# keep some information to generate a dependency tree
my %depend_nodes ;

$depend_nodes{$file_to_depend} =
	{
	__NAME => $file_to_depend,
	
	__INSERTED_AT =>
		{
		  INSERTING_NODE => '__C_DEPENDER'
		, INSERTION_RULE => 'NO CACHE'
		, INSERTION_FILE => '__C_DEPENDER'
		, INSERTION_PACKAGE=> '__C_DEPENDER'
		},
		
	__PBS_CONFIG =>
		{
		  BUILD_DIRECTORY    => $source_directory
		, SOURCE_DIRECTORIES => $source_directories
		}
	} ;
	
my $ParentChild = sub
	{
	my ($parent, $child) = @_ ;
	#~ PrintUser("$parent => $child\n") ;
	
	unless(exists $depend_nodes{$parent})
		{
		die ; # this should not happend
		}
		
	unless(exists $depend_nodes{$child})
		{
		#emulate enough of a pbs node to allow warpification
		tie my %new_node, "Tie::Hash::Indexed" ;
		
		%new_node = 
			(
			__NAME => $child
			, __BUILD_NAME => $child
			
			, __INSERTED_AT =>
				{
				  INSERTING_NODE => $parent
				, INSERTION_RULE => 'NO_CACHE'
				, INSERTION_FILE => '__C_DEPENDER'
				, INSERTION_TIME => 0
				}
				
			, __PBS_CONFIG =>
				{
				  BUILD_DIRECTORY    => $source_directory
				, SOURCE_DIRECTORIES => $source_directories
				}
				
			, __DEPENDED => 1
			, __BUILD_DONE => "in C depender (2)"
			) ;
			
		$depend_nodes{$child} = \%new_node ;
		}
			
	if(defined $tree->{__PBS_CONFIG}{DEBUG_DISPLAY_PARENT})
		{
		# set needed information for --ancestor to work properly on c dependencies nodes
		
		#~ PrintDebug "$parent => $child\n" ;
		
		#~ # make sure next operation doesn't link to an undefined list
		$depend_nodes{$parent}{__DEPENDENCY_TO} = {} unless exists $depend_nodes{$parent}{__DEPENDENCY_TO} ;
		
		if($parent !~ /\.c$/)
			{
			$depend_nodes{$child}{__DEPENDENCY_TO}{$parent} = $depend_nodes{$parent}{__DEPENDENCY_TO} ;
			}
		}
		
	unless(exists $depend_nodes{$parent}{$child})
		{
		$depend_nodes{$parent}{$child} = $depend_nodes{$child} ;
		}
	} ;


my ($depended, $include_levels, $include_nodes, $include_tree, $errors) 
	= $C_Depender_PreprocessorDepend->
		(
		  $config->{'CPP'}
		, $file_to_depend
		, $depend_switches 
		, $config->{'C_DEPENDER_SYSTEM_INCLUDES'}
		, $ParentChild
		, $tree->{__PBS_CONFIG}{DISPLAY_CPP_OUTPUT} # display gcc output
		) ;
		
if($depended)
	{
	my $dependency_file_digest = GetStandard_C_Digest($config, $c_file_md5) ;
	
	# computed included files md5
	for my $dependency (keys %$include_nodes)
		{
		push @dependencies, $dependency ;
		
		unless(exists $C_dependencies_cache::dependency_md5{$dependency})
			{
			my $dependency_md5 ;
			
			if(defined ($dependency_md5 = PBS::Digest::GetFileMD5($dependency)))
				{
				$C_dependencies_cache::dependency_md5{$dependency} = $dependency_md5 ;
				}
			else
				{
				PrintError("Can't compute dependency '$dependency' MD5 while generating digest for '$file_to_depend'!\n") ;
				carp ;
				die ;
				}
			}
			
		$dependency_file_digest->{$dependency} = $C_dependencies_cache::dependency_md5{$dependency} ;
		}
		
	my $include_tree_dump ;
	{
	local $SIG{'__WARN__'} = sub {print STDERR $_[0] unless $_[0] =~ 'Encountered CODE ref'} ;
	local $Data::Dumper::Purity = 1 ;
	local $Data::Dumper::Indent = 1 ;
	
	my $global_pbs_config = # cache to reduce warp file size
		{
		  BUILD_DIRECTORY    => $tree->{__PBS_CONFIG}{BUILD_DIRECTORY}
		, SOURCE_DIRECTORIES => $tree->{__PBS_CONFIG}{SOURCE_DIRECTORIES}
		} ;
	
	my ($nodes, $node_names, $insertion_file_names) = PBS::Warp::Warp1_5::WarpifyTree1_5(\%depend_nodes, $global_pbs_config) ;

	$include_tree_dump .=  Data::Dumper->Dump([$global_pbs_config], ['global_pbs_config']) ;
	$include_tree_dump .= "\n" ;
	
	$include_tree_dump .=  Data::Dumper->Dump([$nodes], ['nodes']) ;
	$include_tree_dump .= "\n" ;
	
	$include_tree_dump .= Data::Dumper->Dump([$node_names], ['node_names']) ;
	$include_tree_dump .= "\n" ;
	
	$include_tree_dump .= Data::Dumper->Dump([$insertion_file_names], ['insertion_file_names']) ;
	$include_tree_dump .= "\n" ;

	$include_tree_dump .= Data::Dumper->Dump([$file_to_depend], ['root_node']) ;
	$include_tree_dump .= "\n" ;
	
	$include_tree_dump .= Data::Dumper->Dump([$VERSION], ['c_depender_version']) ;
	$include_tree_dump .= "\n" ;
	}
	
	my $signature = PBS::Warp::GetWarpSignature([$file_to_depend], $tree->{__PBS_CONFIG}) ;
	
	PBS::Digest::WriteDigest
		(
		  $dependency_file_name
		, "Generated by C_depender $VERSION using warp 1.5"
		, $dependency_file_digest
		, $include_tree_dump
		) ;

	if($display_c_dependencies)
		{
		PrintInfo(DumpTree($depend_nodes{$file_to_depend}, "'$dependent' includes:", FILTER => \&GetDependenciesOnly)) ;	
		}
		
	# add all the includes in the inserted_nodes list
	# MergeNode also merges header file dependencies
	
	my $time = Time::HiRes::time() ;
	
	@dependencies = () ;
	for my $key (keys %{$depend_nodes{$file_to_depend}})
		{
		if($key !~ /^__/)
			{
			push @dependencies, $key ;
			MergeNode($depend_nodes{$file_to_depend}{$key}, $inserted_nodes, $time, $tree->{__LOAD_PACKAGE}) ;
			}
		}
		
	return(@dependencies) ;
	}
else
	{
	PrintInfo($depend_info) if defined $PBS::Shell::silent_commands ;
	PrintError "Error Depending '$file_to_depend':\n$errors\n" ;
	die ;
	}
}

#-------------------------------------------------------------------------------

sub MergeNode
{
my ($node, $inserted_nodes, $time, $load_package) = @_ ;
my $node_name = $node->{__NAME} ;

#~ PrintWarning "Merging $node_name\n" ;

return if exists $node->{__MERGED} ;

unless(exists $inserted_nodes->{$node_name})
	{
	#~ PrintWarning"\tnew node\n" ;
	$node->{__INSERTED_AT}{INSERTION_TIME} = $time ; # needed when we generate graphs
	$node->{__LOAD_PACKAGE}                = $load_package ;
	
	$inserted_nodes->{$node_name} = $node ;
	}
else
	{
	# set needed information for --ancestor to work properly on c dependencies nodes
	for my $dependency_to_key (keys %{$node->{__DEPENDENCY_TO}})
		{
		if(exists $inserted_nodes->{$dependency_to_key})
			{
			$inserted_nodes->{$node_name}{__DEPENDENCY_TO}{$dependency_to_key} = $inserted_nodes->{$dependency_to_key}{__DEPENDENCY_TO} ;
			}
		else
			{
			$inserted_nodes->{$node_name}{__DEPENDENCY_TO}{$dependency_to_key} = $node->{__DEPENDENCY_TO}{$dependency_to_key} ;
			}
		}
	}
	
$node->{__MERGED}++ ;

for my $dependency (grep{! /^__/} keys %$node)
	{
	# this is needed so all nodes get into $inserted_nodes
	MergeNode($node->{$dependency}, $inserted_nodes, $time, $load_package) ;
	$inserted_nodes->{$node_name}{$dependency} = $inserted_nodes->{$dependency} ;
	}
}

#-------------------------------------------------------------------------------

sub Check_C_DependerConfig
{
my $config = shift ;

unless(defined $config->{CC})
	{
	PrintError("Configuration variable 'CC' doesn't exist. Aborting.\n") ;
	use Carp ;
	confess ;
	die ;
	}

unless (defined $config->{CFLAGS_INCLUDE})
	{
	PrintError("Configuration variable 'CFLAGS_INCLUDE' doesn't exist. Aborting.\n") ;
	die ;
	}
	
unless (defined $config->{CDEFINES})
	{
	PrintError("Configuration variable 'CDEFINES' doesn't exist. Aborting.\n") ;
	die ;
	}
}

#-------------------------------------------------------------------------------

sub GetStandard_C_Digest
{
my $config = shift or confess "Missing argument!" ;
my $c_file_md5 = shift or confess "Missing argument!" ;

return
	(
		{
		  '__VARIABLE:CC'                         => $config->{CC}
		, '__VARIABLE:CFLAGS_INCLUDE'             => $config->{CFLAGS_INCLUDE}
		, '__VARIABLE:CDEFINES'                   => $config->{CDEFINES}
		, '__VARIABLE:C_DEPENDER_SYSTEM_INCLUDES' => $config->{C_DEPENDER_SYSTEM_INCLUDES} || 0
		, '__VARIABLE:C_FILE'                     => $c_file_md5
		} 
	) ;
}

#-------------------------------------------------------------------------------

sub C_Builder
{
my ($config, $file_to_build, $dependencies, $triggering_files, $file_tree) = @_ ;

unless($PBS::Shell::silent_commands)
	{
	#~ PrintInfo "Relocating C file to: '$file_tree->{__BUILD_NAME}'\n" ;
	}

return(1, "C_Builder success.") ;
}

#-------------------------------------------------------------------------------

1 ;

