# -*- cperl; cperl-indent-level: 4 -*-
use strict;
use warnings;
use 5.014000;
use Module::Build;

our $VERSION = v1.1.6;

Module::Build->new(
    'module_name' => 'TeX::Hyphen::Pattern',
    'license'     => 'perl',
    'dist_author' => 'Roland van Ipenburg <roland@rolandvanipenburg.com>',
    'requires'    => {
        'Encode'            => 0,
        'File::Temp'        => 0,
        'Log::Log4perl'     => 0,
        'Module::Pluggable' => 0,
        'Moose'             => 0,
        'Readonly'          => 1.03,
        'Set::Scalar'       => 0,
        'perl'              => '5.14.0',
        'strict'            => 0,
        'utf8'              => 0,
        'warnings'          => 0,
    },
    'configure_requires' => {
        'Module::Build' => 0,
    },
    'build_requires' => { 'Module::Build' => 0, },
    'test_requires'  => {
        'TeX::Hyphen'        => 0,
        'Test::More'         => 0.86,
        'Test::NoWarnings'   => 0,
        'Test::Warn'         => 0,
        'Test::TestCoverage' => 0,
    },
    'recommends' => {
        'Module::Signature' => 0,
        'TeX::Hyphen'       => 0,
    },
    'meta_merge' => {
        'resources' => {
            'repository' =>
              'https://bitbucket.org/rolandvanipenburg/tex-hyphen-pattern',
            'bugtracker' =>
'https://bitbucket.org/rolandvanipenburg/tex-hyphen-pattern/issues',
        },
    },
    'sign' => 1,
)->create_build_script;
