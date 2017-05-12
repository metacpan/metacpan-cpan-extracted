#!/usr/bin/perl -w                                         # -*- perl -*-

use strict;
use warnings;
use ExtUtils::MakeMaker;

my %opts = (
    'NAME'         => 'Template::Plugin::Autoformat',
    'VERSION_FROM' => 'lib/Template/Plugin/Autoformat.pm',
    'PMLIBDIRS'    => ['lib'],
    'PREREQ_PM'    => {
        'Template'         => 2.20,
        'Text::Autoformat' => 1.13,
    },
    'dist' => {
        'COMPRESS' => 'gzip',
        'SUFFIX'   => 'gz',
    },
    'clean' => { FILES   => 'Template-Plugin-Autoformat-*tar.gz' },
);

if ( $ExtUtils::MakeMaker::VERSION >= 5.43 ) {
    $opts{AUTHOR}   = 'Andy Wardley <abw@wardley.org>';
    $opts{ABSTRACT} = 'TT plugin for Text::Autoformat',;
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.30_00' ) {
    $opts{'LICENSE'} = 'perl';
}

if ( $ExtUtils::MakeMaker::VERSION ge '6.44' ) {
    $opts{'META_MERGE'} = {
        resources => {
            license => 'http://dev.perl.org/licenses/',
            homepage =>
                'https://github.com/karpet/template-plugin-autoformat',
            bugtracker =>
                'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Plugin-Autoformat',
            repository =>
                'https://github.com/karpet/template-plugin-autoformat',
        },
    };
}

if (  $ExtUtils::MakeMaker::VERSION ge '6.48' ) {
    $opts{'MIN_PERL_VERSION'} = '5.6.0';
}


WriteMakefile(%opts);
