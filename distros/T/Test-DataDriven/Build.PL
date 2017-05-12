#!/usr/bin/perl -w

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new
  ( module_name    => 'Test::DataDriven',
    license        => 'perl',
    requires       => { 'Test::Base'        => 0,
                        'Test::More'        => 0,
                        'Class::Spiffy'     => 0.12,
                        'Test::Differences' => 0,
                        'File::Slurp'       => 0,
                        },
    create_makefile_pl => 'passthrough',
    );
$builder->add_to_cleanup( 't/dummy', '*.data', 't/*.data' );
$builder->create_build_script;
