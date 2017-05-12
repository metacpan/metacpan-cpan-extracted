use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::SMS::Massenversand',
    AUTHOR              => 'Manuel Laux <laux@medicalrecall.de>',
    VERSION_FROM        => 'lib/Net/SMS/Massenversand.pm',
    ABSTRACT_FROM       => 'lib/Net/SMS/Massenversand.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Crypt::SSLeay' => 0,
        'URI' => 0,
        'URI::QueryParam' => 0,
        'LWP::UserAgent' => 0,
        'Class::Accessor::Fast' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-SMS-Massenversand-*' },
);
