#!/usr/bin/perl

# ABSTRACT: Threat List management function tests for the Net::Google::SafeBrowsing4 class

use strict;
use warnings;

use HTTP::Response;
use JSON::XS;
use Test::LWP::UserAgent;
use Test::More qw(no_plan);

use Net::Google::SafeBrowsing4;
use Net::Google::SafeBrowsing4::Storage::File;


sub prepare_test {
	my $content = shift;

	my $lwp = Test::LWP::UserAgent->new();
	my $gsb = Net::Google::SafeBrowsing4->new(
		key => "random-api-key-random-api-key-random-ap",
		storage => Net::Google::SafeBrowsing4::Storage::File->new(path => "."),
		http_agent => $lwp,
	);

	if (defined($content)) {
		$gsb->{http_agent}->map_response(
			qr{\/threatLists\?key=},
			HTTP::Response->new(
				200,
				'OK',
				[ "Content-Type" => "application/json" ],
				$content
			),
		);
	}

	return $gsb;
}

# Fake agent test
my $gsb;
$gsb = prepare_test();
ok($gsb, "SafeBrowsing4 object accepts fake http_agent.");

# "cannot connect" test (408 Timeout)
my $lists;
$gsb = prepare_test();
$gsb->{http_agent}->map_response(
	qr{\/threatLists\?key=},
	HTTP::Response->new(408),
);
$lists = $gsb->get_lists();
is($lists, undef, "get_lists: Returns undef on HTTP 408 error");
like($gsb->{last_error}, qr{^get_lists: 408}, "get_lists 408 error string set.");
$gsb->{http_agent}->unmap_all();

# empty string response
my $content = '';
$gsb = prepare_test($content);
$lists = $gsb->get_lists();
is($lists, undef, "get_lists: Returns undef on broken (empty) JSON response");
like($gsb->{last_error}, qr{^get_lists: Invalid response}i, "get_lists invalid response error string set.");

# broken JSON reponse (missing ending)
$content = '{"threatLists": [{"threatType":"MALWARE","threatEntryType":"URL","platformType":"ANY_PLATFORM"';
$gsb = prepare_test($content);
$lists = $gsb->get_lists();
is($lists, undef, "get_lists: Returns undef on broken JSON response");
like($gsb->{last_error}, qr{^get_lists: Invalid response}i, "get_lists invalid response error string set.");

# broken JSON reponse (array instead of a hash)
my $data;
$data = [
	{
		threatEntryType	=> 'URL',
		threatType		=> 'MALWARE',
		platformType	=> 'ANY_PLATFORM'
	}
];
$gsb = prepare_test(encode_json($data));
$lists = $gsb->get_lists();
is($lists, undef, "get_lists: Returns undef on bad JSON response (array)");
like($gsb->{last_error}, qr{^get_lists: Invalid response}i, "get_lists invalid response error string set.");

# JSON with wrong object
$data = {
	badData => [
		{
			threatEntryType	=> 'URL',
			threatType		=> 'MALWARE',
			platformType	=> 'ANY_PLATFORM'
		}
	]
};
$gsb = prepare_test(encode_json($data));
$lists = $gsb->get_lists();
is($lists, undef, "get_lists: Returns undef on broken JSON response (missing key)");
like($gsb->{last_error}, qr{^get_lists: Invalid response}i, "get_lists invalid response error string set.");

# Correct JSON
$data = {
	threatLists => [
		{
			threatEntryType	=> 'URL',
			threatType		=> 'MALWARE',
			platformType	=> 'ANY_PLATFORM'
		}
	]
};
$gsb = prepare_test(encode_json($data));
$lists = $gsb->get_lists();
ok($lists, "get_lists: returned a not-null value");
is(ref($lists), 'ARRAY', "get_lists: returned an array reference");
is(scalar(@$lists), 1, "get_lists: returned an array with 1 element");
is(scalar(keys(%{$lists->[0]})), 3, "get_lists: list entry has 3 properties");
is($lists->[0]->{threatEntryType}, $data->{threatLists}->[0]->{threatEntryType}, "get_lists: list entry has correct threatEntryType");
is($lists->[0]->{threatType}, $data->{threatLists}->[0]->{threatType}, "get_lists: list entry has correct threatType");
is($lists->[0]->{platformType}, $data->{threatLists}->[0]->{platformType}, "get_lists: list entry has correct platformType");
