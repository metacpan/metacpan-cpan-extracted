#!/usr/bin/perl

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More;
use Module::Install::Metadata;

eval {
	require Software::License;
	require Module::Find;
};
plan skip_all => "requires Software::License and Module::Find" if $@;

my @licenses = Module::Find::findsubmod('Software::License');

plan tests => 1 * @licenses;

foreach my $license (@licenses) {
SKIP: {
		local $@;
		eval "require $license";
		if ($@) {
			skip "Can't load $license: $@", 1;
			next;
		}

		my $name = $license->name;
		my $meta = $license->meta_name;

		unless ($meta) {
			skip "$license has no meta_name", 1;
			next;
		}
		$meta =~ s/_\d+$//;

		my $got = Module::Install::Metadata::__extract_license($name);
		ok $got =~ /^$meta/, $name;

		# should also test license urls?
		my $url = $license->url;
	}
}
