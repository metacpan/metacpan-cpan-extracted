use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net-JBoss',
    AUTHOR           => q{"Heince Kurniawan" <"heince@gmail.com">},
    VERSION_FROM     => 'lib/Net/JBoss.pm',
    ABSTRACT_FROM    => 'lib/Net/JBoss.pm',
    "DISTNAME"       => "Net-JBoss",
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.010,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'LWP::UserAgent'        => 5.8,
        'Moo'                   => 2,
        'Log::Log4perl'         => 1,
        'URL::Encode'           => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'JBoss-*' },
);
