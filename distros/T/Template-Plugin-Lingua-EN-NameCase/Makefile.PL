#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Template::Plugin::Lingua::EN::NameCase',
    VERSION_FROM        => 'lib/Template/Plugin/Lingua/EN/NameCase.pm',
    ABSTRACT            => 'TT2 interface to Lingua::EN::NameCase module',
    NO_META             => 1,
    PREREQ_PM => {

        # prereqs
        'Template'              => '2.07',
        'Template::Plugin'      => '2.07',
        'Template::Stash'       => '2.07',
        'Lingua::EN::NameCase'  => '0',

        # for testing
        'IO::File'              => '0',
        'Template::Test'        => '2.07',
        'Test::More'            => '0.70'

    },
);
