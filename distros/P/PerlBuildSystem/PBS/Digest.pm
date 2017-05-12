
package PBS::Digest;
use PBS::Debug ;

use 5.006 ;

use strict ;
use warnings ;
use Data::Dumper ;
use Data::TreeDumper ;
use Carp ;
use Data::Compare;
use Time::HiRes qw(gettimeofday tv_interval) ;
use File::Spec::Functions qw(:ALL) ;

require Exporter ;
use AutoLoader qw(AUTOLOAD) ;

our @ISA = qw(Exporter) ;
our %EXPORT_TAGS = ('all' => [ qw() ]) ;
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
our @EXPORT = qw(
						AddPbsLibDependencies
						AddFileDependencies           AddNodeFileDependencies
						AddEnvironmentDependencies    AddNodeEnvironmentDependencies
						AddVariableDependencies       AddNodeVariableDependencies
						AddConfigVariableDependencies AddNodeConfigVariableDependencies
						AddSwitchDependencies         AddNodeSwitchDependencies
						
						ExcludeFromDigestGeneration   ForceDigestGeneration 
						GenerateNodeDigest
						GetDigest
						
						GetFileMD5
						CheckFilesMD5
					) ;
					
our $VERSION = '0.05' ;

use PBS::PBSConfig ;
use PBS::Output ;

use Digest::MD5 qw(md5_hex) ;

#-------------------------------------------------------------------------------

my %package_dependencies ;
my %package_config_variable_dependencies ;

my %node_digest_rules ;
my %node_config_variable_dependencies ;

my %exclude_from_digest ;
my %force_digest ;

#-------------------------------------------------------------------------------
# cached MD5 functions
#-------------------------------------------------------------------------------

my %md5_cache ;
my $cache_hits = 0 ;
my $md5_request = 0 ;
my $md5_time = 0 ;
my $non_cached_md5_request = 0 ;

sub Get_MD5_Statistics
{
my $total_md5_requests = $non_cached_md5_request + $md5_request ;
my $md5_cache_hit_ratio = 'N/A' ;
my $cache_misses = 'N/A' ;

if($total_md5_requests)
	{
	$cache_misses = $total_md5_requests - $cache_hits  ;
	$md5_cache_hit_ratio = int(($cache_hits * 100) / $total_md5_requests) ;
	}
	
return
	({
	  TOTAL_MD5_REQUESTS  => $total_md5_requests
	, CACHED_REQUESTS     => $md5_request
	, NON_CACHED_REQUESTS => $non_cached_md5_request
	, CACHE_MISSES        => $cache_misses
	, CACHE_HITS          => $cache_hits
	, MD5_CACHE_HIT_RATIO => $md5_cache_hit_ratio
	, MD5_TIME            => $md5_time
	});
}

sub FlushMd5Cache
{
my $file = shift ;

if(defined $file)
	{
	delete $md5_cache{$file} ;
	}
else
	{
	%md5_cache = () ;
	}
}

#-------------------------------------------------------------------------------

sub GetCachedFileMD5
{
my $file = shift or carp ERROR "GetCachedFileMD5: Called without argument!\n" ;

$md5_request++ ;
my $t0_md5 = [gettimeofday] ;

my $md5 ;
if(exists $md5_cache{$file})
	{
	$md5 = $md5_cache{$file}  ;
	$cache_hits++ ;
	}
else
	{
	if(defined ($md5 = NonCached_GetFileMD5($file)))
		{
		$md5_cache{$file} = $md5 ;
		}
	else
		{
		die croak ERROR("Can't open '$file' to compute MD5 digest: $!") ;
		}
	}
	
$md5_time += tv_interval($t0_md5, [gettimeofday]) ;

return($md5) ;
}

#-------------------------------------------------------------------------------

sub GetFileMD5
{
#  this one caching too.
my $file = shift or carp ERROR "GetFileMD5: Called without argument!\n" ;
my $md5 ;

$non_cached_md5_request++ ;

if(exists $md5_cache{$file})
	{
	$md5 = $md5_cache{$file}  ;
	$cache_hits++ ;
	#~ PrintInfo "cached $file\n" ;
	}
else
	{
	#~ PrintInfo "NON cached $file\n" ;
	if(defined ($md5 = NonCached_GetFileMD5($file)))
		{
		$md5_cache{$file} = $md5 ;
		}
	}

return($md5) ;
}

