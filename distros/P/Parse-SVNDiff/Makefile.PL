#!/usr/bin/perl

use strict;
use inc::Module::Install;

name            'Parse-SVNDiff';
all_from        'lib/Parse/SVNDiff.pm';

requires        'Data::Lazy'     => 0.06;
requires        'Class::Tangram' => 1.54;
auto_install;

build_requires  'Test::Base';
auto_include_deps;

sign; WriteAll;
