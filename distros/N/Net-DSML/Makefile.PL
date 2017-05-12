use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::DSML',
    AUTHOR              => 'Clif Harden <charden@pobox.com>',
    VERSION_FROM        => 'lib/Net/DSML.pm',
    ABSTRACT_FROM       => 'lib/Net/DSML.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::Simple' => 0.70,
        'version'    => '0.680',
        'Class::Std::Utils'   => '0.0.2',
        'MIME::Base64'        => '3.050',
        'LWP::UserAgent'      => '2.033',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-DSML-*' },
);
