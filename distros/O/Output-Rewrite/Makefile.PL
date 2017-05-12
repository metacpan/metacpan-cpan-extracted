use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Output::Rewrite',
    AUTHOR              => 'Hogeist <mahito@cpan.org>',
    VERSION_FROM        => 'lib/Output/Rewrite.pm',
    ABSTRACT_FROM       => 'lib/Output/Rewrite.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Output-Rewrite-*' },
);
