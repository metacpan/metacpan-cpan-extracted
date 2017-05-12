use ExtUtils::MakeMaker;
WriteMakefile(
	NAME             => "PEF::CacheLRU",
	AUTHOR           => "Pef Secure",
	VERSION          => "0.02",
	INSTALLDIRS      => 'site',
	LICENSE          => "artistic_2",
	MIN_PERL_VERSION => "5.014000",
	META_MERGE       => {
		"meta-spec" => {version => 2},
		resources   => {
			bugtracker => {web => 'https://github.com/pef-secure/pef-cache-lru/issues'},
			repository => {
				type => 'git',
				url  => 'https://github.com/pef-secure/pef-cache-lru.git',
				web  => 'https://github.com/pef-secure/pef-cache-lru',
			},
		},
	},
	PREREQ_PM     => {},
	TEST_REQUIRES => {'Test::More' => 0},
	test          => {TESTS => "t/*.t"},
	dist          => {
		DIST_DEFAULT => 'all tardist',
		COMPRESS     => 'gzip -vf',
		SUFFIX       => '.gz',
	},
	clean     => {FILES => '*~',},
	realclean => {FILES => '*~',},
);
