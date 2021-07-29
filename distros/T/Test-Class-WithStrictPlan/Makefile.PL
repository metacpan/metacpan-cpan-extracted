use ExtUtils::MakeMaker 6.68;
WriteMakefile(
	NAME             => 'Test::Class::WithStrictPlan',
	VERSION_FROM     => 'lib/Test/Class/WithStrictPlan.pm',
	ABSTRACT_FROM    => 'lib/Test/Class/WithStrictPlan.pm',
	AUTHOR           => 'Pali <pali@cpan.org>',
	LICENSE          => 'perl_5',
	MIN_PERL_VERSION => '5.6.0',

	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker'    => '6.68',
	},
	PREREQ_PM => {
		'parent'                 => '0',
		'strict'                 => '0',
		'warnings'               => '0',
		'Test::Class'            => '0.51',
	},
	TEST_REQUIRES => {
		'Test::More'             => '0',
	},
	META_MERGE => {
		'meta-spec' => {
			version => 2,
		},
		'resources' => {
			bugtracker => {
				web  => 'https://github.com/pali/Test-Class-WithStrictPlan/issues',
			},
			repository => {
				url  => 'git://github.com/pali/Test-Class-WithStrictPlan.git',
				web  => 'https://github.com/pali/Test-Class-WithStrictPlan',
				type => 'git',
			},
		},
		'dynamic_config' => 0,
	},
);
