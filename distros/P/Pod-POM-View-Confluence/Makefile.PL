use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Pod::POM::View::Confluence',
    AUTHOR              => 'Philippe Bruhat (BooK) <book@cpan.org>',
    VERSION_FROM        => 'lib/Pod/POM/View/Confluence.pm',
    ABSTRACT_FROM       => 'lib/Pod/POM/View/Confluence.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Pod::POM'   => 0.17,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Pod-POM-View-Confluence-*' },
);
