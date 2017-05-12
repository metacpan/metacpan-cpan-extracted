#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Template::Plugin::Class',
    'VERSION_FROM' => 'lib/Template/Plugin/Class.pm',
    'PREREQ_PM'    => {
        'Test::More' => 0,
        'Template'   => 0,
    }
);