#-------------------------------------------------------------------------------
# non cached MD5 functions
#-------------------------------------------------------------------------------

sub XXXGetFileMD5
{
my $file_name = shift or carp ERROR "GetFileMD5: Called without argument!\n" ;

return(NonCached_GetFileMD5($file_name)) ;
}

#-------------------------------------------------------------------------------

sub CheckFilesMD5
{
my $files_md5 = shift ;
my $display_error = shift ;

while (my($file, $md5) = each(%$files_md5))
	{
	my $file_md5 = NonCached_GetFileMD5($file) ; 
	
	if(defined $file_md5)
		{
		if($md5 ne $file_md5)
			{
			PrintError("Different md5 for file '$file'.\n") if $display_error;
			return(0) ;
			}
		}
	else
		{
		PrintError("Can't open '$file' to compute MD5 digest: $!\n") if $display_error;
		return(0) ;
		}
	}
	
return(1) ; # all files ok.
}

#-------------------------------------------------------------------------------

sub NonCached_GetFileMD5
{
my $file_name = shift or carp ERROR "GetFileMD5: Called without argument!\n" ;

use IO::File ;
my $fh = new IO::File ;

if($fh->open($file_name))
	{
	$fh->binmode();
	my $md5sum = Digest::MD5->new->addfile($fh)->hexdigest ;
	undef $fh ;
	
	return($md5sum) ;
	}
else
	{
	return ;
	}
}

#-------------------------------------------------------------------------------

sub GetPackageDigest
{
my $package = shift || caller() ;

my %config_variables ;

if (exists $package_config_variable_dependencies{$package})
	{
	my $pbs_config = PBS::PBSConfig::GetPbsConfig($package) ;
	my %config = PBS::Config::ExtractConfig
			(
			  PBS::Config::GetPackageConfig($package)
			, $pbs_config->{CONFIG_NAMESPACES}
			) ;

	#~ PrintDebug DumpTree(\%config, "config for package '$package':") ;
	
	for my $key (keys %{$package_config_variable_dependencies{$package}})
		{
		$config_variables{"__CONFIG_VARIABLE:$key"} = $config{$key} ;
		}
	}
	
if(exists $package_dependencies{$package})
	{
	return({ %{$package_dependencies{$package}}, %config_variables}) ;
	}
else
	{
	return( {%config_variables} );
	}
}

#-------------------------------------------------------------------------------

sub AddFileDependencies
{
my @files = @_ ;

my $package = caller() ;

for (@files)
	{
	my $file_name = $_ ;
	
	if(/^PBSFILE:/)
		{
		$file_name = "__PBSFILE" ;
		s/^PBSFILE:// ;
		
		my $file_md5 = GetCachedFileMD5($_) ;
		
		# warp need this data to find out if it's been made invalid by aPbs filechange
		$package_dependencies{__PBS_WARP_DATA}{$_} = $file_md5 ;
		}
	else
		{
		$file_name = "__FILE:$file_name" ;
		
		$package_dependencies{$package}{$file_name} = GetCachedFileMD5($_) ;
		}
	}
}

#-------------------------------------------------------------------------------

sub AddPbsLibDependencies
{
my ($file_name,	$lib_name) = @_ ;

my $package = caller() ;

$lib_name = "__PBS_LIB_PATH/$lib_name" ;

$package_dependencies{$package}{$lib_name} = GetCachedFileMD5($file_name) ;

# warp need this data to find out if it's been made invalid by aPbsfile change
$package_dependencies{__PBS_WARP_DATA}{$file_name} = $package_dependencies{$package}{$lib_name} ;

#warp 1.6
$package_dependencies{'__WARP1_6'}{$package}{$file_name} = $package_dependencies{$package}{$lib_name} ;
}

#-------------------------------------------------------------------------------

sub AddVariableDependencies 
{
my $package = caller() ;
while(my ($variable_name, $value) = splice(@_, 0, 2))
      {
      $package_dependencies{$package}{"__VARIABLE:$variable_name"} = $value ;
      }
}

#-------------------------------------------------------------------------------

sub AddEnvironmentDependencies 
{
my $package = caller() ;

for (@_)
	{
	if(exists $ENV{$_})
		{
		$package_dependencies{$package}{"__ENV:$_"} = $ENV{$_} ;
		}
	else
		{
		$package_dependencies{$package}{"__ENV:$_"} = '' ;
		}
	}
}

#-------------------------------------------------------------------------------

