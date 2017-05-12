use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'TRD::Uranai',
    AUTHOR              => 'Takuya Ichikawa <trd.ichi@gmail.com>',
    VERSION_FROM        => 'lib/TRD/Uranai.pm',
    ABSTRACT_FROM       => 'lib/TRD/Uranai.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
		'LWP::UserAgent' => 0,
		'Jcode' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'TRD-Uranai-*' },
);
