use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::ICAP::Client',
    AUTHOR           => q{David Dick <ddick@cpan.org>},
    VERSION_FROM     => 'lib/Net/ICAP/Client.pm',
    ABSTRACT_FROM    => 'lib/Net/ICAP/Client.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'File::Temp' => 0,
        'HTTP::Headers' => 0,
    },
    PREREQ_PM => {
        'strict'            => 0, 
        'warnings'          => 0,
        'English'           => 0,
        'IO::Socket::INET'  => 0,
        'IO::Socket::SSL'   => 0,
        'Carp'              => 0,
        'URI'               => 0,
        'HTTP::Request'     => 0,
        'HTTP::Response'    => 0,
        'POSIX'             => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-ICAP-Client-*' },
);
