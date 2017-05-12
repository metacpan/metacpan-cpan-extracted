use 5.010001;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojolicious::Plugin::SessionCompress',
    AUTHOR           => q{Sean Ohashi <adura83+cpan@gmail.com>},
    VERSION_FROM     => 'lib/Mojolicious/Plugin/SessionCompress.pm',
    ABSTRACT_FROM    => 'lib/Mojolicious/Plugin/SessionCompress.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010001,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Data::Dumper' => 0,
        'FindBin'      => 0,
        'lib'          => 0,
        'Test::More'   => 0
    },
    PREREQ_PM => {
        'Compress::Zlib' => 0,
        'Mojolicious'    => 5.07
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mojolicious-Plugin-SessionCompress-*' },
);
