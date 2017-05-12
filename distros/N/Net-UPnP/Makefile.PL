use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::UPnP',
    AUTHOR              => 'Satoshi Konno <skonno@cybergarage.org>',
    VERSION_FROM        => 'lib/Net/UPnP.pm',
    ABSTRACT_FROM       => 'lib/Net/UPnP.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-UPnP-*' },
);
