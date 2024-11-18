use 5.008005;
use ExtUtils::MakeMaker 7.12; # for XSMULTI option

WriteMakefile(
	NAME             => 'Random::Simple',
	VERSION_FROM     => 'lib/Random/Simple.pm',
	PREREQ_PM        => { 'ExtUtils::MakeMaker' => '7.12' },
	ABSTRACT_FROM    => 'lib/Random/Simple.pm',
	AUTHOR           => 'Scott Baker',
	XSMULTI          => 1,
	AUTHOR           => 'Scott Baker <bakerscot@cpan.org>',
	LICENSE          => 'mit',
	MIN_PERL_VERSION => '5.012',

	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
	},
	TEST_REQUIRES => {
		'Test::More' => '0',
	},
	PREREQ_PM => { },

	META_MERGE => {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				url => 'https://github.com/scottchiefbaker/perl-Random-Simple.git',
				web => 'https://github.com/scottchiefbaker/perl-Random-Simple',
				type => 'git'
			}
		}
	},
);
