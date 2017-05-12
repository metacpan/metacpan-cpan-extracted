#!/usr/bin/perl -w

use strict;
use Test::More;
eval "use Test::Pod::Coverage 1.00";
plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage"
  if $@;
plan( tests => 2 );
pod_coverage_ok( 'Test::DataDriven',
                 { coverage_class => 'Pod::Coverage::CountParents',
                   trustme        => [ qw(open close), qw(create) ],
                   } );
pod_coverage_ok( 'Test::DataDriven::Plugin',
                 { coverage_class => 'Pod::Coverage::CountParents',
                   trustme        => [ qw(MODIFY_CODE_ATTRIBUTES), qw(endc) ],
                   } );
