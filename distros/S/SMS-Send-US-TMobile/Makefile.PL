use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SMS::Send::US::TMobile',
    AUTHOR              => 'Daniel Muey <http://drmuey.com/cpan_contact.pl>',
    VERSION_FROM        => 'lib/SMS/Send/US/TMobile.pm',
    ABSTRACT_FROM       => 'lib/SMS/Send/US/TMobile.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'        => 0,
        'version'           => 0,
        'Net::SSLeay'       => 0,
        'URI::Escape'       => 0,
        'SMS::Send::Driver' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SMS-Send-US-TMobile-*' },
);
