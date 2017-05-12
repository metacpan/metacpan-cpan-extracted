use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Template::Plugin::DumbQuotes',
    AUTHOR              => 'Yann Kerhervé <yannk@cpan.org>',
    VERSION_FROM        => 'lib/Template/Plugin/DumbQuotes.pm',
    ABSTRACT_FROM       => 'lib/Template/Plugin/DumbQuotes.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Template'   => 0,
        'Encode'     => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Template-Plugin-DumbQuotes-*' },
);
