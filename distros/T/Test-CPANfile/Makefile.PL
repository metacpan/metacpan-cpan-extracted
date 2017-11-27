use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME          => 'Test::CPANfile',
    AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
    VERSION_FROM  => 'lib/Test/CPANfile.pm',
    ABSTRACT_FROM => 'lib/Test/CPANfile.pm',
    LICENSE       => 'perl',
    META_MERGE => {
        resources => {
            repository => '',
        },
    },
);
