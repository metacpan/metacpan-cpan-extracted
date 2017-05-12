#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR          => 'Barbie <barbie@cpan.org>',
    NAME            => 'Template::Plugin::MultiMarkdown',
    VERSION_FROM    => 'lib/Template/Plugin/MultiMarkdown.pm',
    ABSTRACT        => 'TT plugin for Text::MultiMarkdown',
    NO_META         => 1,
    PREREQ_PM => {

        # prereqs
        'parent'                    => '0',
        'Template'                  => '2.16',
        'Template::Plugin::Filter'  => '1.38',
	    'Text::MultiMarkdown'       => '1.000035',

        # for testing
        'FindBin'                   => 0,
        'IO::File'                  => 0,
        'Test::More'                => 0.70

    },
);
