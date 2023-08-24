use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Resource::Silo',
    AUTHOR           => q{Konstantin Uvarin <khedin@cpan.org>},
    VERSION_FROM     => 'lib/Resource/Silo.pm',
    ABSTRACT_FROM    => 'lib/Resource/Silo.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'   => 7,
    },
    TEST_REQUIRES => {
        'Test::More'            => 1.302015,
        'Test::Exception'       => 0.29,
    },
    PREREQ_PM => {
        'Module::Load'          => 0.32,
        'Scalar::Util'          => 1.23,
        'Sub::Quote'            => 2,
    },
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/dallaylaen/resource-silo-p5/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/dallaylaen/resource-silo-p5.git',
                web => 'https://github.com/dallaylaen/resource-silo-p5',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Resource-Silo-*' },
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
