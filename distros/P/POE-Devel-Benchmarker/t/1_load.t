#!/usr/bin/perl

# Import the stuff
# XXX no idea why this is broken for this particular dist!
#use Test::UseAllModules;
#BEGIN { all_uses_ok(); }

use Test::More tests => 7;
use_ok( 'POE::Devel::Benchmarker' );
use_ok( 'POE::Devel::Benchmarker::SubProcess' );
use_ok( 'POE::Devel::Benchmarker::GetInstalledLoops' );
use_ok( 'POE::Devel::Benchmarker::GetPOEdists' );
use_ok( 'POE::Devel::Benchmarker::Utils' );
use_ok( 'POE::Devel::Benchmarker::Imager' );
use_ok( 'POE::Devel::Benchmarker::Imager::BasicStatistics' );
