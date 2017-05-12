use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'POE::Devel::Top',
    AUTHOR              => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    VERSION_FROM        => 'lib/POE/Devel/Top.pm',
    ABSTRACT_FROM       => 'lib/POE/Devel/Top.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        # prereqs
        'POE'               => 0,
        'POE::API::Peek'    => 0,
        'Term::ANSIColor'   => 0,

        # build/test prereqs
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'POE-Devel-Top-*' },
);
