#!/usr/bin/perl

use strict;
use warnings;

use 5.010001;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'PDF::API2::Resource::XObject::Image::Imager',
    VERSION_FROM      => 'lib/PDF/API2/Resource/XObject/Image/Imager.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {
                'Imager' => 1,
                'PDF::API2' => 2,
            },
    TEST_REQUIRES => {
                'FindBin' => 0,
                'File::Spec' => 0,
                'File::Path' => 0,
            }, 
    ABSTRACT_FROM     => 'lib/PDF/API2/Resource/XObject/Image/Imager.pm', # retrieve abstract from module
    AUTHOR            => 'Philip Gwyn <gwyn at cpan.org>',
    LICENSE           => 'perl',
    dist=>{COMPRESS=>'gzip -9f', EXT=>'gz'},
);
