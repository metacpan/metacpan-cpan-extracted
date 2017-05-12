
my %versions = 
	(
	  gcc =>
		{
		COMPILER => 'gcc'
		}
		
	, arm =>
		{
		COMPILER => 'arm'
		}
	, cl =>
		{
		  COMPILER => 'gcc'
		, EXTRA_OBJECT_FILES => 1 
		}
	) ;

#----------------------------------------------------------------------------------------------------

AddRule [VIRTUAL], "all",['all' => undef], BuildOk() ;

for my $version (keys %versions)
	{
	AddRule [VIRTUAL], "all_$version",['all' => "${version}_A"] ;
	
	AddRule "sub_pbsfile_$version",
		{
		  NODE_REGEX      => "${version}_A"
		, ALIAS           => "A.lib"
		, PBSFILE         => 'sub.pl'
		, PACKAGE         => 'LIB'
		, BUILD_DIRECTORY => $version
		, LOCAL_NODES     => 1 # Allows us to  have multiple nodes with the same name
		, COMMAND_LINE_DEFINITIONS => $versions{$version}
		} ;
	}
	

