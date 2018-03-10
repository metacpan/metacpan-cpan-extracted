#!/usr/bin/perl

# ABSTRACT: Lookup URI (suffix/prefix expression) extraction tests for Net::Google::SafeBrowsing4::URI class

use strict;
use warnings;

use Test::More qw(no_plan);

use Net::Google::SafeBrowsing4::URI;


my %uris = (
	'http://www1.rapidsoftclearon.net/' =>  { map { $_ => 1 } qw(
		www1.rapidsoftclearon.net/
		rapidsoftclearon.net/
	)},
	'www.google.com' =>  { map { $_ => 1 } qw(
		www.google.com/
		google.com/
	)},
	'google.com' =>  { map { $_ => 1 } qw(
		google.com/
	)},
	'malware.testing.google.test' =>  { map { $_ => 1 } qw(
		malware.testing.google.test/
		testing.google.test/
		google.test/
	)},
	'google.test/first/second/third/fourth/fifth/sixth' =>  { map { $_ => 1 } qw(
		google.test/first/second/third/fourth/fifth/sixth
		google.test/first/second/third/
		google.test/first/second/
		google.test/first/
		google.test/
	)},
	'http://www.domain.com?source=3Demail' =>  { map { $_ => 1 } qw(
		www.domain.com/?source=3Demail
		www.domain.com/
		domain.com/?source=3Demail
		domain.com/
	)},
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
