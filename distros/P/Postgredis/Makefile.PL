use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Postgredis',
    AUTHOR           => q{Brian Duggan <bduggan@matatu.org>},
    VERSION_FROM     => 'lib/Postgredis.pm',
    ABSTRACT_FROM    => 'lib/Postgredis.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.0020,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Mojo::Pg' => 0,
        'Test::PostgreSQL' => 0,
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Postgredis-*' },
);
