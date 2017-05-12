#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Test::CPAN::Meta',
    VERSION_FROM        => 'lib/Test/CPAN/Meta.pm',
    ABSTRACT            => 'Validate your CPAN META.yml files',
    NO_META             => 1,
    PREREQ_PM           => {

        # runtime prereqs
		'Parse::CPAN::Meta'     => '0.02',
		'Test::Builder'         => '0',

        # build/test prereqs
        'IO::File'              => '0',
		'Test::Builder::Tester' => '0',
        'Test::More'            => '0.70'

    }
);
