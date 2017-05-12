use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Parse::AccessLogEntry::Accessor',
    AUTHOR              => 'Ryoji Tanida <ryo2.amari3@gmail.com>',
    VERSION_FROM        => 'lib/Parse/AccessLogEntry/Accessor.pm',
    ABSTRACT_FROM       => 'lib/Parse/AccessLogEntry/Accessor.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Parse::AccessLogEntry' => 0,
        'Class::Accessor::Fast' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Parse-AccessLogEntry-Accessor-*' },
);
