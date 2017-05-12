use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => '[%main_module%]',
    AUTHOR              => '[% self.author %] <[% self.email %]>',
    VERSION_FROM        => '[%main_pm_file%]',
    ABSTRACT_FROM       => '[%main_pm_file%]',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => '[%self.distro%]-*' },
);
