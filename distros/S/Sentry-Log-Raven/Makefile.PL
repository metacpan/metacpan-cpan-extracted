use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Sentry::Log::Raven',
    AUTHOR           => q{Dan Gardiner <daniel@theenginuity.com>},
    VERSION_FROM     => 'lib/Sentry/Log/Raven.pm',
    ABSTRACT_FROM    => 'lib/Sentry/Log/Raven.pm',
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
	'JSON' => 2.0,
        'HTTP::Request::Common' => 0,
        'LWP::UserAgent' => 0,
        'MIME::Base64' => 0,
        'Time::HiRes' => 0,
        'DateTime' => 0,
        'Sys::Hostname' => 0,
        'Mozilla::CA' => 0,
        'IO::Socket::SSL' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Sentry-Log-Raven-*' },
);
