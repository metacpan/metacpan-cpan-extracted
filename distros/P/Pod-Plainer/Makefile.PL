use 5.006;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Pod::Plainer',
    VERSION_FROM  => 'Plainer.pm',
    ABSTRACT_FROM => 'Plainer.pm',
    AUTHOR        => 'Robin Barker <rmbarker@cpan.org>',

    INSTALLDIRS   => ($] < 5.011 ? 'perl' : 'site'),
    LICENSE       => 'perl',
    MIN_PERL_VERSION => '5.6.0',
    PREREQ_PM     => { 'Pod::Parser' => 0 },
);

