use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::OpenSRS::Email_APP',
    AUTHOR              => q{Mark Goldfinch <mark.goldfinch@modicagroup.com>},
    VERSION_FROM        => 'lib/Net/OpenSRS/Email_APP.pm',
    ABSTRACT            => 'Communicate using the OpenSRS Email Service Account Provisioning Protocol',
    ($ExtUtils::MakeMaker::VERSION ge 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'IO::Socket::SSL' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-OpenSRS-Email_APP-*' },
);
