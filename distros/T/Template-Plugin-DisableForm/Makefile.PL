use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Template::Plugin::DisableForm',
    AUTHOR              => 'Naoya Ito <naoya@bloghackers.net>',
    VERSION_FROM        => 'lib/Template/Plugin/DisableForm.pm',
    ABSTRACT_FROM       => 'lib/Template/Plugin/DisableForm.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Template' => 0,
        'Template::Plugin::Filter' => 0,
        'HTML::DisableForm' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Template-Plugin-DisableForm-*' },
);
