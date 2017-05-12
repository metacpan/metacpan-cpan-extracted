#!/usr/bin/perl -w                                         # -*- perl -*-

use strict;

use lib qw( ./lib );
use Config;
use File::Spec::Functions qw( catfile );
use ExtUtils::MakeMaker;
use Cwd;

select STDERR;
$| = 1;
select STDOUT;

our $QUIET  = 0;
our $ACCEPT = 0;
our $WIN32  = ($^O eq 'MSWin32');

my %opts = (
    'NAME'	       => 'Template-Plugin-Latex',
    'VERSION_FROM' => 'lib/Template/Plugin/Latex.pm',
    'PMLIBDIRS'    => [ 'lib' ], 
    'PREREQ_PM'    => { 
        'Template'      => 2.16,
	'LaTeX::Driver' => 0.07,
	'LaTeX::Encode' => 0.02,
	'LaTeX::Table'  => 0,
    },
    'dist'         => {
        'COMPRESS' => 'gzip',
        'SUFFIX'   => 'gz',
    },
    'clean'        => {
        'FILES'    => join(' ', qw( t/output/test1.pdf 
                                    t/output/test1.ps 
                                    t/output/test1.dvi
                                    t/output/test2 
                                    t/output/test2.pdf 
                                    t/output/test2.ps 
                                    t/output/test2.dvi )),
    },
);

if ($ExtUtils::MakeMaker::VERSION >= 5.43) {
    $opts{ AUTHOR   } = 'Andrew Ford <a.ford@ford-mason.co.uk>';
    $opts{ ABSTRACT } = 'Latex support for the Template Toolkit',
}

WriteMakefile(%opts);

