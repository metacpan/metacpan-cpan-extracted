#!/usr/bin/perl

# ABSTRACT: Basic tests about the Net::Google::SafeBrowsing4 class

use strict;
use warnings;

use HTTP::Message;
use LWP::UserAgent;
use Test::More qw(no_plan);

use Net::Google::SafeBrowsing4::Storage::File;

BEGIN {
	use_ok("Net::Google::SafeBrowsing4");
};

require_ok("Net::Google::SafeBrowsing4");

my $gsb;
# Constructor paramter tests
$gsb = Net::Google::SafeBrowsing4->new();
is($gsb, undef, "SafeBrowsing4 object needs an API key and a Storage object.");

$gsb = Net::Google::SafeBrowsing4->new(
	storage => Net::Google::SafeBrowsing4::Storage::File->new(path => "."),
);
is($gsb, undef, "SafeBrowsing4 object needs an API key.");

$gsb = Net::Google::SafeBrowsing4->new(
		key => "random-api-key-random-api-key-random-ap",
);
is($gsb, undef, "SafeBrowsing4 object needs a Storage object.");

$gsb = Net::Google::SafeBrowsing4->new(
	key => "random-api-key-random-api-key-random-ap",
	storage => Net::Google::SafeBrowsing4::Storage::File->new(path => "."),
	http_agent => undef,
);
is($gsb, undef, "SafeBrowsing4 object cannot work without a http_agent.");

$gsb =  new_ok(
	"Net::Google::SafeBrowsing4" => [
		key => "random-api-key-random-api-key-random-ap",
		storage => Net::Google::SafeBrowsing4::Storage::File->new(path => "."),
	],
	"Net::Google::SafeBrowsing4"
);
can_ok($gsb, qw{
	update
	lookup
	get_lists
});

# Check UserAgent
ok($gsb->{http_agent}, "SafeBrowsing object got an LWP object");

# Using custom UserAgent
my $lwp;
$lwp = LWP::UserAgent->new();
$lwp->timeout(10);
$lwp->default_header("Content-Type" => "text/plain");
$lwp->default_header("Accept-Encoding" => "");
$lwp->local_address("192.160.0.124");
$gsb = Net::Google::SafeBrowsing4->new(
	key => "random-api-key-random-api-key-random-ap",
	storage => Net::Google::SafeBrowsing4::Storage::File->new(path => "."),
	http_agent => $lwp,
);
ok($gsb, "SafeBrowsing4 object accepts http_agent.");
is($gsb->{http_agent}->timeout(), 60, "HTTP timeout value got overridden");
is($gsb->{http_agent}->default_header("Content-Type"), "application/json", "HTTP Content-Type was overridden.");
is($gsb->{http_agent}->default_header("Accept-Encoding"), "" . HTTP::Message->decodable(), "HTTP Accept-Encoding was overridden.");
is($gsb->{http_agent}->local_address(), "192.160.0.124", "LWP Local Address setting kept.");

SKIP: {
	eval {
		use Test::Pod::Coverage;
	};
	if ($@) {
		skip("Test::Pod::Coverage is not installed Pod coverage test skipped.");
	}

    pod_coverage_ok("Net::Google::SafeBrowsing4");
}
