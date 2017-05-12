#! /usr/bin/perl

# Module build script creator

use Module::Build;
use strict;
use warnings;
use 5.6.0;

my $build = new Module::Build
    module_name => 'Object::Factory::Declarative',
    license     => 'perl',
    dist_author => 'Jim Schneider <perl@jrcsdevelopment.com>',
;

$build->create_build_script;
