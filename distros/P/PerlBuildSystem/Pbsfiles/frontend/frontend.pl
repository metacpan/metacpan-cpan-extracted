
AddRule [VIRTUAL], 'all', ['all' => 'ib'], \&Builder ;

AddRule [IMMEDIATE_BUILD], 'ib', ['ib'], ["echo %FILE_TO_BUILD"] ;
#~ AddRule [IMMEDIATE_BUILD], 'ib', ['ib' => 'iba', 'ibb'], ["echo %FILE_TO_BUILD"] ;

# same dependency tree as all
AddRule 'subpbs_name',
	{
	  NODE_REGEX         => 'b'
	, PBSFILE            => './virtual_pbsfile'
	, PACKAGE            => 'test'
	, PBS_COMMAND        => DEPEND_CHECK_AND_BUILD
	, PBSFILE_CONTENT => <<EOC
ExcludeFromDigestGeneration('source' => qr/b/) ;

AddRule '', [b => undef],
	[
	  "echo Building '%FILE_TO_BUILD' with virtual subpbs"
	#, "touch %FILE_TO_BUILD"
	] ;
EOC
	} ;

# separate dependency tree
sub Builder
{
my ($config, $file_to_build, $dependencies, $triggering_dependencies, $tree) = @_ ;

my $pbs_config = $tree->{__PBS_CONFIG} ;

return
	(
	PBS::FrontEnd::Pbs
		(
		  COMMAND_LINE_ARGUMENTS => [qw(-p virtual_pbsfile2 target)]
		  
		, PBS_CONFIG =>
			{
			  #~ DISPLAY_NO_STEP_HEADER => 1
			  CREATE_LOG => $pbs_config->{CREATE_LOG}
			, LOG_NAME   => $pbs_config->{LOG_NAME} 
			, DUMP       => $pbs_config->{DUMP} 
			}
			
		, PBSFILE_CONTENT => <<EOC
AddRule '', [target => undef],
	[
	  sub{ PrintUser "Building target in separate PBS.\n" ;}
	, "echo shell command"
	] ;
EOC
		)
	) ;
}
