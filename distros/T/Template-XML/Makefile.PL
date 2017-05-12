#!/usr/bin/perl -w                                         # -*- perl -*-

use strict;

use ExtUtils::MakeMaker;
    
my %opts = (
    'NAME'         => 'Template::XML',
    'VERSION_FROM' => 'lib/Template/Plugin/XML.pm',
    'PMLIBDIRS'    => [ 'lib' ], 
    'PREREQ_PM'    => { 
        'Template'    => 2.15,
        'XML::Parser' => 2.19,
        'XML::DOM'    => 1.27,
        'XML::RSS'    => 0.9,
        'XML::XPath'  => 1.0,
        'XML::Simple' => 2.0,
    },
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{ AUTHOR   } = 'Andy Wardley <abw@cpan.org>';
    $opts{ ABSTRACT } = 'XML plugins for the Template Toolkit',
}

WriteMakefile( %opts );

