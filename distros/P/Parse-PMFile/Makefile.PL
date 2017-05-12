use strict;
use warnings;
use ExtUtils::MakeMaker::CPANfile;

my %params = (
    NAME          => 'Parse::PMFile',
    AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
    VERSION_FROM  => 'lib/Parse/PMFile.pm',
    ABSTRACT_FROM => 'lib/Parse/PMFile.pm',
    LICENSE       => 'perl',
    META_MERGE => {
        resources => {
            repository => 'https://github.com/charsbar/Parse-PMFile',
        },
    },
);

WriteMakefile(%params);
