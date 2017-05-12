#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Term::ProgressBar::Quiet',
    VERSION_FROM => 'lib/Term/ProgressBar/Quiet.pm',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    LICENSE      => 'perl',
    PREREQ_PM    => {
        'Term::ProgressBar'      => '0',
        'IO::Interactive'        => '0',
        'Test::MockObject'       => '0', 
        'Test::More'             => '0',
    }
);

