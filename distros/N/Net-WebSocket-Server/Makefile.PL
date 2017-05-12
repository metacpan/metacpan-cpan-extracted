use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::WebSocket::Server',
    AUTHOR           => q{Eric Wastl <topaz@cpan.org>},
    VERSION_FROM     => 'lib/Net/WebSocket/Server.pm',
    ABSTRACT_FROM    => 'lib/Net/WebSocket/Server.pm',
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
        'Protocol::WebSocket' => 0.12,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-WebSocket-Server-*' },
);
