use 5.10.1;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'SVN::Rami',
    AUTHOR           => q{Dan Richter <dan.richter@trdpnt.com>},
    VERSION_FROM     => 'lib/SVN/Rami.pm',
    ABSTRACT_FROM    => 'lib/SVN/Rami.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.10.1',
    EXE_FILES        => ['bin/rami'],
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '7.38',
    },
    TEST_REQUIRES => {
        'Test::More' => '1.302169',
    },
    PREREQ_PM => {
		'File::Basename'      => '2.85',
		'File::Path'          => '2.16'
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'SVN-Rami-*' },
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
