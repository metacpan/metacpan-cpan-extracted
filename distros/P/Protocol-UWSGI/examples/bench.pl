#!/usr/bin/env perl 
use strict;
use warnings;
use Benchmark qw(:hireswallclock cmpthese);
use Protocol::UWSGI qw(:all);
use Digest::SHA qw(sha256_hex);

my $req = build_request(
	modifier1 => PSGI_MODIFIER1,
	modifier2 => PSGI_MODIFIER2,
	method => 'GET',
	uri => 'http://uwssgi.example.com/test',
	'HTTP_ACCEPT_LANGUAGE' => 'en-GB,en-US;q=0.8,en;q=0.6',
	'REMOTE_PORT' => '57574',
	'PATH_INFO' => '/test',
	'HTTP_HOST' => 'uwsgi.example.com',
	'HTTP_CONNECTION' => 'keep-alive',
	'QUERY_STRING' => '',
	'HTTP_ACCEPT' => 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
	'CONTENT_TYPE' => '',
	'REQUEST_METHOD' => 'GET',
	'SERVER_NAME' => 'uwsgi.example.com',
	'SERVER_PROTOCOL' => 'HTTP/1.1',
	'HTTP_ACCEPT_ENCODING' => 'gzip,deflate,sdch',
	'REQUEST_URI' => '/test',
	'REMOTE_ADDR' => '192.168.1.1',
	'HTTP_CACHE_CONTROL' => 'max-age=0',
	'HTTP_USER_AGENT' => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.153 Safari/537.36',
	'SERVER_PORT' => '80',
	'CONTENT_LENGTH' => '',
	'UWSGI_SCHEME' => 'http',
	'DOCUMENT_ROOT' => '/var/www/uwsgi'
);

sub extract4 {
	my ($buffref) = @_;

	my ($modifier1, $length, $modifier2) = unpack 'C1v1C1', $$buffref;
	# no, still too short
	return undef unless $length && length $$buffref >= $length + 4;

	# then do the modifier-specific handling
	die "Unsupported modifier1 $modifier1" unless $modifier1 == PSGI_MODIFIER1;

	# hack bits off the buffer
	substr $$buffref, 0, 4, '';

	my %env = unpack '(v1/a*)*', substr $$buffref, 0, $length, '';
	\%env
}
sub extract3 {
	my ($buffref) = @_;

	my ($modifier1, $length, $modifier2) = unpack 'C1v1C1', $$buffref;
	# no, still too short
	return undef unless $length && length $$buffref >= $length + 4;

	# then do the modifier-specific handling
	die "Unsupported modifier1 $modifier1" unless $modifier1 == PSGI_MODIFIER1;

	# hack bits off the buffer
	substr $$buffref, 0, 4, '';

	my %env;
	while($length) {
		my ($k, $v) = unpack 'v1/a*v1/a*', $$buffref;
		$env{$k} = $v;
		substr $$buffref, 0, (my $found = 4 + length($k) + length($v)), '';
		$length -= $found;
	}
	\%env
}
sub extract2 {
	my ($buffref) = @_;

	my ($modifier1, $length, $modifier2) = unpack 'C1v1C1', $$buffref;
	# no, still too short
	return undef unless $length && length $$buffref >= $length + 4;

	# then do the modifier-specific handling
	die "Unsupported modifier1 $modifier1" unless $modifier1 == PSGI_MODIFIER1;

	# hack bits off the buffer
	substr $$buffref, 0, 4, '';

	my %env;
	while($length) {
		my ($kl) = unpack 'v1', substr $$buffref, 0, 2, '';
		my $k = substr $$buffref, 0, $kl, '';
		my ($vl) = unpack 'v1', substr $$buffref, 0, 2, '';
		$env{$k} = substr $$buffref, 0, $vl, '';
		$length -= 4 + $kl + $vl;
	}
	\%env
}

my %impl = (
	extract_frame => sub { my $copy = $req; extract_frame(\$copy) },
	extract2 => sub { my $copy = $req; extract2(\$copy) },
	extract3 => sub { my $copy = $req; extract3(\$copy) },
	extract4 => sub { my $copy = $req; extract4(\$copy) },
);
for(sort keys %impl) {
	my $result = $impl{$_}->($_);
	my $str = sha256_hex join "\x1F", map { "$_\x1E" . $result->{$_} } sort keys %$result;
	printf "%-32.32s => %s\n", $_, $str;
}

cmpthese -5, {
	extract_frame => sub { my $copy = $req; extract_frame(\$copy) },
	extract2 => sub { my $copy = $req; extract2(\$copy) },
	extract3 => sub { my $copy = $req; extract3(\$copy) },
	extract4 => sub { my $copy = $req; extract4(\$copy) },
};
