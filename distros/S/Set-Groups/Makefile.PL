use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Set::Groups',
    AUTHOR              => 'Jacquelin Charbonnel <jacquelin.charbonnel at math.cnrs.fr>',
    VERSION_FROM        => 'lib/Set/Groups.pm',
    ABSTRACT_FROM       => 'lib/Set/Groups.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Set-Groups-*' },
);
