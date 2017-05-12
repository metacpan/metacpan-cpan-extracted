use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Perl6::Export::Attrs',
    AUTHOR              => 'Damian Conway <DCONWAY@cpan.org>',
    VERSION_FROM        => 'lib/Perl6/Export/Attrs.pm',
    ABSTRACT_FROM       => 'lib/Perl6/Export/Attrs.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'          => 0,
        'version'             => 0,
        'Attribute::Handlers' => 0,
        'PadWalker'           => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Perl6-Export-Attrs-*' },
);