sub AddSwitchDependencies
{
my $package = caller() ;
my $pbs_config = PBS::PBSConfig::GetPbsConfig($package) ;

for (@_)
	{
	if(/^\s*-D\s*(\w+)/)
		{
		if(exists $pbs_config->{COMMAND_LINE_DEFINITIONS}{$1})
			{
			$package_dependencies{$package}{"__SWITCH:$1"} = $pbs_config->{COMMAND_LINE_DEFINITIONS}{$1} ;
			}
		else
			{
			$package_dependencies{$package}{"__SWITCH:$1"} = '' ;
			}
		}

	if(/^\s*-D\s*\*/)
		{
		for (keys %{$pbs_config->{COMMAND_LINE_DEFINITIONS}})
			{
			$package_dependencies{$package}{"__SWITCH:$_"} = $pbs_config->{COMMAND_LINE_DEFINITIONS}{$_} ;
			}
		}

	if(/^\s*-u\s*(\w+)/)
		{
		if(exists $pbs_config->{USER_OPTIONS}{$1})
			{
			$package_dependencies{$package}{"__SWITCH:$1"} = $pbs_config->{USER_OPTIONS}{$1} ;
			}
		else
			{
			$package_dependencies{$package}{"__SWITCH:$1"} = '' ;
			}
		}

	if(/^\s*-u\s*\*/)
		{
		for (keys %{$pbs_config->{USER_OPTIONS}})
			{
			$package_dependencies{$package}{"__SWITCH:$_"} = $pbs_config->{USER_OPTIONS}{$_} ;
			}
		}
	}
}

#-------------------------------------------------------------------------------

sub AddConfigVariableDependencies 
{
my $package = caller() ;

for my $config_variable (@_)
	{
	$package_config_variable_dependencies{$package}{$config_variable}++ ; 
	}
}

#-------------------------------------------------------------------------------

sub GetNodeDigest
{
my $node = shift ;
my $node_package = $node->{__LOAD_PACKAGE} ;

my %node_dependencies ;

for (@{$node_digest_rules{$node_package}})
	{
	if($node->{__NAME} =~ $_->{REGEX})
		{
		$node_dependencies{$_->{NAME}} = $_->{VALUE} ;
		}
	}
	
if(exists $node_config_variable_dependencies{$node_package})
	{
	my %config = %{$node->{__CONFIG}} ;
	
	for (@{$node_config_variable_dependencies{$node_package}})
		{
		if($node->{__NAME} =~ $_->{REGEX})
			{
			my $config_variable_name = $_->{CONFIG_VARIABLE} ;
			my $config_value = $config{$config_variable_name} ;
			
			$node_dependencies{"__NODE_CONFIG_VARIABLE:$config_variable_name"} = $config_value ;
			}
		}
	}
	
# add node children to digest
my @node_children = map {$node->{$_}{__NAME} ;} grep { ('HASH' eq ref($node->{$_})) && ($_ !~ /^__/) ;} (keys %$node) ;

for(@node_children)
	{
	if(exists $node->{$_}{__VIRTUAL})
		{
		$node_dependencies{$_} = 'VIRTUAL' ;
		}
	else
		{
		$node_dependencies{$_} = GetCachedFileMD5($node->{$_}{__BUILD_NAME}) ;
		}
	}

return(\%node_dependencies) ;
}

#-------------------------------------------------------------------------------

sub AddNodeFileDependencies
{
my $node_regex = shift ;
my @files      = @_ ;

my $package = caller() ;

for my $file_name (@files)
	{
	push @{$node_digest_rules{$package}}, {REGEX => $node_regex, NAME => "__NODE_FILE:$file_name", VALUE => GetCachedFileMD5($file_name)} ;
	}
}

#-------------------------------------------------------------------------------

sub AddNodeEnvironmentDependencies
{
my $node_regex = shift ;
my $package = caller() ;

for (@_)
	{
	if(exists $ENV{$_})
		{
		push @{$node_digest_rules{$package}}, {REGEX => $node_regex, NAME => "__NODE_ENV:$_", VALUE => $ENV{$_}} ;
		}
	else
		{
		push @{$node_digest_rules{$package}}, {REGEX => $node_regex, NAME => "__NODE_ENV:$_", VALUE => ''} ;
		}
	}
}

#-------------------------------------------------------------------------------

