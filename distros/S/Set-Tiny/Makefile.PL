#!/usr/bin/perl
use strict;

use ExtUtils::MakeMaker;
WriteMakefile(
    NAME => 'Set::Tiny',
    ABSTRACT_FROM => 'lib/Set/Tiny.pm',
    VERSION_FROM => 'lib/Set/Tiny.pm',
    AUTHOR => 'Stanis Trendelenburg <trendels@cpan.org>',
    LICENSE => 'perl',
    PREREQ_PM => {
        'Test::More' => 0,
    },
);

