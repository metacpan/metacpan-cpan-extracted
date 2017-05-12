use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'POE::Component::SASLAuthd',
    AUTHOR              => 'Kirill Miazine <km@krot.org>',
    VERSION_FROM        => 'lib/POE/Component/SASLAuthd.pm',
    ABSTRACT_FROM       => 'lib/POE/Component/SASLAuthd.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'POE::Session' => 0,
        'POE::Wheel::ReadWrite' => 0,
        'POE::Filter::Line' => 0,

    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'POE-Component-SASLAuthd-*' },
);