sub AddNodeSwitchDependencies
{
my $node_regex = shift ;

my $package    = caller() ;
my $pbs_config = PBS::PBSConfig::GetPbsConfig($package) ;

for (@_)
	{
	if(/^\s*-D\s*(\w+)/)
		{
		if(exists $pbs_config->{COMMAND_LINE_DEFINITIONS}{$1})
			{
			push @{$node_digest_rules{$package}}, {REGEX => $node_regex, NAME => "__NODE_SWITCH:$1", VALUE => $pbs_config->{COMMAND_LINE_DEFINITIONS}{$1}} ;
			}
		else
			{
			push @{$node_digest_rules{$package}}, {REGEX => $node_regex, NAME => "__NODE_SWITCH:$1", VALUE => ''} ;
			}
		}

	if(/^\s*-D\s*\*/)
		{
		for (keys %{$pbs_config->{COMMAND_LINE_DEFINITIONS}})
			{
			push @{$node_digest_rules{$package}}, {REGEX => $node_regex, NAME => "__NODE_SWITCH:$_", VALUE => $pbs_config->{COMMAND_LINE_DEFINITIONS}{$_}} ;
			}
		}

	if(/^\s*-u\s*(\w+)/)
		{
		if(exists $pbs_config->{USER_OPTIONS}{$1})
			{
			push @{$node_digest_rules{$package}}, {REGEX => $node_regex, NAME => "__NODE_SWITCH:$1", VALUE => $pbs_config->{USER_OPTIONS}{$1}} ;
			}
		else
			{
			push @{$node_digest_rules{$package}}, {REGEX => $node_regex, NAME => "__NODE_SWITCH:$1", VALUE => ''} ;
			}
		}

	if(/^\s*-u\s*\*/)
		{
		for (keys %{$pbs_config->{USER_OPTIONS}})
			{
			push @{$node_digest_rules{$package}}, {REGEX => $node_regex, NAME => "__NODE_SWITCH:$_", VALUE => $pbs_config->{USER_OPTIONS}{$_}} ;
			}
		}
	}
}

#-------------------------------------------------------------------------------

sub AddNodeConfigVariableDependencies
{
my $node_regex = shift ;
my $package    = caller() ;

for my $config_variable_name (@_)
	{
	push @{$node_config_variable_dependencies{$package}}, {REGEX => $node_regex, CONFIG_VARIABLE => $config_variable_name} ;
	}
}

#-------------------------------------------------------------------------------

sub AddNodeVariableDependencies 
{
my $node_regex = shift ;
my $package    = caller() ;

while(my ($variable_name, $value) = splice(@_, 0, 2))
	{
	push @{$node_digest_rules{$package}}, {REGEX => $node_regex, NAME => "__NODE_VARIABLE:$variable_name", VALUE => $value} ;
	}
}

#-------------------------------------------------------------------------------

sub ExcludeFromDigestGeneration
{
my ($package, $file_name, $line) = caller() ;

die ERROR "Invalid 'ExcludeFromDigestGeneration' arguments at $file_name:$line\n" if @_ % 2 ;

_ExcludeFromDigestGeneration($package, $file_name, $line, @_) ;
}

sub _ExcludeFromDigestGeneration
{
my ($package, $file_name, $line, %exclusion_patterns) = @_ ;
 
for my $name (keys %exclusion_patterns)
	{
	if(exists $exclude_from_digest{$package}{$name})
		{
		PrintWarning
			(
			"Overriding ExcludeFromDigest entry '$name' defined at $exclude_from_digest{$package}{$name}{ORIGIN}:\n"
			. "\t$exclude_from_digest{$package}{$name}{PATTERN} "
			. "with $exclusion_patterns{$name} defined at $file_name:$line\n"
			) ;
		}
		
	$exclude_from_digest{$package}{$name} = {PATTERN => $exclusion_patterns{$name}, ORIGIN => "$file_name:$line"} ;
	}
}
#-------------------------------------------------------------------------------

sub ForceDigestGeneration
{
my ($package, $file_name, $line) = caller() ;

die ERROR "Invalid 'ForceDigestGeneration' arguments at $file_name:$line\n" if @_ % 2 ;

my %force_patterns = @_ ;
for my $name (keys %force_patterns)
	{
	if(exists $force_digest{$package}{$name})
		{
		PrintWarning
			(
			"Overriding ForceDigestGeneration entry '$name' defined at $force_digest{$package}{$name}{ORIGIN}:\n"
			. "\t$force_digest{$package}{$name}{PATTERN} "
			. "with $force_patterns{$name} defined at $file_name:$line\n"
			) ;
		}
		
	$force_digest{$package}{$name} = {PATTERN => $force_patterns{$name}, ORIGIN => "$file_name:$line"} ;
	}
}

