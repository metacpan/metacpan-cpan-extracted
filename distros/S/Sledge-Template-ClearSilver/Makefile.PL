use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Sledge::Template::ClearSilver',
    AUTHOR        => 'Jiro Nishiguchi <jiro@cpan.org>',
    VERSION_FROM  => 'lib/Sledge/Template/ClearSilver.pm',
    PL_FILES      => {},
    PREREQ_PM => {
        'Test::More'   => 0.32,
        'ClearSilver'  => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Sledge-Template-ClearSilver-*' },
);
