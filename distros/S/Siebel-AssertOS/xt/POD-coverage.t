use warnings;
use strict;
use Test::Pod::Coverage tests => 2;

for my $module(qw(Siebel::AssertOS Siebel::AssertOS::Validate)) {
	pod_coverage_ok($module, "$module is POD covered");
}