#-------------------------------------------------------------------------------

sub IsDigestToBeGenerated
{
my $package = shift ;
my $node    = shift ;

my $node_name  = $node->{__NAME} ;
my $pbs_config = $node->{__PBS_CONFIG} ;

my $generate_digest = 1 ;

for my $name (keys %{$exclude_from_digest{$package}})
	{
	if($node_name =~ $exclude_from_digest{$package}{$name}{PATTERN})
		{
		if(defined $pbs_config->{DISPLAY_DIGEST_EXCLUSION})
			{
			PrintWarning("'$node_name' excluded from digest generation by rule: '$name' [$exclude_from_digest{$package}{$name}{PATTERN}]") ;
			PrintWarning(" @ $exclude_from_digest{$package}{$name}{ORIGIN}") if defined $pbs_config->{ADD_ORIGIN} ;
			PrintWarning(".\n") ;
			}
			
		$generate_digest = 0 ;
		last ;
		}
	}

for my $name (keys %{$force_digest{$package}})
	{
	if($node_name =~ $force_digest{$package}{$name}{PATTERN})
		{
		if(defined $pbs_config->{DISPLAY_DIGEST_EXCLUSION})
			{
			PrintWarning("'$node_name' digest generation forced by rule: '$name'") ;
			PrintWarning(" @ $force_digest{$package}{$name}{ORIGIN}") if defined $pbs_config->{ADD_ORIGIN} ;
			PrintWarning(".\n") ;
			}
			
		$generate_digest = 1 ;
		last ;
		}
	}

return($generate_digest) ;
}

#-------------------------------------------------------------------------------

sub DisplayAllPackageDigests
{
warn DumpTree(\%package_dependencies, "All package digests:") ;
}

#-------------------------------------------------------------------------------

sub GetAllPackageDigests
{
return(\%package_dependencies) ;
}

#-------------------------------------------------------------------------------

sub IsNodeDigestDifferent
{
my $node = shift ;

return
	(
	CompareExpectedDigestWithDigestFile($node, \&CompareDigests)
	) ;
}

#-------------------------------------------------------------------------------

sub IsNodeDigestIncluded
{
my $node = shift ;

return
	(
	CompareExpectedDigestWithDigestFile($node, \&DigestIsIncluded)
	) ;
}

#-------------------------------------------------------------------------------

sub CompareExpectedDigestWithDigestFile
{
my $node = shift ;
my $comparator = shift ;

my $digest_file_name = GetDigestFileName($node) ;

my $pbs_config = $node->{__PBS_CONFIG} ;
my $package = $node->{__LOAD_PACKAGE} ;

my ($rebuild_because_of_digest, $result_message) = (0, 'digest OK') ;

if(IsDigestToBeGenerated($package, $node))
	{
	if(-e $digest_file_name)
		{
		# check with inotify/archive flag first
		my $current_md5 ;
		
		unless(defined ($current_md5 = GetFileMD5($node->{__BUILD_NAME})))
			{
			$current_md5 = "Can't open '$node->{__BUILD_NAME}' to compute MD5 digest: $!" ;
			}
			
		my $node_digest = 
			{
			  #~ %{GetPackageDigest($node->{__DEPENDING_PACKAGE})}
			  %{GetPackageDigest($node->{__LOAD_PACKAGE})}
			, %{GetNodeDigest($node)}
			, $node->{__NAME} => $current_md5 
			, __DEPENDING_PBSFILE => $node->{__DEPENDING_PBSFILE}
			} ;
			
		my $digest ;
		unless ($digest = do $digest_file_name) 
			{
			warn "couldn't parse '$digest_file_name': $@" if $@;
			}
			
		if('HASH' eq ref $digest)
			{
			if
				(
				$comparator->
					(
					  $node->{__BUILD_NAME}
					, $node_digest
					, $digest
					, $pbs_config->{DISPLAY_DIGEST}
					, $pbs_config->{DISPLAY_DIFFERENT_DIGEST_ONLY} 
					)
				)
				{
				($rebuild_because_of_digest, $result_message) = (1, "Difference in digest.") ;
				}
			}
		else
			{
			($rebuild_because_of_digest, $result_message) = (1, "Empty digest.") ;
			}
		}
	else
		{
		PrintInfo("Digest file '$digest_file_name' not found.\n") if(defined $pbs_config->{DISPLAY_DIGEST}) ;
		($rebuild_because_of_digest, $result_message) = (1, "Digest file '$digest_file_name' not found") ;
		}
	
	}
else
	{
	($rebuild_because_of_digest, $result_message) = (0, 'Excluded from digest') ;
	}
	
return($rebuild_because_of_digest, $result_message) ;
}

