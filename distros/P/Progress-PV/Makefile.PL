use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Progress::PV',
    AUTHOR              => 'Girish Venkatachalam <girish@gayatri-hitech.com>',
    VERSION_FROM        => 'lib/Progress/PV.pm',
    ABSTRACT		=> 'lib/Progress/PV.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'            => 0,
        'Class::Accessor::Fast' => 0,
        'Class::ErrorHandler'   => 0,
        'IPC::Run'              => 0,
        'MIME::Types'           => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Progress-PV-*' },
);
