#!perl
use 5.006;
use strict;
use warnings;
use Test2::V0;

plan tests => 1;

use ok 'PDL::Opt::GLPK' || print "Bail out!\n";

diag( "Testing PDL::Opt::GLPK $PDL::Opt::GLPK::VERSION, Perl $], $^X" );
