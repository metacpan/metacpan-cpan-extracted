#!/usr/bin/env perl

use ExtUtils::MakeMaker;

WriteMakefile(
    ABSTRACT_FROM => 'lib/Path/Hilbert.pm',
    AUTHOR => '"PWBENNETT" <paul.w.bennett@gmail.com>',
    MIN_PERL_VERSION => 5.012000,
    NAME => 'Path::Hilbert',
    PREREQ_PM => { 'Carp' => 0, 'integer' => 0, 'Math::BigInt' => 0, 'utf8' => 0 },
    PRINT_PREREQ => 1,
    TEST_REQUIRES => { 'Test::Simple' => 0, },
    VERSION_FROM => 'lib/Path/Hilbert.pm',
    LICENSE => 'lgpl',
);
