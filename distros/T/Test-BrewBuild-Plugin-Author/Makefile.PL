use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Test::BrewBuild::Plugin::Author',
    AUTHOR           => q{Steve Bertrand <steveb@cpan.org>},
    VERSION_FROM     => 'lib/Test/BrewBuild/Plugin/Author.pm',
    ABSTRACT_FROM    => 'lib/Test/BrewBuild/Plugin/Author.pm',
    LICENSE          => 'perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => {
                web => 'https://github.com/stevieb9/test-brewbuild-plugin-author/issues',
            },
            repository => {
                type => 'git',
                url => 'https://github.com/stevieb9/test-brewbuild-plugin-author.git',
                web => 'https://github.com/stevieb9/test-brewbuild-plugin-author',
            },
        },
    },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Test-BrewBuild-Plugin-Author-*' },
);
