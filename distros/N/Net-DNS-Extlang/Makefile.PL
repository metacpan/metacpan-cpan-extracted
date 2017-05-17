use 5.016;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::DNS::Extlang',
    AUTHOR           => q{John Levine <extlang@m.jl.ly>},
    VERSION_FROM     => 'lib/Net/DNS/Extlang.pm',
    ABSTRACT_FROM    => 'lib/Net/DNS/Extlang.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    EXE_FILES        => [ 'script/RRTYPEgen' ],
    MIN_PERL_VERSION => 5.016,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Net::DNS'              => 1.07,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-DNS-Extlang-*' },
);
