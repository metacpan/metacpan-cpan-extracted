use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::ICAP::Client',
    AUTHOR           => q{David Dick <ddick@cpan.org>},
    VERSION_FROM     => 'lib/Net/ICAP/Client.pm',
    ABSTRACT_FROM    => 'lib/Net/ICAP/Client.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    (
        $ExtUtils::MakeMaker::VERSION >= 6.48
        ? ( 'MIN_PERL_VERSION' => '5.006' )
        : ()
    ),
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                url  => 'https://github.com/david-dick/net-icap-client',
                web  => 'https://github.com/david-dick/net-icap-client',
                type => 'git',
            },
            bugtracker => {
                web => 'https://github.com/david-dick/net-icap-client/issues'
            },
        },
    },
    PL_FILES         => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'File::Temp' => 0,
        'HTTP::Headers' => 0,
        'Pod::Coverage' => 0.18,
        'Test::CheckManifest' => 0.9,
        'Test::More' => 0,
        'Test::Pod::Coverage' => 1.08,
    },
    PREREQ_PM => {
        'strict'            => 0, 
        'warnings'          => 0,
        'English'           => 0,
        'IO::Socket::INET'  => 0,
        'IO::Socket::SSL'   => 0,
        'Carp'              => 0,
        'URI'               => '5.20', # includes URI::icap and URI::icaps
        'HTTP::Request'     => 0,
        'HTTP::Response'    => 0,
        'POSIX'             => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Net-ICAP-Client-*' },
);
