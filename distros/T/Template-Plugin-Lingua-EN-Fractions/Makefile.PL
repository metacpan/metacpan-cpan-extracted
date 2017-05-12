#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Template::Plugin::Lingua::EN::Fractions',
    VERSION_FROM        => 'lib/Template/Plugin/Lingua/EN/Fractions.pm',
    ABSTRACT            => 'TT2 interface to Lingua::EN::Fractions module',
    NO_META             => 1,
    PREREQ_PM => {

        # prereqs
        'Template'                          => '2.07',
        'Template::Plugin'                  => '2.07',
        'Template::Stash'                   => '2.07',
        'Lingua::EN::Fractions'             => '0',

        # for testing
        'IO::File'                          => '0',
        'Template::Test'                    => '2.07',
        'Test::More'                        => '0.70'

    },
);
