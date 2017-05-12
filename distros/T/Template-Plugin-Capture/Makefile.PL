use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Template::Plugin::Capture',
    AUTHOR              => 'Jiro Nishiguchi <jiro@cpan.org>',
    VERSION_FROM        => 'lib/Template/Plugin/Capture.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' =>  0.32,
        'Template'   =>  2.07,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Template-Plugin-Capture-*' },
);
