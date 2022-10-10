#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME               => 'Test::CSS',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Test/CSS.pm',
    ABSTRACT_FROM      => 'lib/Test/CSS.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'     => 0,
        'File::ShareDir::Install' => 0,
    },
    BUILD_REQUIRES     => {
        'Test::More'   => 0,
        'Test::Tester' => 0,
    },
    PREREQ_PM => {
        'JSON'          => 0,
        'Test::Builder' => 0,
        'File::Share'   => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Test-CSS-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Test::CSS' => { file => 'lib/Test/CSS.pm', version => '0.09' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Test-CSS.git',
                web  => 'https://github.com/manwar/Test-CSS',
            },
        bugtracker => {
    	web => 'https://github.com/manwar/Test-CSS/issues',
        },
    }})
     : ()
    ),
);

package MY;
use File::ShareDir::Install 'postamble';
