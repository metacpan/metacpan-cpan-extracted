use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SOAP::Amazon::MerchantTransport',
    AUTHOR              => 'Nate Murray <nate@natemurray.com>',
    VERSION_FROM        => 'lib/SOAP/Amazon/MerchantTransport.pm',
    ABSTRACT_FROM       => 'lib/SOAP/Amazon/MerchantTransport.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SOAP-Amazon-MerchantTransport-*' },
);
