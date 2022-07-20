use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'PlayStation::MemoryCard',
    AUTHOR           => "Gavin Hayes <gahayes\@cpan.org>",
    VERSION_FROM     => 'lib/PlayStation/MemoryCard.pm',
    ABSTRACT_FROM    => 'lib/PlayStation/MemoryCard.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    PREREQ_PM => {
        'Image::GIF::Encoder::PP' => '0'
    },
    EXE_FILES => ['script/lsmc', 'script/mciconextract', 'script/mcs2raw', 'script/mcsaveextract', 'script/mkmcd', 'script/raw2mcs'],
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => ['PlayStation-MemoryCard-*']},
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/G4Vi/psx_mc_cli.git',
                web  => 'https://github.com/G4Vi/psx_mc_cli',
            },
            bugtracker => {
                web => 'https://github.com/G4Vi/psx_mc_cli/issues'
            },
            homepage   => 'https://github.com/G4Vi/psx_mc_cli',
        },
        'dynamic_config' => 0,
        'x_static_install' => 1
    },
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
