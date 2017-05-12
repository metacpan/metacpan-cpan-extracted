use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Perl6::Gather',
    AUTHOR              => 'Damian Conway <DCONWAY@CPAN.org>',
    VERSION_FROM        => 'lib/Perl6/Gather.pm',
    ABSTRACT_FROM       => 'lib/Perl6/Gather.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Perl6::Export' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Perl6-Gather-*' },
);
