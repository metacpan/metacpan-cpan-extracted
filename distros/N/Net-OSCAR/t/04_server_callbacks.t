#!/usr/bin/perl

# The SNAC handlers are loaded on demand,
# so we test loading them all here.

eval {
	require Test::More;
	Test::More->import();
};
if($@) {
	print "1..0 # Skipped: Couldn't load Test::More\n";
	exit 0;
}

use strict;
use warnings;
use lib "./blib/lib";

sub getfiles {
	my $dir = shift;
	my @ret;

	opendir(DIR, $dir) or die "Couldn't open test directory $dir: $!\n";
	my @files = readdir(DIR);
	closedir(DIR);

	foreach my $file(@files) {
		next if $file eq "." or $file eq "..";

		my $path = "$dir/$file";
		if(-d $path) {
			push @ret, getfiles($path);
		} elsif($path =~ /\.pm$/) {
			push @ret, $path;
		}
	}

	return @ret;
}

my @tests = getfiles("./blib/lib/Net/OSCAR/ServerCallbacks");
plan(tests => scalar(@tests) + 2);

require_ok("Net::OSCAR");
require_ok("Net::OSCAR::Constants");
Net::OSCAR::Constant->import(":all");

foreach my $file(@tests) {
	next if $file eq "." or $file eq "..";
	ok(do($file), "callback load: $file");
	diag($@) if $@;
}

1;
