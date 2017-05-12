#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Template::Plugin::WikiFormat',
    VERSION_FROM        => 'lib/Template/Plugin/WikiFormat.pm',
    ABSTRACT            => 'TT wrapper for Text::WikiFormat',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
        'Template'	                => '2',
        'Template::Plugin::Filter'  => '2',
        'Text::WikiFormat'          => '0.75',

        # build/test prereqs
        'IO::File'                  => '0',
        'Template::Test'            => '2',
        'Test::More'                => '0.70'

    }
);
