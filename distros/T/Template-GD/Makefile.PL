#!/usr/bin/perl -w                                         # -*- perl -*-

use strict;

use ExtUtils::MakeMaker;
    
my %opts = (
    'NAME'         => 'Template::GD',
    'VERSION_FROM' => 'lib/Template/Plugin/GD.pm',
    'PMLIBDIRS'    => [ 'lib' ], 
    'PREREQ_PM'    => { 
        'Template' => 2.14,
        'GD'       => 1.14,
    },
    dist         => {
        PREOP => 'pod2text lib/Template/Plugin/GD.pm > README',
        COMPRESS => 'gzip',
        SUFFIX   => 'gz',
    },
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{ AUTHOR   } = 'Andy Wardley <abw@cpan.org>';
    $opts{ ABSTRACT } = 'GD plugins for the Template Toolkit',
}

WriteMakefile( %opts );

