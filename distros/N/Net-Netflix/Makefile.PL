use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Netflix',
    AUTHOR              => 'Christie Robertson and Colin Meyer <pants@helvella.org>',
    VERSION_FROM        => 'lib/Net/Netflix.pm',
    ABSTRACT_FROM       => 'lib/Net/Netflix.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Netflix-*' },
);
