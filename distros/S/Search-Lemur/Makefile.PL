use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Search::Lemur',
    AUTHOR              => 'Patrick Kaeding <pkaeding@cpan.org>',
    VERSION_FROM        => 'lib/Search/Lemur.pm',
    ABSTRACT            => 'A module to parse the output from a Lemur server',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Simple' => 0,
        'LWP' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Search-Lemur-*' },
);
