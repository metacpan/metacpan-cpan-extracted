use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Plack::Middleware::DNSBL',
    AUTHOR           => q{Victor Franco <victorfrancovl@gmail.com>},
    VERSION_FROM     => 'lib/Plack/Middleware/DNSBL.pm',
    ABSTRACT_FROM    => 'lib/Plack/Middleware/DNSBL.pm',
    LICENSE          => 'perl',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Net::DNS' => 0,
        'Plack'    => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Plack-Middleware-DNSBL-*' },
);
