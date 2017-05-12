use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SMS::Send::AT::SmsAt',
    AUTHOR              => 'Stefan Seifert <stefan.seifert@atikon.com>',
    VERSION_FROM        => 'lib/SMS/Send/AT/SmsAt.pm',
    ABSTRACT_FROM       => 'lib/SMS/Send/AT/SmsAt.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'SMS::Send'   => 0,
        'XML::XPath'  => 0,
        'XML::Writer' => 0,
        'LWP::UserAgent' => 0,
        'Carp'        => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SMS-Send-AT-SmsAt-*' },
);
