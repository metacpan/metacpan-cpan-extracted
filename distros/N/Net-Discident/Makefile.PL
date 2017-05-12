use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Discident',
    AUTHOR              => 'Mark Norman Francis <norm@cackhanded.net>',
    VERSION_FROM        => 'lib/Net/Discident.pm',
    ABSTRACT_FROM       => 'lib/Net/Discident.pm',
    PL_FILES            => {},
    EXE_FILES           => [
        'bin/discident',
    ],
    PREREQ_PM => {
        'Modern::Perl' => 0,
        'version'      => 0,
        'HTTP::Lite'   => 0,
        'JSON'         => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Discident-*' },
);
