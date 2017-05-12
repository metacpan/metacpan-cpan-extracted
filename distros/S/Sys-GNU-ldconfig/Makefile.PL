#!/usr/bin/perl

use 5.00405;
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Sys::GNU::ldconfig',
    VERSION_FROM      => 'lib/Sys/GNU/ldconfig.pm', # finds $VERSION
    'LICENSE'       => 'perl',

    PREREQ_PM         => {
        'Test::More'  => 0.98, 
        'File::Spec'  => 3.33,
        'File::Slurp' => 9999.13,
        'File::Glob'  => 1.05,
        'Carp'        => 1.26
    },

    dist=>{COMPRESS=>'gzip -9f', EXT=>'gz'},

    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Sys/GNU/ldconfig.pm', # retrieve abstract from module
       AUTHOR         => 'Philip Gwyn <fil@localdomain>') : ()),
);
