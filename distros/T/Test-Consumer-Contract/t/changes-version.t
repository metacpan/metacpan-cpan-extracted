#!/usr/bin/env perl

# The newest entry in Changes and the version every module declares have to be
# the same number.  A release is two edits - the $VERSION in lib/ and a heading
# in Changes - and the heading is the one that gets forgotten, which leaves a
# released version with no note saying what changed in it.  That is the mistake
# this test exists to catch, so it runs as an author test (AUTHOR_TESTING=1),
# before an upload rather than after one.
#
# Neither side is taken on trust.  The heading is parsed out of Changes, and
# each module under lib/ is loaded and asked for its $VERSION, so what is
# compared is the version the module really has rather than a line that looks
# like a version - a commented-out assignment could not pass for one.

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;

use FindBin qw($Bin);
use File::Find;
use File::Spec;
use lib "$Bin/../lib";

my $root    = File::Spec->catdir($Bin, File::Spec->updir);
my $changes = File::Spec->catfile($root, 'Changes');
my $lib     = File::Spec->catdir($root, 'lib');

# The newest entry is the first line of Changes that starts in column 1 with a
# version.  An entry heading is "0.02" or "0.02\t2026-10-16", while the title
# line, the prose between entries and the bullets under a heading either start
# with a word or are indented.
sub _newest_entry
{
	my ($path) = @_;

	open(my $fh, '<', $path) or return;

	while(my $line = <$fh>) {
		next if $line =~ /^\s/;
		return $1 if $line =~ /^v?(\d[\w._]*)/;
	}

	return;
}

# The name a file under lib/ is loaded as: lib/Foo/Bar.pm is Foo::Bar.
sub _module_name
{
	my ($file) = @_;

	my $rel = File::Spec->abs2rel($file, $lib);
	$rel =~ s{\.pm\z}{}xms;

	return join('::', File::Spec->splitdir($rel));
}

# A heading may be written v1.2.3 or 1.2.3, so the number is what is compared
# rather than the spelling of it.
sub _number
{
	my ($version) = @_;

	$version =~ s{^v}{}xms;
	$version =~ s{\s+\z}{}xms;

	return $version;
}

my $newest = _newest_entry($changes);

ok(defined($newest), 'Changes has a version heading')
	or diag("$changes has no line in column 1 that starts with a version");

if(defined($newest)) {
	# find() on a directory that is not there is a bare warning, so the check
	# comes first and the search is skipped when it fails.
	my @files;
	if(ok(-d $lib, "$lib is there to look for modules in")) {
		find({ no_chdir => 1, wanted => sub {
			push @files, $File::Find::name if -f && /\.pm\z/xms;
		} }, $lib);
	}

	ok(scalar(@files), 'there are modules to check')
		or diag("no .pm files under $lib");

	my @checked;
	foreach my $file (sort @files) {
		my $module = _module_name($file);

		my $loaded = eval { require $file; 1 };
		if(!$loaded) {
			fail("$module loads, so that its \$VERSION can be asked for: $@");
			next;
		}

		# A module that declares no $VERSION has nothing to compare: the
		# distribution's version is the one version that has to be in Changes.
		my $version = eval { $module->VERSION };
		next if !defined($version);

		push @checked, $module;
		is(_number($version), _number($newest),
			"$module declares \$VERSION = $version, which Changes' newest entry ($newest) matches");
	}

	if(!@checked) {
		fail("a module declares a \$VERSION to compare with the newest Changes entry ($newest)");
	} else {
		diag("Changes' newest entry is $newest, as declared by " . join(', ', @checked));
	}
}

done_testing();
