use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME      => 'Search::Binary',
    VERSION_FROM   => 'lib/Search/Binary.pm',
    MIN_PERL_VERSION => '5.6.0',
    PREREQ_PM => {
        'Carp' => 0,
        'Exporter' => 0,
        'lib' => 0,
        'parent' => 0,
        'strict' => 0,
        'warnings' => 0,
    },
    TEST_REQUIRES => {
        'Test::More' => 0.96,
        'Test::Warnings' => 0.012,
    },
    ABSTRACT_FROM => 'lib/Search/Binary.pm',
    AUTHOR => 'Erik Rantapaa <rantapaa@uswest.net>',
    LICENSE => 'perl_5',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url => 'git://github.com/Xaerxess/Search-Binary.git',
                web => 'https://github.com/Xaerxess/Search-Binary',
            },
            bugtracker => {
                web => 'https://rt.cpan.org/Dist/Display.html?Name=Search-Binary',
            },
        },
    },
    test => {
        TESTS => "t/*.t"
    },
);

unless (eval { ExtUtils::MakeMaker->VERSION(6.64) }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES};
    if (eval { ExtUtils::MakeMaker->VERSION(6.5503) }) {
        $WriteMakefileArgs{BUILD_REQUIRES} = $test_requires;
    }
}

unless (eval { ExtUtils::MakeMaker->VERSION(6.48) }) {
    delete $WriteMakefileArgs{MIN_PERL_VERSION};
}

unless (eval { ExtUtils::MakeMaker->VERSION(6.46) }) {
    delete $WriteMakefileArgs{META_MERGE};
}

unless (eval { ExtUtils::MakeMaker->VERSION(6.31) }) {
    delete $WriteMakefileArgs{LICENSE};
}

WriteMakefile(%WriteMakefileArgs);
