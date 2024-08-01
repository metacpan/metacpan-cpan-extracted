#
## Copyright (C) Carlos Celso
## All rights reserved.
# 
	use 5.006001;
	use ExtUtils::MakeMaker;

	my %makefile_param =
	(
		NAME => 'SQL::SimpleOps',
		VERSION_FROM => 'lib/SQL/SimpleOps.pm',
		ABSTRACT_FROM => 'lib/SQL/SimpleOps.pod',
		AUTHOR => 'Carlos Celso <ccelso@cpan.org>',
		LICENSE => 'GPL_3',
		META_MERGE =>
		{
			'meta-spec' => { version => 2 },
			resources =>
			{
				license => 'http://www.gnu.org/licenses/gpl-3.0.html',
				homepage => 'https://sourceforge.net/p/csi-sql-simpleops/wiki/Home/',
#				bugtracker => { web => 'https://sourceforge.net/p/csi-sql-simpleops/tickets/' },
				bugtracker => 'https://sourceforge.net/p/csi-sql-simpleops/tickets/',
				repository =>
				{
					type => 'git',
					url => 'https://sourceforge.net/projects/csi-sql-simpleops/files',
					web => 'https://sourceforge.net/projects/csi-sql-simpleops/',
				},
			},
		},
		CONFIGURE_REQUIRES =>
		{
			'ExtUtils::MakeMaker' => 0,
		},
		BUILD_REQUIRES => {},
		PREREQ_PM =>
		{
			'Date::Calc' => 0,
			'DBI' => 0,
			'File::Path' => 0,
			'File::Spec' => 0,
			'IO::File' => 0,
			'JSON' => 0,
			'Sys::Syslog' => 0,
		},
		TEST_REQUIRES =>
		{
			'Test::More' => 0,
			'DBD::SQLite' => 0,
		},
		dist => { COMPRESS => "gzip -9", SUFFIX => "gz" },
	);
	#
	## test makemaker version and supported options
	#
	if ( !eval { ExtUtils::MakeMaker->VERSION(6.63_03); } )
	{
		$makefile_param{PREREQ_PM} = 
		{
			%{ delete $makefile_param{TEST_REQUIRES} },
			%{ delete $makefile_param{BUILD_REQUIRES} },
		};
	}
	if ( !eval { ExtUtils::MakeMaker->VERSION(6.52) } )
	{
		delete $makefile_param{CONFIGURE_REQUIRES};
	}
	if ( !eval { ExtUtils::MakeMaker->VERSION(6.48) } )
	{
		delete $makefile_param{MIN_PERL_VERSION};
	}
	#
	## write my makefile
	#
	WriteMakefile(%makefile_param);

##ENDED
