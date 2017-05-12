#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'MouseX::Params::Validate',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/MouseX/Params/Validate.pm',
    ABSTRACT_FROM      => 'lib/MouseX/Params/Validate.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Carp'             => '0',
        'Devel::Caller'    => '0',
        'Mouse'            => '0.93',
        'Params::Validate' => '0.88',
        'Scalar::Util'     => '0',
        'Sub::Exporter'    => '0'
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'MouseX-Params-Validate-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => { 'MouseX::Params::Validate' => { file => 'lib/MouseX/Params/Validate.pm', version => '0.10' } },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/MouseX-Params-Validate.git',
                web  => 'https://github.com/manwar/MouseX-Params-Validate',
            },
        }})
     : ()
    ),
);
