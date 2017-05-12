use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Template::Plugin::Handy',
    AUTHOR              => 'Peter Karman <karman@cpan.org>',
    VERSION_FROM        => 'lib/Template/Plugin/Handy.pm',
    ABSTRACT_FROM       => 'lib/Template/Plugin/Handy.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Data::Dump' => 0,
        'JSON::XS'   => 0,
        'Template::Plugin::VMethods' => 0,

    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Template-Plugin-Handy-*' },
);
