#!perl -w

require 5.008001;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::Reddit',
    DISTNAME		 => 'Net-Reddit',
    VERSION_FROM     => 'lib/Net/Reddit.pm',
    ABSTRACT   		 => 'reddit API interface',
    AUTHOR           => q{Daniel Torres <daniel.torres@owasp.org>},  
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.008001,
    PREREQ_PM => {
        'Moose' => 0,
        'Net::SSL' => 0,
        'LWP::UserAgent' => 0,
        'HTTP::Cookies' => 0,
        'JSON' => 0,
        'DeathByCaptcha::SocketClient' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-Reddit-*' },
);
