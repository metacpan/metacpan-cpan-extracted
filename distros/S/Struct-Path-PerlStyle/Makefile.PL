use 5.010;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Struct::Path::PerlStyle',
    AUTHOR           => 'Michael Samoglyadov <mixas@cpan.org>',
    VERSION_FROM     => 'lib/Struct/Path/PerlStyle.pm',
    ABSTRACT_FROM    => 'lib/Struct/Path/PerlStyle.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Clone'        => 0,
        'Test::More'   => 0.94,  # subtest support
    },
    META_MERGE => {
        resources => {
            repository  => 'https://github.com/mr-mixas/Struct-Path-PerlStyle.pm',
        },
    },
    PREREQ_PM => {
        'Carp'              => 0,
        'Safe'              => 0,
        'Text::Balanced'    => 0,
        'Scalar::Util'      => 1.18,
        'parent'            => 0,
        're'                => 0.08, # it seems eralier versions has no is_regexp() and regexp_pattern()
        'strict'            => 0,
        'warnings'          => 0
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Struct-Path-PerlStyle-* cover_db' },
);
