use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME               => 'NOAA::Aurora',
    AUTHOR             => q{Dimitrios Kechagias <dkechag@cpan.org>},
    VERSION_FROM       => 'lib/NOAA/Aurora.pm',
    ABSTRACT_FROM      => 'lib/NOAA/Aurora.pm',
    LICENSE            => 'perl_5',
    MIN_PERL_VERSION   => '5.008',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test2::V0'               => '0.000143',
        'Test2::Tools::Exception' => '0',
        'LWP::UserAgent'          => '0',
        'HTTP::Response'          => '0',
        'JSON'                    => '0'
    },
    PREREQ_PM  => {
        'Weather::API::Base' => '0.4',
    },
    META_MERGE => {
        "meta-spec" => {version => 2},
        resources   => {
            repository => {
                type => 'git',
                url  => 'git://github.com/dkechag/NOAA-Aurora.git',
                web  => 'https://github.com/dkechag/NOAA-Aurora',
            },
        },
    },
    dist => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
    },
    clean => {FILES => 'NOAA-Aurora-*'},
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
