#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Test::CPAN::Meta::JSON',
    VERSION_FROM        => 'lib/Test/CPAN/Meta/JSON.pm',
    ABSTRACT            => 'Validate your CPAN META.json files',
    NO_META             => 1,
    PREREQ_PM           => {

        # runtime prereqs
        'IO::File'              => '0',
		'JSON'	                => '2.15',
		'Test::Builder'         => '0',

        # build/test prereqs
		'Test::Builder::Tester' => '0',
        'Test::More'            => '0.70'

    }
);
