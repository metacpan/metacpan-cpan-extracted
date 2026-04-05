use 5.008003;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
	NAME             => 'Object::Proto::Sugar',
	AUTHOR           => ['LNATION <email@lnation.org>'],
	VERSION_FROM     => 'lib/Object/Proto/Sugar.pm',
	ABSTRACT_FROM    => 'lib/Object/Proto/Sugar.pm',
	LICENSE          => 'artistic_2',
	MIN_PERL_VERSION => '5.008003',
	macro => { TARFLAGS   => "--format=ustar -c -v -f" },
	CONFIGURE_REQUIRES => {
		'ExtUtils::MakeMaker' => '0',
	},
	TEST_REQUIRES => {
		'Test::More' => '0',
	},
	PREREQ_PM => {
		'BEGIN::Lift' => '0.07',
		'Devel::Hook' => '0',
		'Object::Proto' => '0.05',
		'Carp' => '0',
	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
	clean => { FILES => 'Object-Proto-Sugar-*' },
);

# Compatibility with old versions of ExtUtils::MakeMaker
unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
	my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
	@{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

unless (eval { ExtUtils::MakeMaker->VERSION('6.55_03'); 1 }) {
	my $build_requires = delete $WriteMakefileArgs{BUILD_REQUIRES} || {};
	@{$WriteMakefileArgs{PREREQ_PM}}{keys %$build_requires} = values %$build_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
