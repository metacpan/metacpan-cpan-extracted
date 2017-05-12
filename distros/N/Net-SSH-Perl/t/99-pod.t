#!perl

## Check our Pod, requires Test::Pod
## Also done if available: Test::Pod::Coverage
## Requires TEST_AUTHOR env

use 5.006;
use strict;
use warnings;
use Test::More;
select(($|=1,select(STDERR),$|=1)[1]);

plan skip_all => 'Test not ready yet.';

if (!$ENV{TEST_AUTHOR}) {
	plan skip_all => 'Set the environment variable TEST_AUTHOR to enable this test';
}

my @files;
open my $fh, '<', 'MANIFEST' or die qq{Could not open the MANIFEST file: $!\n};
while (<$fh>) {
	next unless /(.*\.pm)/;
	push @files, $1;
}
close $fh or die qq{Could not close the MANIFEST file: $!\n};
my $numfiles = @files;

plan tests => 1 + $numfiles;

my $PODVERSION = '0.95';
eval {
	require Test::Pod;
	Test::Pod->import;
};

SKIP: {
	if ($@ or $Test::Pod::VERSION < $PODVERSION) {
		skip ("Test::Pod $PODVERSION is required", $numfiles);
	}
	for (@files) {
		pod_file_ok ($_);
	}
}

## We won't require everyone to have this, so silently move on if not found
my $PODCOVERVERSION = '1.04';
eval {
	require Test::Pod::Coverage;
	Test::Pod::Coverage->import;
};
SKIP: {

	if ($@ or $Test::Pod::Coverage::VERSION < $PODCOVERVERSION) {
		skip ("Test::Pod::Coverage $PODCOVERVERSION is required", 1);
	}

	my $trusted_names  =
		[
		 qr{^VERSION$},
		];

	my $t='Net::SSH::Perl pod coverage okay';
	pod_coverage_ok ('Net::SSH::Perl', {trustme => $trusted_names}, $t);
}