#-------------------------------------------------------------------------------

sub IsFileModified
{
my ($pbs_config, $file, $md5) = @_ ;
my $file_is_modified = 0;

# check with inotify/archive flag first
if(defined (my $current_md5 = GetFileMD5($file)))
	{
	unless($current_md5 eq $md5)
		{
		if($pbs_config->{DISPLAY_WARP_TRIGGERED_NODES})	
			{
			PrintDebug "\nWarp: '$file' MD5 mismatch\n" ;
			}
			
		$file_is_modified++ ;
		}
	}
else
	{
	if($pbs_config->{DISPLAY_WARP_TRIGGERED_NODES})	
		{
		PrintDebug "\nWarp: '$file' No such file $@\n" ;
		}
		
	$file_is_modified++ ;
	}

return($file_is_modified) ;
}

#-------------------------------------------------------------------------------

sub CompareDigests
{
my ($name, $expected_digest, $digest, $display_digest, $display_different_digest_only) = @_ ;

#~ print DumpTree $expected_digest, 'expected_digest' ;
#~ print DumpTree $digest, 'digest' ;

my $digest_is_different = 0 ;

my @in_expected_digest_but_not_file_digest ;
my @in_file_digest_but_not_expected_digest ;
my @different_in_file_digest ;

for my $key( keys %$expected_digest)
	{
	if(exists $digest->{$key})
		{
		if
			(
			   (defined $digest->{$key} && ! defined $expected_digest->{$key})
			|| (! defined $digest->{$key} && defined $expected_digest->{$key})
			|| (
				   defined $digest->{$key} && defined $expected_digest->{$key} 
				&& (!Compare($digest->{$key}, $expected_digest->{$key}))
			   )
			)
			{
			push @different_in_file_digest, $key ;
			$digest_is_different++ ;
			}
		}
	else
		{
		push @in_expected_digest_but_not_file_digest, $key ;
		$digest_is_different++ ;
		}
	}
	
for my $key( keys %$digest)
	{
	unless(exists $expected_digest->{$key})
		{
		push @in_file_digest_but_not_expected_digest, $key ;
		$digest_is_different++ ;
		}
	}
	
if($display_digest)
	{
	if($digest_is_different)
		{
		PrintInfo("Digests for file $name are different [$digest_is_different]:\n") ;
		
		#~PrintInfo(Data::Dumper->Dump($digest, "digest:\n")) ;
		#~PrintInfo(Data::Dumper->Dump($expected_digest, "expected_digest:\n")) ;
		
		for my $key (@in_file_digest_but_not_expected_digest)
			{
			my $digest_value = $digest->{$key} || 'undef' ;
			PrintWarning("\tkey '$key' exists only in file digest.\n") ;
			#~ PrintWarning("\tkey '$key' exists only in file digest: $digest_value\n") ; # too verbose
			}
			
		for my $key (@different_in_file_digest)
			{
			my $digest_value = $digest->{$key} || 'undef' ;
			my $expected_digest_value = $expected_digest->{$key} || 'undef' ;
			#PrintError("\tkey '$key' is different.\n") ;
			PrintError("\tkey '$key' is different: $digest_value <=> $expected_digest_value\n") ;
			}
			
		for my $key (@in_expected_digest_but_not_file_digest)
			{
			my $expected_digest_value = $expected_digest->{$key} || 'undef' ;
			PrintError("\tkey '$key' exists only in expected digest.\n") ;
			#~ PrintError("\tkey '$key' exists only in expected digest: $expected_digest_value\n") ;
			}
		}
	else
		{
		PrintInfo("Digests for file '$name' are identical.\n") unless $display_different_digest_only ;
		}
	}

return($digest_is_different) ;
}

#-------------------------------------------------------------------------------

