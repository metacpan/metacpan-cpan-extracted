use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::SMTP::IPMM',
    AUTHOR              => 'Mike Friedman <friedo@friedo.com>',
    VERSION_FROM        => 'lib/Net/SMTP/IPMM.pm',
    ABSTRACT_FROM       => 'lib/Net/SMTP/IPMM.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-SMTP-IPMM-*' },
);
