#!/usr/bin/env perl

use inc::Module::Install 0.75;

use strict;
use warnings;

name           'MooseX-Method';
all_from       'lib/MooseX/Method.pm';

requires       'Moose' => '0.22';
requires       'Class::MOP' => '0.37';
requires       'Carp' => '0';
requires       'HTML::Template::Pro' => '0.65';
requires       'Scalar::Util' => '1.14';
requires       'Sub::Name' => '0.02';

build_requires 'Test::More' => '0.47';
build_requires 'Test::Exception' => '0.21';
build_requires 'Test::Pod' => '1.26';

auto_install;
WriteAll;

