use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Netcat',
    AUTHOR              => 'Girish Venkatachalam <girish@gayatri-hitech.com>',
    VERSION_FROM        => 'lib/Net/Netcat.pm',
    ABSTRACT_FROM       => 'lib/Net/Netcat.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'            => 0,
        'Class::Accessor::Fast' => 0,
        'Class::ErrorHandler'   => 0,
        'IPC::Run'              => 0,
        'MIME::Types'           => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Netcat-*' },
);