sub DigestIsIncluded
{
my ($name, $expected_digest, $digest, $display_digest, $display_different_digest_only) = @_ ;

#~ print DumpTree $expected_digest, 'expected_digest' ;
#~ print DumpTree $digest, 'digest' ;

my $digest_is_different = 0 ;

my @in_expected_digest_but_not_file_digest ;
my @in_file_digest_but_not_expected_digest ;
my @different_in_file_digest ;

for my $key( keys %$expected_digest)
	{
	if(exists $digest->{$key})
		{
		if
			(
			   (defined $digest->{$key} && ! defined $expected_digest->{$key})
			|| (! defined $digest->{$key} && defined $expected_digest->{$key})
			|| (
				   defined $digest->{$key} && defined $expected_digest->{$key} 
				&& !Compare($digest->{$key}, $expected_digest->{$key})
			   )
			)
			{
			push @different_in_file_digest, $key ;
			$digest_is_different++ ;
			}
		}
	else
		{
		push @in_expected_digest_but_not_file_digest, $key ;
		$digest_is_different++ ;
		}
	}
	
if($display_digest)
	{
	if($digest_is_different)
		{
		PrintInfo("Digests for file $name are diffrent [$digest_is_different]:\n") ;
		
		for my $key (@in_file_digest_but_not_expected_digest)
			{
			my $digest_value = $digest->{$key} || 'undef' ;
			PrintWarning("\tkey '$key' exists only in file digest.\n") ;
			#~ PrintWarning("\tkey '$key' exists only in file digest: $digest_value\n") ; # too verbose
			}
			
		for my $key (@different_in_file_digest)
			{
			my $digest_value = $digest->{$key} || 'undef' ;
			my $expected_digest_value = $expected_digest->{$key} || 'undef' ;
			#PrintError("\tkey '$key' is different.\n") ;
			PrintError("\tkey '$key' is different: $digest_value <=> $expected_digest_value\n") ;
			}
			
		for my $key (@in_expected_digest_but_not_file_digest)
			{
			my $expected_digest_value = $expected_digest->{$key} || 'undef' ;
			PrintError("\tkey '$key' exists only in expected digest.\n") ;
			#~ PrintError("\tkey '$key' exists only in expected digest: $expected_digest_value\n") ;
			}
		}
	else
		{
		PrintInfo("Digest for file '$name' are identical.\n") unless $display_different_digest_only ;
		}
	}

return(!$digest_is_different) ;
}

#-------------------------------------------------------------------------------

sub GetDigestFileName
{
my ($node) = @_ ;

my $file_name = $node->{__BUILD_NAME} ;
my $digest_file_name = $file_name . '.pbs_md5' ;

# files with full path get their digest file in the same path as the 
# file defeating the output path
if(file_name_is_absolute($node->{__NAME}))
	{
	my ($volume,$directories,$file) = splitpath($file_name);
	my $build_directory = $node->{__PBS_CONFIG}{BUILD_DIRECTORY} ;

	$digest_file_name = "$build_directory/ROOT${directories}$file.pbs_md5" ;
	}
		

return($digest_file_name) ;
}

#-------------------------------------------------------------------------------

sub GenerateNodeDigest
{
my $node = shift ;

my $digest_file_name = GetDigestFileName($node) ;

if(exists $node->{__VIRTUAL} && $node->{__VIRTUAL} == 1)
	{
	if(-e $digest_file_name)
		{
		PrintInfo("Removing digest file: '$digest_file_name'. Node is virtual.\n") ;
		unlink($digest_file_name) ;
		}
		
	return() ;
	}

my $package = $node->{__LOAD_PACKAGE} ;

if(IsDigestToBeGenerated($package, $node))
	{
	WriteDigest
		(
		  $digest_file_name
		, "Pbsfile: $node->{__PBS_CONFIG}{PBSFILE}"
		, GetDigest($node)
		, '' # caller data to be added to digest
		, 1 # create path
		) ;
	}
}

#-------------------------------------------------------------------------------

sub GetDigest
{
my $node = shift ;
my $package = $node->{__LOAD_PACKAGE} ;

PrintDebug "$node->{__NAME} doesn't have __DEPENDING_PBSFILE\n" unless exists $node->{__DEPENDING_PBSFILE} ;
return
	{
	  %{GetPackageDigest($package)}
	#TODO , map {$_ => GetCachedFileMD5($_)} PBS::Plugin::GetLoadedPlugins()
	# TODO: depend on pbs install
	, %{GetNodeDigest($node)}
	, $node->{__NAME} => GetCachedFileMD5($node->{__BUILD_NAME})
	, __DEPENDING_PBSFILE =>  $node->{__DEPENDING_PBSFILE}
	} ;
}

