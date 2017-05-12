#!/usr/bin/perl -w

# Compile-testing for Process::YAML

use strict;
use Test::More tests => 2;

ok( $] > 5.005, 'Perl version is 5.005 or newer' );
use_ok( 'Process::YAML' );

