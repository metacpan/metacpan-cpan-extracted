#!/usr/bin/perl

# ABSTRACT: Basic tests about the Net::Google::SafeBrowsing4::Storage::File class

use strict;
use warnings;

use Test::More qw(no_plan);

BEGIN {
	use_ok("Net::Google::SafeBrowsing4::Storage::File");
};

require_ok("Net::Google::SafeBrowsing4::Storage::File");

my $storage = Net::Google::SafeBrowsing4::Storage::File->new(path => ".");

$storage->save_lists([
	{
		'threatEntryType' => 'URL',
		'threatType' => 'MALWARE',
		'platformType' => 'ANY_PLATFORM'
	},
	{
		'threatEntryType' => 'URL',
		'threatType' => 'MALWARE',
		'platformType' => 'WINDOWS'
	},
]);

ok(-e "lists.gsb4", "SafeBrowsing4 lists saved.");

my $lists = $storage->get_lists();
is(scalar(@$lists), 2, "2 lists retrieved.");
is($lists->[0]->{threatType}, 'MALWARE', 'Lists saved correctly');


unlink("lists.gsb4");
