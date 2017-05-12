use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Template::Plugin::SortNatural',
    AUTHOR              => 'Alexander Wirt <formorer@formorer.de>',
    VERSION_FROM        => 'lib/Template/Plugin/SortNatural.pm',
    ABSTRACT_FROM       => 'lib/Template/Plugin/SortNatural.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Template::Plugin::VMethods' => 0,

    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Template-Plugin-SortNatural-*' },
);
