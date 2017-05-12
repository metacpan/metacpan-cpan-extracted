#!/usr/bin/perl

use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

WriteMakefile(
    AUTHOR              => 'Barbie <barbie@cpan.org>',
    NAME                => 'Munin::Plugin::ApacheRequest',
    VERSION_FROM        => 'lib/Munin/Plugin/ApacheRequest.pm',
    ABSTRACT            => 'Monitor Apache requests with Munin',
    NO_META             => 1,
    PREREQ_PM           => {

        # build/test prereqs
        'IO::File'          => '0',
        'Test::Trap'        => '0',
        'Test::More'        => '0.70'

    }
);
