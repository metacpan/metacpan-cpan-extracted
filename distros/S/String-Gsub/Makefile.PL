use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'String::Gsub',
    AUTHOR              => 'YAMASHINA Hio <hio@cpan.org>',
    VERSION_FROM        => 'lib/String/Gsub.pm',
    ABSTRACT_FROM       => 'lib/String/Gsub.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Exporter'   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'String-Gsub-*' },
);
