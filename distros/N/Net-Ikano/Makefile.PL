use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Ikano',
    AUTHOR              => 'Erik Levinson <levinse@freeside.biz>',
    VERSION_FROM        => 'lib/Net/Ikano.pm',
    ABSTRACT_FROM       => 'lib/Net/Ikano.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Ikano-*' },
);
