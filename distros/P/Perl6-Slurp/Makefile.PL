use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Perl6::Slurp',
    AUTHOR        => 'Damian Conway <DCONWAY@CPAN.org>',
    VERSION_FROM  => 'lib/Perl6/Slurp.pm',
    ABSTRACT_FROM => 'lib/Perl6/Slurp.pm',
    PL_FILES      => {},
    PREREQ_PM     => {},
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => 'Perl6-Slurp-*' },
);
