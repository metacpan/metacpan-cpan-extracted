#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'PPIx::IndexOffsets',
    VERSION_FROM => 'lib/PPIx/IndexOffsets.pm',
    LICENSE      => 'perl',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    PREREQ_PM    => {
        'Test::More' => '0',
        'PPI'        => '0',
    },
);

