# $Id: Makefile.PL 2676 2007-10-03 17:38:27Z andy $
use strict;
use warnings;
use ExtUtils::MakeMaker;

eval 'use ExtUtils::MakeMaker::Coverage';
warn "Optional ExtUtils::MakeMaker::Coverage not available\n" if $@;

WriteMakefile(
    ( MM->can( 'signature_target' ) ? ( SIGN => 1 ) : () ),
    NAME          => 'Parallel::Iterator',
    AUTHOR        => 'Andy Armstrong <andy@hexten.net>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/Parallel/Iterator.pm',
    ABSTRACT_FROM => 'lib/Parallel/Iterator.pm',
    PL_FILES      => {},
    PREREQ_PM     => {
        'Test::More' => 0,
        'Storable'   => 0,
        'IO::Handle' => 0,
        'IO::Select' => 0,
        'Config'     => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Parallel-Iterator-*' },
);
