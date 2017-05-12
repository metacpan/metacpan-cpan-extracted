use 5.010;
use ExtUtils::MakeMaker;

WriteMakefile(
		NAME => 'SQL::Exec',
		AUTHOR => 'Mathias Kende <mathias@cpan.org>',
		VERSION_FROM => 'lib/SQL/Exec.pm',
		ABSTRACT_FROM => 'lib/SQL/Exec.pm',
		#README_FROM => 'lib/SQL/Exec.pm',
		LICENSE => 'perl',
		MIN_PERL_VERSION => '5.10.1',
		CONFIGURE_REQUIRES => {
				'ExtUtils::MakeMaker' => 6.3002,
			},
		BUILD_REQUIRES => {
				'Test::Subs' => 0,
				'DBD::SQLite' => 0,
				'String::Replace' => 0,
			},
		PREREQ_PM => {
				'Exporter' => 0,
				'Carp' => 0,
				'DBI' => 0,
				'DBI::Const::GetInfoType' => 0,
				'Scalar::Util' => 0,
				'List::MoreUtils' => 0,
				'DBIx::Connector' => 0,
				'SQL::SplitStatement' => 0,
    		},
	);

