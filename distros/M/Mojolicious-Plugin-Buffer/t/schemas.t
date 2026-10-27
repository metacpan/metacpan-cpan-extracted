use strict;
use warnings;

use File::Find;
use File::Spec;
use File::Temp qw(tempdir);
use Test::More;

# Author test: the API SPECIFICATION blocks must stay readable by
# extract-schemas (from App::Test::Generator) in its strictest mode, so a
# POD edit cannot silently break the schemas that tools generate tests from
my ($script) = grep { -x }
	map { File::Spec->catfile($_, 'extract-schemas') }
	File::Spec->path();
plan skip_all => 'extract-schemas (App::Test::Generator) is not installed' unless $script;

my @modules;
find(sub { push @modules, $File::Find::name if /\.pm\z/ }, 'lib');
plan skip_all => 'no modules found under lib' unless @modules;

for my $module (sort @modules) {
	# Write the schemas somewhere disposable; only the exit status matters
	my $out = tempdir(CLEANUP => 1);
	my $output = qx{"$^X" "$script" --strict-pod=fatal --output-dir "$out" "$module" 2>&1};
	is($? >> 8, 0, "$module passes extract-schemas --strict-pod=fatal")
		or diag($output);
}

done_testing();
