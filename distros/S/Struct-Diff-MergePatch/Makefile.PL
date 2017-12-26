use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Struct::Diff::MergePatch',
    AUTHOR           => 'Michael Samoglyadov <mixas@cpan.org>',
    VERSION_FROM     => 'lib/Struct/Diff/MergePatch.pm',
    ABSTRACT_FROM    => 'lib/Struct/Diff/MergePatch.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Clone'                 => 0,
        'Data::Dumper'          => 0,
        'Test::More'            => 0,
    },
    META_MERGE => {
        resources => {
            repository  => 'https://github.com/mr-mixas/Struct-Diff-MergePatch.pm',
        },
    },
    PREREQ_PM => {
        'Struct::Diff'          => 0.93,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Struct-Diff-MergePatch-*' },
);
