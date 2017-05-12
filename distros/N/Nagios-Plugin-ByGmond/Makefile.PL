use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Nagios::Plugin::ByGmond',
    AUTHOR           => q{chenryn <rao.chenlin@gmail.com>},
    VERSION_FROM     => 'lib/Nagios/Plugin/ByGmond.pm',
    ABSTRACT_FROM    => 'lib/Nagios/Plugin/ByGmond.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'IO::Socket::INET' => 0,
        'Nagios::Plugin'   => 0,
        'XML::Simple'      => 0,
    },
    'EXE_FILES' => [
        'bin/check_by_gmond'
    ],
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Nagios-Plugin-ByGmond-*' },
);
