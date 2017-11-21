use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Pod::Github',
    DISTNAME         => 'Pod-Github',
    ABSTRACT         => 'Make beautiful Markdown readmes from your POD',
    AUTHOR           => q{Richard Harris <richardjharris@gmail.com>},
    VERSION_FROM     => 'lib/Pod/Github.pm',
    LICENSE          => 'perl',
    EXE_FILES        => [ 'bin/pod2github' ],
    PL_FILES         => {},
    MAN1PODS         => { 'bin/pod2github' => 'blib/man1/pod2github.1' },
    MIN_PERL_VERSION => '5.008',
    (ExtUtils::MakeMaker->VERSION(6.52) ? (
        CONFIGURE_REQUIRES => {
            'ExtUtils::MakeMaker' => '0',
        },
    ) : ()),
    BUILD_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
        'Carp' => '0',
        'Encode' => '0',
        'File::Slurp' => '0',
        'Getopt::Long' => '0',
        'parent' => '0',
        'Pod::Markdown' => '3.005',
        'Pod::Usage' => '0',
        'YAML::XS' => '0',
        'Test::More' => '0',
        'FindBin' => '0',
    },
    test  => { TESTS => "t/*.t" },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Pod-Github-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'https://github.com/richardjharris/perl-Pod-Github.git',
                web => 'https://github.com/richardjharris/perl-Pod-Github',
            },
        },
    },
);
