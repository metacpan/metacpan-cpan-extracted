use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'String::Blender',
    AUTHOR              => 'Alexey Skorikov <alexey@skorikov.name>',
    LICENSE             => 'perl',
    VERSION_FROM        => 'lib/String/Blender.pm',
    ABSTRACT_FROM       => 'lib/String/Blender.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Moose'      => 0.74,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'String-Blender-*' },
);
