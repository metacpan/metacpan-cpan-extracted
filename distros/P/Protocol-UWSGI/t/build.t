use strict;
use warnings;

use Test::More;
use Protocol::UWSGI qw(:all);
use Test::HexString;

plan tests => 24;

{ # try a simple request first as a sanity check
	is_hexstr(build_request(
		uri => 'http://localhost/index.html',
		method => 'GET',
		remote => '1.2.3.4:2000',
	), "\x05\x91\x00\x00\x09\x00\x48\x54\x54\x50\x5f\x48\x4f\x53\x54\x09\x00\x6c\x6f\x63\x61\x6c\x68\x6f\x73\x74\x09\x00\x50\x41\x54\x48\x5f\x49\x4e\x46\x4f\x0b\x00\x2f\x69\x6e\x64\x65\x78\x2e\x68\x74\x6d\x6c\x0b\x00\x52\x45\x4d\x4f\x54\x45\x5f\x41\x44\x44\x52\x07\x00\x31\x2e\x32\x2e\x33\x2e\x34\x0b\x00\x52\x45\x4d\x4f\x54\x45\x5f\x50\x4f\x52\x54\x04\x00\x32\x30\x30\x30\x0e\x00\x52\x45\x51\x55\x45\x53\x54\x5f\x4d\x45\x54\x48\x4f\x44\x03\x00\x47\x45\x54\x0b\x00\x53\x45\x52\x56\x45\x52\x5f\x50\x4f\x52\x54\x02\x00\x38\x30\x0c\x00\x55\x57\x53\x47\x49\x5f\x53\x43\x48\x45\x4d\x45\x04\x00\x68\x74\x74\x70", 'basic PSGI request to localhost');
}

# now go through some roundtrip test cases
my @cases = ({
	uri => 'http://localhost/index.html',
	method => 'GET',
	remote => '1.2.3.4:50000',
}, {
	uri => 'https://localhost/index.html',
	method => 'GET',
	remote => '1.2.3.4:50000',
}, {
	uri => 'https://localhost/index.html',
	method => 'GET',
	remote => '1.2.3.4:50000',
	headers => {
		'Content-Type' => 'text/html',
	}
}, {
	uri => 'https://localhost/index.txt',
	method => 'GET',
	remote => '1.2.3.4:50000',
	headers => {
		'Content-Type' => 'text/plain',
		'Content-Length' => 1024,
	}
});
for my $case (@cases) {
	ok(my $pkt = build_request(%$case), 'build packet');
	ok(my $data = extract_frame(\$pkt), 'extract packet data again');
	is(length($pkt), 0, 'packet data is now empty');

	# Drop common ports
	my $uri = uri_from_env($data);
	$uri->port(undef) if $uri->scheme eq 'http' && $uri->port == 80;
	$uri->port(undef) if $uri->scheme eq 'https' && $uri->port == 443;
	is($uri, $case->{uri}, "URI matches");
	is($data->{HTTP_HOST}, $uri->host, 'host matches');
	foreach my $k (keys %{$case->{headers}}) {
		(my $env_k = uc $k) =~ tr/-/_/;
		is($data->{"HTTP_$env_k"}, $case->{headers}{$k}, "header $k matches");
	}
}

done_testing;

