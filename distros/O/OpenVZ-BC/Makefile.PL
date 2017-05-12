use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'OpenVZ::BC',
    AUTHOR              => 'Dusty Wilson <dev+cpan-OpenVZ-BC@megagram.com>',
    VERSION_FROM        => 'lib/OpenVZ/BC.pm',
    ABSTRACT_FROM       => 'lib/OpenVZ/BC.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'OpenVZ-BC-*' },
);
