use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'POE::Component::Client::BigBrother',
    LICENSE             => 'perl',
    AUTHOR              => q{Sebastien Aperghis-Tramoni <sebastien@aperghis.net>},
    VERSION_FROM        => 'lib/POE/Component/Client/BigBrother.pm',
    ABSTRACT_FROM       => 'lib/POE/Component/Client/BigBrother.pm',
    PREREQ_PM => {
        # prereqs
        'POE'           => 0,

        # build/test prereqs
        'Test::More'    => 0,
    },
    PL_FILES            => {},
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'POE-Component-Client-BigBrother-*' },
);
