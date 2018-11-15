use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

WriteMakefile(
    NAME          => 'Parse::Distname',
    AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
    VERSION_FROM  => 'lib/Parse/Distname.pm',
    ABSTRACT_FROM => 'lib/Parse/Distname.pm',
    LICENSE       => 'perl',
    test          => {TESTS => 't/*.t t/*/*.t'},
    META_MERGE => {
        resources => {
            repository => 'https://github.com/charsbar/Parse-Distname',
            bugtracker => 'https://github.com/charsbar/Parse-Distname/issues',
        },
    },
);
