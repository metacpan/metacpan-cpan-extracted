#!/usr/bin/perl

# ABSTRACT: Lookup URI (suffix/prefix expression) extraction tests for Net::Google::SafeBrowsing4::URI class listed on Google's API webpage
# See: https://developers.google.com/safe-browsing/v4/urls-hashing#suffixprefix-expressions

use strict;
use warnings;

use Test::More qw(no_plan);

use Net::Google::SafeBrowsing4::URI;


# URI suffix/prefix expressions extraction tests from Google's API webpage:
# https://developers.google.com/safe-browsing/v4/urls-hashing#suffixprefix-expressions
my %uris = (
	'http://a.b.c/1/2.html?param=1' => { map { $_ => 1 } qw(
		a.b.c/1/2.html?param=1
		a.b.c/1/2.html
		a.b.c/
		a.b.c/1/
		b.c/1/2.html?param=1
		b.c/1/2.html
		b.c/
		b.c/1/
	)},
	'http://a.b.c.d.e.f.g/1.html' => { map { $_ => 1 } qw(
		a.b.c.d.e.f.g/1.html
		a.b.c.d.e.f.g/
		c.d.e.f.g/1.html
		c.d.e.f.g/
		d.e.f.g/1.html
		d.e.f.g/
		e.f.g/1.html
		e.f.g/
		f.g/1.html
		f.g/
	)},
	'http://1.2.3.4/1/' => { map { $_ => 1 } qw(
		1.2.3.4/1/
		1.2.3.4/
	)}
);

foreach my $uri (keys(%uris)) {
	note("Checking uri: " . $uri . "\n");
	my $gsb_uri = Net::Google::SafeBrowsing4::URI->new($uri);
	my @lookups = $gsb_uri->generate_lookupuris();
	is(scalar(@lookups), scalar(keys(%{$uris{$uri}})), "Number of possible prefix/suffix uris for '". $uri ."'");
	foreach my $lookupuri (@lookups) {
		my $expression = $lookupuri->as_string();
		$expression =~ s/^https?:\/\///i;
		ok(exists($uris{$uri}->{$expression}), "prefix/suffix uri '". $expression ."' found");
		delete($uris{$uri}->{$expression});
	}
	is(scalar(keys(%{$uris{$uri}})), 0, "All prefix/suffix uris found");
}
