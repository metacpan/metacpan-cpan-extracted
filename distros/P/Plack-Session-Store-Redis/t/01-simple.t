#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Plack::Request;
use Plack::Session::State::Cookie;
use Plack::Session::Store::Redis;

use t::lib::TestSessionHash;

my ($conn, $skip);

eval { $conn = Redis->new; };

SKIP: {
	skip "Redis needs to be running for this test.", 1 if $@ or !$conn;

	t::lib::TestSessionHash::run_all_tests(
		store  => Plack::Session::Store::Redis->new(prefix => 'plack_test_sessions'),
		state  => Plack::Session::State->new,
		env_cb => sub {
			open my $in, '<', \do { my $d };
			my $env = {
				'psgi.version'    => [ 1, 0 ],
				'psgi.input'      => $in,
				'psgi.errors'     => *STDERR,
				'psgi.url_scheme' => 'http',
				SERVER_PORT       => 80,
				REQUEST_METHOD    => 'GET',
				QUERY_STRING      => join "&" => map { $_ . "=" . $_[0]->{ $_ } } keys %{$_[0] || +{}},
			};
		},
	);

	# drop the keys
	$conn->del($_) for $conn->keys('plack_test_sessions_*');
}

done_testing;
