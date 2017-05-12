use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SVG::DOM2',
    AUTHOR              => 'Martin Owens <doctormo@cpan.org>',
    VERSION_FROM        => 'lib/SVG/DOM2.pm',
    ABSTRACT_FROM       => 'lib/SVG/DOM2.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SVG-DOM2-*' },
);
