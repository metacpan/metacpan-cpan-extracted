#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'PPIx::LineToSub',
    VERSION_FROM => 'lib/PPIx/LineToSub.pm',
    LICENSE      => 'perl',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    PREREQ_PM    => {
        'Test::More' => '0',
        'PPI'        => '0',
    },
);

