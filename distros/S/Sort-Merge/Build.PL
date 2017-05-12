#!/usr/bin/perl
use warnings;
use strict;
use Module::Build;

my $build=Module::Build->new
  (
   module_name => 'Sort::Merge',
   license => 'perl',
   dist_author => 'James Mastros <james@mastros.biz>',
   build_requires => {'Test::More'=>0},
   requires => {},
   create_makefile_pl => 'traditional' # don't require having Module::Build for end-users
  )->create_build_script;
