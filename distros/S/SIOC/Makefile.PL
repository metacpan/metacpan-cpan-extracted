use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'SIOC',
    AUTHOR              => 'Jochen Lillich <geewiz@cpan.org>',
    VERSION_FROM        => 'lib/SIOC.pm',
    ABSTRACT_FROM       => 'lib/SIOC.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Moose' => 0,
        'MooseX::AttributeHelpers' => 0,
        'Template' => 0,
        'Template::Provider::FromDATA' => 0,
        'version' => 0,
        'Readonly' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'SIOC-*' },
);
