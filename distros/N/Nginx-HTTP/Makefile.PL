#!/usr/bin/perl

use ExtUtils::MakeMaker;

WriteMakefile(
    dist => {
        COMPRESS => 'gzip -9v',
        SUFFIX   => '.gz',
    },

    NAME          => 'Nginx::HTTP',
    VERSION_FROM  => 'lib/Nginx/HTTP.pm',
    ABSTRACT_FROM => 'lib/Nginx/HTTP.pm',
    AUTHOR        => 'Alexandr Gomoliako <zzz@zzz.org.ua>',

    PREREQ_PM => {
        'HTTP::Parser2::XS' => 0,
        'Nginx::Perl'       => '1.1.13.1',
    },

    (eval $ExtUtils::MakeMaker::VERSION >= 6.46
         ? ( 'META_MERGE' => { 
                 'no_index' => { 
                     'directory' => ['eg'] 
                 } 
             } ) : ()),

);