#-------------------------------------------------------------------------------

sub WriteDigest
{
my ($digest_file_name, $caller_information, $digest, $caller_data, $create_path) = @_ ;

if($create_path)
	{
	my ($basename, $path, $ext) = File::Basename::fileparse($digest_file_name, ('\..*')) ;
	
	use File::Path ;
	mkpath($path) unless(-e $path) ;
	}
	
open NODE_DIGEST, ">", $digest_file_name  or die ERROR("Can't open '$digest_file_name' for writting: $!\n") ;

use POSIX qw(strftime);
my $now_string = strftime "%a %b %e %H:%M:%S %Y", gmtime;

my $HOSTNAME = $ENV{HOSTNAME} || qx"hostname" || 'no_host' ;
my $user = PBS::PBSConfig::GetUserName() ;

$caller_information = '' unless defined $caller_information ;
$caller_information =~ s/^/# /g ;

print NODE_DIGEST <<EOH ;
# This file is automaticaly generated by PBS (Perl Build System).
# Digest.pm version $VERSION

# File: $digest_file_name
# Date: $now_string 
# User: $user @ $HOSTNAME
$caller_information

EOH

print NODE_DIGEST "$caller_data\n" if defined $caller_data ;

print NODE_DIGEST Data::Dumper->Dump([$digest], ['digest']) ;
close(NODE_DIGEST) ;
}

#-------------------------------------------------------------------------------

1 ;

__END__
=head1 NAME

PBS::Digest  -

=head1 SYNOPSIS

	#within a Pbsfile
	
	AddFileDependencies('/usr/bin/gcc') ;
	AddEnvironmentDependencies('PROJECT') ;
	AddSwitchDependencies('-D*', '-u*') ;
	AddVariableDependencies('gcc_version' => GetGccVersion()) ;
	AddNodeFileDependencies(qr/^.\/file_name$/, 'pbs.html') ;
	
=head1 DESCRIPTION

This module handle s all the digest functionality of PBS. It also make available, to the user,  a set of functions
that can be used in I<Pbsfiles> to add information to the node digest generated by B<PBS>

=head2 EXPORT

All the node specific functions take a regular expression (string or qr) as a first argument.
only nodes matching that regex will be dependent on the rest of the arguments.

	# make all the nodes dependent on the compiler
	# including documentation, libraries, text files and whatnot
	AddVariableDependencies(compiler => GetCompilerInfo()) ;


	# c files only depend on the compiler
	AddNodeVariableDependencies(qr/\.c$/, compiler => GetCompilerInfo()) ;
	
AddFileDependencies, AddNodeFileDependencies: this function is given a list of file names. 

AddEnvironmentDependencies, AddNodeEnvironmentDependencies: takes a list of environnement variables.

AddVariableDependencies, AddNodeVariableDependency: takes a list of tuples (variable_name => value).

AddConfigVariableDependencies AddNodeConfigVariableDependencies: takes a list of tuples (variable_name).
	the variable's value is extracted from the node's config when generating the digest.

AddSwitchDependencies, AddNodeSwitchDependencies: handles command line switches B<-D> and B<-u>.
	AddNodeSwitchDependencies('node_which_uses_my_user_switch_regex' => '-u my_user_switch) ;
	AddSwitchDependencies('-D gcc'); # all node depend on the '-D gcc' switch.
	AddSwitchDependencies('-D*') ; # all nodes depend on all'-D' switches.


ExcludeFromDigestGeneration('rule_name', $regex): the nodes matching $regex will not have any digest attached. Digests are 
for nodes that B<PBS> can build. Source files should not have any digest. 'rule_name' is displayed by PBS for your information.
	# extracted from the 'Rules/C' module
	ExcludeFromDigestGeneration( 'c_files' => qr/\.c$/) ;
	ExcludeFromDigestGeneration( 's_files' => qr/\.s$/) ;
	ExcludeFromDigestGeneration( 'h_files' => qr/\.h$/) ;
	ExcludeFromDigestGeneration( 'libs'    => qr/\.a$/) ;

ForceDigestGeneration('rule_name', $regex): forces the generation of a digest for nodes matching the regex. This is 
usefull if you generate a node that has been excluded via I<ExcludeFromDigestGeneration>.

=head1 AUTHOR

Khemir Nadim ibn Hamouda. nadim@khemir.net

=cut
