#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Template::Plugin::Lingua::EN::Numbers',
    VERSION_FROM        => 'lib/Template/Plugin/Lingua/EN/Numbers.pm',
    ABSTRACT            => 'TT2 interface to Lingua::EN::Numbers modules',
    NO_META             => 1,
    PREREQ_PM => {

        # prereqs
        'Template'                          => '2.07',
        'Template::Plugin'                  => '2.07',
        'Template::Stash'                   => '2.07',
        'Lingua::EN::Numbers'               => '0',
        'Lingua::EN::Numbers::Years'        => '0',
        'Lingua::EN::Numbers::Ordinate'     => '0',

        # for testing
        'IO::File'                          => '0',
        'Template::Test'                    => '2.07',
        'Test::More'                        => '0.70'

    },
);
