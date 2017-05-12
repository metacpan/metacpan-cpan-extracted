use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Template::Plugin::JapanesePrefectures',
    AUTHOR              => 'Atsushi Kobayashi <nekokak@gmail.com>',
    VERSION_FROM        => 'lib/Template/Plugin/JapanesePrefectures.pm',
    ABSTRACT_FROM       => 'lib/Template/Plugin/JapanesePrefectures.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Template::Pluign' => 0,
        'Geography::JapanesePrefectures::Walker' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Template-Plugin-JapanesePrefectures-*' },
);
