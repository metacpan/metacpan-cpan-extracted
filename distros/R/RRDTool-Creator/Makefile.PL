use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'RRDTool::Creator',
    AUTHOR              => 'Jacquelin Charbonnel <jacquelin.charbonnel at math.cnrs.fr>',
    VERSION_FROM        => 'lib/RRDTool/Creator.pm',
    ABSTRACT_FROM       => 'lib/RRDTool/Creator.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'RRDTool::OO' => 0.17
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'RRDTool-Creator-*' },
);
