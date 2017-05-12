use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Net::Vitelity',
    AUTHOR              => 'Ivan Kohler <ivan-vitelity@freeside.biz>',
    VERSION_FROM        => 'lib/Net/Vitelity.pm',
    ABSTRACT_FROM       => 'lib/Net/Vitelity.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'LWP::UserAgent' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Net-Vitelity-*' },
);
