use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::OpenVPN::Launcher',
    AUTHOR           => q{David Farrell <sillymoos@cpan.org>},
    VERSION_FROM     => 'lib/Net/OpenVPN/Launcher.pm',
    ABSTRACT_FROM    => 'lib/Net/OpenVPN/Launcher.pm',
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
        'Method::Signatures'        => 20130505,
        Moo                         => 1.003000,
        Carp                        => 1.26,
        'IPC::Cmd'                  => 0.84, 
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-OpenVPN-Launcher-*' },
);
