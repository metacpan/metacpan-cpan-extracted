#!/usr/bin/perl
 
BEGIN {
  require './t/test-config.pl';
  if (!$RunDeveloperTests) {
    print "1..0 # Skipped: Developer tests are not enabled";
  
    exit;
  }   
};


use strict;
use warnings;
use Devel::Cover;
use Test::More;

# This will find step definitions and feature files in the directory you point
# it at below
use Test::BDD::Cucumber::Loader;
 
# This harness prints out nice TAP
use Test::BDD::Cucumber::Harness::TestBuilder;
 
# Load a directory with Cucumber files in it. It will recursively execute any
# file matching .*_steps.pl as a Step file, and .*\.feature as a feature file.
# The features are returned in @features, and the executor is created with the
# step definitions loaded.
my ( $executor, @features ) = Test::BDD::Cucumber::Loader->load(
       't/features/' );
 
# Create a Harness to execute against. TestBuilder harness prints TAP
my $harness = Test::BDD::Cucumber::Harness::TestBuilder->new({});
 
# For each feature found, execute it, using the Harness to print results
$executor->execute( $_, $harness ) for @features;
done_testing();
