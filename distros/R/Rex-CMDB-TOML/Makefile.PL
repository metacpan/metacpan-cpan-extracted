use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
	NAME               => 'Rex::CMDB::TOML',
	AUTHOR             => q{Zane C. Bowers-Hadley <vvelox@vvelox.net>},
	VERSION_FROM       => 'lib/Rex/CMDB/TOML.pm',
	ABSTRACT_FROM      => 'lib/Rex/CMDB/TOML.pm',
	LICENSE            => 'apache_2_0',
	MIN_PERL_VERSION   => '5.006',
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
	},
	TEST_REQUIRES => {
		'Test::More' => '0',
	},
	PREREQ_PM => {
		'Rex::Logger'         => '0',
		'Rex::Commands'       => '0',
		'Data::Dumper'        => '0',
		'Hash::Merge'         => '0',
		'Rex::Commands::File' => '0',
		'TOML'                => '0',
	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES    => 'Rex-CMDB-TOML-*' },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless ( eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 } ) {
	my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
	@{ $WriteMakefileArgs{PREREQ_PM} }{ keys %$test_requires } = values %$test_requires;
}

unless ( eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 } ) {
	my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
	@{ $WriteMakefileArgs{PREREQ_PM} }{ keys %$build_requires } = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
	unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
	unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
	unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
