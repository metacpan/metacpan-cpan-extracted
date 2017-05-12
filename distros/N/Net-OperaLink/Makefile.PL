use 5.010;
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::OperaLink',
    AUTHOR              => 'Opera Software ASA <cpan@opera.com>',
    LICENSE             => 'BSD',
    VERSION_FROM        => 'lib/Net/OperaLink.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'feature'          => 0,
        'Test::More'       => 0,
        'LWP::UserAgent'   => 0,
        'CGI'              => 0,
        'URI'              => 0,
        'Net::OAuth'       => 0.25,
        'JSON::XS'         => 0,
    },
    META_MERGE => {
        resources => {
            repository => 'http://github.com/operasoftware/perl5-net-operalink',
            bugtracker => 'https://bugs.opera.com',
        },
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'GeoDns-*' },
);

