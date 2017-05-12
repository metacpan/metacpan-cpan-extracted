use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Perl6::Form',
    AUTHOR              => 'Damian Conway <DCONWAY@CPAN.org>',
    VERSION_FROM        => 'lib/Perl6/Form.pm',
    ABSTRACT_FROM       => 'lib/Perl6/Form.pm',
    MIN_PERL_VERSION    => 5.008001,
    PL_FILES            => {},
    PREREQ_PM => {
        'Perl6::Export' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Perl6-Form-*' },
);
