use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME          => 'Parse::LocalDistribution',
    AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
    VERSION_FROM  => 'lib/Parse/LocalDistribution.pm',
    ABSTRACT_FROM => 'lib/Parse/LocalDistribution.pm',
    LICENSE       => 'perl',
    META_MERGE => {
        resources => {
            repository => 'https://github.com/charsbar/Parse-LocalDistribution',
        },
    },
);
