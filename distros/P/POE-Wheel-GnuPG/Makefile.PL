use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'POE::Wheel::GnuPG',
    AUTHOR              => 'Damien "dams" Krotkine <dams@cpan.org>',
    VERSION_FROM        => 'lib/POE/Wheel/GnuPG.pm',
    ABSTRACT_FROM       => 'lib/POE/Wheel/GnuPG.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'IO::Handle' => 0,
        'GnuPG::Interface' => 0,
        'parent' => 0,
        'POE' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'POE-Wheel-GnuPG-*' },
);
