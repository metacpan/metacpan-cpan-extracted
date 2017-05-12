#!/usr/bin/perl

use File::Spec;
use FindBin;
use Test::BDD::Cucumber::Harness::TestBuilder;
use Test::BDD::Cucumber::Loader;
use Test::More;

my $feature_dir = File::Spec->catdir($FindBin::Bin, ("..") x 3);
my ($executor, @features) = Test::BDD::Cucumber::Loader->load($feature_dir);
diag("No feature files found") unless @features;

my $count_tests = 0;
foreach my $feature (@features) {
	foreach my $scenario (@{$feature->scenarios}) {
		$count_tests += scalar(@{$scenario->steps});
	}
}

plan tests => $count_tests;
my $harness = Test::BDD::Cucumber::Harness::TestBuilder->new();
$executor->execute($_, $harness) for @features;
done_testing();

