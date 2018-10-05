use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Perl6::Controls',
    AUTHOR              => 'Damian Conway <DCONWAY@CPAN.org>',
    VERSION_FROM        => 'lib/Perl6/Controls.pm',
    ABSTRACT_FROM       => 'lib/Perl6/Controls.pm',
    PL_FILES            => {},
    LICENSE             => 'artistic2',
    MIN_PERL_VERSION    => 5.010,
    PREREQ_PM => {
        'Test::More'       => 0,
        'Keyword::Declare' => '0.001',
        'Scope::Upper'     => 0,
        'experimentals'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Perl6-Controls-*' },
);
