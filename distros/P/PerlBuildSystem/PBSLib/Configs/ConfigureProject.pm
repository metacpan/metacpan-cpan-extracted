
use strict ;
use warnings ;

#-------------------------------------------------------------------------------

my $project_config = GetConfig("PROJECT_CONFIG") ;
my (undef, $file, $line) = caller(2) ;

if(defined $project_config && 'HASH' eq ref $project_config)
	{
	unless (GetConfig('PROJECT_CONFIGURED'))
		{
		eval {PbsUse($project_config->{CONFIGURATION}) ;} ;
		
		if($@)
			{
			die ERROR ("Error while loading project configuration '$project_config->{CONFIGURATION}' at  $file:$line:\n   $@") ;
			}
		}

	eval {PbsUse($project_config->{RULES}) ;} ;
		
	if($@)
		{
		die ERROR ("Error while loading project rules '$project_config->{RULES}' at  $file:$line:\n   $@") ;
		}

	AddConfig('PROJECT_CONFIGURED:SILENT_OVERRIDE' => 1);

	}
else
	{
	die ERROR("Error loading project configuration: variable 'PROJECT_CONFIG' is not set properly at $file:$line.\n") ;
	}

#-------------------------------------------------------------------------------
1 ;
