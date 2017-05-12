use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'NCBIx::eUtils::GeneAliases',
    AUTHOR              => 'Roger A Hall <rogerhall@cpan.org>',
    VERSION_FROM        => 'lib/NCBIx/eUtils/GeneAliases.pm',
    ABSTRACT_FROM       => 'lib/NCBIx/eUtils/GeneAliases.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'version'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'NCBIx-eUtils-GeneAliases-*' },
);
