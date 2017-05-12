#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Regexp::Log::Common',
    VERSION_FROM        => 'lib/Regexp/Log/Common.pm',
    ABSTRACT_FROM       => 'lib/Regexp/Log/Common.pm',
    NO_META             => 1,
    PREREQ_PM           => {

        # prereqs
		'Regexp::Log'       => 0,

        # build/test prereqs
        'IO::File'          => '0',
        'Test::More'        => '0.70'

    }
);
