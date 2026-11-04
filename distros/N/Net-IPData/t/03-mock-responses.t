#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 61;
use JSON::PP qw(encode_json decode_json);
use Scalar::Util qw(refaddr);

use_ok('Net::IPData');

# --- Mock HTTP::Tiny to avoid real network calls ---

my @mock_responses;
my @mock_calls;    # [ method, HTTP::Tiny object, url, opts ] for every request made

{
    # 'once': each glob is assigned here and nowhere else, which would
    # otherwise draw a "used only once: possible typo" warning
    no warnings qw(redefine once);

    *HTTP::Tiny::get = sub {
        my ($self, $url) = @_;
        push @mock_calls, ['get', $self, $url];
        return _next_mock_response($url);
    };

    *HTTP::Tiny::post = sub {
        my ($self, $url, $opts) = @_;
        push @mock_calls, ['post', $self, $url, $opts];
        return _next_mock_response($url, $opts);
    };
}

sub _next_mock_response {
    my ($url, $opts) = @_;
    die "No mock response queued for: $url" unless @mock_responses;
    my $mock = shift @mock_responses;
    if (ref $mock eq 'CODE') {
        return $mock->($url, $opts);
    }
    return $mock;
}

sub mock_json_response {
    my ($status, $data) = @_;
    push @mock_responses, {
        status  => $status,
        content => encode_json($data),
        headers => { 'content-type' => 'application/json' },
        success => ($status >= 200 && $status < 300) ? 1 : 0,
    };
}

sub mock_text_response {
    my ($status, $text) = @_;
    push @mock_responses, {
        status  => $status,
        content => $text,
        headers => { 'content-type' => 'text/plain' },
        success => ($status >= 200 && $status < 300) ? 1 : 0,
    };
}

my $ipd = Net::IPData->new(api_key => 'test_key_123');

# --- Test: successful IP lookup ---
{
    my $mock_data = {
        ip           => '8.8.8.8',
        is_eu        => JSON::PP::false,
        city         => 'Mountain View',
        region       => 'California',
        region_code  => 'CA',
        country_name => 'United States',
        country_code => 'US',
        continent_name => 'North America',
        continent_code => 'NA',
        latitude     => 37.386,
        longitude    => -122.0838,
        postal       => '94035',
        calling_code => '1',
        flag         => 'https://ipdata.co/flags/us.png',
        emoji_flag   => "\x{1F1FA}\x{1F1F8}",
        emoji_unicode => 'U+1F1FA U+1F1F8',
        asn          => {
            asn    => 'AS15169',
            name   => 'Google LLC',
            domain => 'google.com',
            route  => '8.8.8.0/24',
            type   => 'business',
        },
        company => {
            name    => 'Google LLC',
            domain  => 'google.com',
            network => '8.8.8.0/24',
            type    => 'business',
        },
        carrier  => { name => '', mcc => '', mnc => '' },
        languages => [
            { name => 'English', native => 'English', code => 'en' },
        ],
        currency => {
            name   => 'US Dollar',
            code   => 'USD',
            symbol => '$',
            native => '$',
            plural => 'US dollars',
        },
        time_zone => {
            name         => 'America/Los_Angeles',
            abbr         => 'PST',
            offset       => '-0800',
            is_dst       => JSON::PP::false,
            current_time => '2025-01-15T10:30:00-08:00',
        },
        threat => {
            is_tor            => JSON::PP::false,
            is_icloud_relay   => JSON::PP::false,
            is_proxy          => JSON::PP::false,
            is_datacenter     => JSON::PP::false,
            is_anonymous      => JSON::PP::false,
            is_known_attacker => JSON::PP::false,
            is_known_abuser   => JSON::PP::false,
            is_threat         => JSON::PP::false,
            is_bogon          => JSON::PP::false,
        },
        count => 0,
    };

    mock_json_response(200, $mock_data);
    my $result = $ipd->lookup('8.8.8.8');
    is($result->{ip}, '8.8.8.8', 'lookup returns correct IP');
    is($result->{country_name}, 'United States', 'lookup returns country_name');
    is($result->{city}, 'Mountain View', 'lookup returns city');
    is($result->{asn}{name}, 'Google LLC', 'lookup returns nested ASN name');
    is($result->{currency}{code}, 'USD', 'lookup returns currency code');
    is($result->{time_zone}{name}, 'America/Los_Angeles', 'lookup returns timezone');
    ok(!$result->{threat}{is_tor}, 'threat is_tor is false');
}

# --- Test: lookup_mine (no IP) ---
{
    mock_json_response(200, { ip => '203.0.113.1', country_name => 'Australia' });
    my $result = $ipd->lookup_mine();
    is($result->{ip}, '203.0.113.1', 'lookup_mine returns IP');
    is($result->{country_name}, 'Australia', 'lookup_mine returns country');
}

# --- Test: lookup with field filtering ---
{
    mock_json_response(200, { ip => '8.8.8.8', country_name => 'United States' });
    my $result = $ipd->lookup('8.8.8.8', fields => [qw(ip country_name)]);
    is($result->{ip}, '8.8.8.8', 'filtered lookup returns IP');
    is($result->{country_name}, 'United States', 'filtered lookup returns country_name');
}

# --- Test: lookup_field returns a single text value ---
{
    mock_text_response(200, '"United States"');
    my $result = $ipd->lookup_field('8.8.8.8', 'country_name');
    is($result, 'United States', 'lookup_field returns plain text');
}

# --- Test: lookup_field returns JSON for nested fields ---
{
    mock_json_response(200, { asn => 'AS15169', name => 'Google LLC', domain => 'google.com', route => '8.8.8.0/24', type => 'business' });
    my $result = $ipd->lookup_field('8.8.8.8', 'asn');
    is($result->{name}, 'Google LLC', 'lookup_field returns parsed JSON for asn');
}

# --- Test: single-field lookups answer with a bare JSON scalar, which every
#     JSON::PP version must decode (before 4.0 only allow_nonref permits it) ---
{
    mock_text_response(200, 'false');
    my $eu = $ipd->is_eu('8.8.8.8');
    ok(defined $eu && !$eu, 'is_eu: bare false decodes to a defined false value');

    mock_text_response(200, 'true');
    ok($ipd->is_eu('185.1.1.1'), 'is_eu: bare true decodes to a true value');

    mock_text_response(200, 'null');
    ok(!defined $ipd->lookup_field('8.8.8.8', 'city'), 'lookup_field: bare null decodes to undef, not the string "null"');

    mock_text_response(200, '"Zürich"');
    is($ipd->lookup_field('8.8.8.8', 'city'), "Z\x{fc}rich", 'lookup_field: a \u escape in a bare string is decoded');

    mock_text_response(200, '"Mountain \"View\""');
    is($ipd->lookup_field('8.8.8.8', 'city'), 'Mountain "View"', 'lookup_field: escaped quotes in a bare string are decoded');

    mock_text_response(200, '37.386');
    is($ipd->lookup_field('8.8.8.8', 'latitude'), 37.386, 'lookup_field: a bare number is returned as a number');

    mock_text_response(200, 'not json at all');
    is($ipd->lookup_field('8.8.8.8', 'city'), 'not json at all', 'a 2xx body that is not JSON is returned as trimmed text');

    mock_text_response(502, '<html>Bad Gateway</html>');
    eval { $ipd->lookup('8.8.8.8') };
    like($@, qr{^HTTP 502: <html>Bad Gateway</html>}, 'an error body that is not JSON is reported with its status');
}

# --- Test: bulk lookup ---
{
    my $bulk_data = [
        { ip => '8.8.8.8', country_name => 'United States' },
        { ip => '1.1.1.1', country_name => 'Australia' },
    ];
    mock_json_response(200, $bulk_data);

    my $results = $ipd->bulk(['8.8.8.8', '1.1.1.1']);
    is($mock_calls[-1][3]{headers}{'Content-Type'}, 'application/json', 'bulk POST carries Content-Type: application/json');
    is(ref $results, 'ARRAY', 'bulk returns array ref');
    is(scalar @$results, 2, 'bulk returns 2 results');
    is($results->[0]{ip}, '8.8.8.8', 'bulk result 0 IP');
    is($results->[1]{country_name}, 'Australia', 'bulk result 1 country');
}

# --- Test: convenience methods ---
{
    mock_json_response(200, { is_tor => JSON::PP::false, is_proxy => JSON::PP::true, is_threat => JSON::PP::true });
    my $threat = $ipd->threat('8.8.8.8');
    ok($threat->{is_proxy}, 'threat convenience method works');
}

{
    mock_json_response(200, { name => 'USD', code => 'USD', symbol => '$' });
    my $curr = $ipd->currency('8.8.8.8');
    is($curr->{code}, 'USD', 'currency convenience method works');
}

# --- Test: API error responses ---
{
    mock_json_response(401, { message => 'You have not provided a valid API Key.' });
    eval { $ipd->lookup('8.8.8.8') };
    like($@, qr/401/, 'error includes status code');
    like($@, qr/valid API Key/i, 'error includes API message');
}

{
    mock_json_response(403, { message => 'Access forbidden.' });
    eval { $ipd->lookup('8.8.8.8') };
    like($@, qr/403/, '403 error propagated');
}

{
    mock_json_response(429, { message => 'You have exceeded your rate limit.' });
    eval { $ipd->lookup('8.8.8.8') };
    like($@, qr/429/, '429 rate limit error propagated');
    like($@, qr/rate limit/i, '429 message preserved');
}

# --- Test: network failure (HTTP::Tiny status 599) ---
{
    push @mock_responses, {
        status  => 599,
        content => 'Connection timed out',
        headers => {},
        success => 0,
    };
    eval { $ipd->lookup('8.8.8.8') };
    like($@, qr/Network error/i, 'network failure raises error');
    like($@, qr/timed out/i, 'network error includes reason');
}

sub mock_network_error {
    my ($text) = @_;
    push @mock_responses, {
        status  => 599,
        content => $text,
        headers => { 'content-type' => 'text/plain' },
        success => 0,
    };
}

# --- Test: every request on one object goes through the same HTTP::Tiny ---
{
    my %seen = map { refaddr($_->[1]) => 1 } @mock_calls;
    is(scalar keys %seen, 1, 'all requests so far went through a single HTTP::Tiny object');
    is((keys %seen)[0], refaddr($ipd->ua), 'that object is the one the ua accessor returns');
    isa_ok($ipd->ua, 'HTTP::Tiny', 'ua');
    ok($ipd->ua->keep_alive, 'the HTTP::Tiny object has keep_alive enabled');
    is_deeply($ipd->ua->default_headers, { Accept => 'application/json' }, 'GET requests send Accept only: Content-Type is not a default header');
}

# --- Test: bulk (POST) is retried once when the kept-alive socket was dead ---
{
    @mock_calls = ();
    mock_network_error("Socket closed by remote server: Broken pipe\n");
    mock_json_response(200, [ { ip => '8.8.8.8', country_name => 'United States' } ]);

    my $results = $ipd->bulk(['8.8.8.8']);
    is(scalar @mock_calls, 2, 'bulk retried once after a "Socket closed" 599');
    is($mock_calls[0][0], 'post', 'first attempt was a POST');
    is($mock_calls[1][0], 'post', 'retry was a POST');
    is($mock_calls[1][2], $mock_calls[0][2], 'retry used the same URL');
    is($mock_calls[1][3]{content}, $mock_calls[0][3]{content}, 'retry sent the same body');
    is($mock_calls[1][3]{headers}{'Content-Type'}, 'application/json', 'retry sent the Content-Type too');
    is($results->[0]{ip}, '8.8.8.8', 'result of the retry is returned');
}

{
    @mock_calls = ();
    mock_network_error("Unexpected end of stream\n");
    mock_json_response(200, [ { ip => '1.1.1.1' } ]);

    my $results = $ipd->bulk(['1.1.1.1']);
    is(scalar @mock_calls, 2, 'bulk retried once after "Unexpected end of stream"');
    is($results->[0]{ip}, '1.1.1.1', 'result of the retry is returned');
}

{
    @mock_calls = ();
    mock_network_error("Could not write to socket: 'Connection reset by peer'\n");
    mock_json_response(200, [ { ip => '9.9.9.9' } ]);

    my $results = $ipd->bulk(['9.9.9.9']);
    is(scalar @mock_calls, 2, 'bulk retried once after "Connection reset"');
    is($results->[0]{ip}, '9.9.9.9', 'result of the retry is returned');
}

# --- Test: bulk is retried exactly once ---
{
    @mock_calls = ();
    mock_network_error("Socket closed by remote server: Broken pipe\n");
    mock_network_error("Socket closed by remote server: Broken pipe\n");

    eval { $ipd->bulk(['8.8.8.8']) };
    like($@, qr/Network error: Socket closed/, 'bulk fails when the single retry fails too');
    is(scalar @mock_calls, 2, 'bulk is retried exactly once');
    is(scalar @mock_responses, 0, 'no third attempt was made');
}

# --- Test: other network errors are not retried ---
{
    @mock_calls = ();
    mock_network_error("Timed out while waiting for socket to become ready for reading\n");

    eval { $ipd->bulk(['8.8.8.8']) };
    like($@, qr/Network error: Timed out/, 'timeout is reported as a network error');
    is(scalar @mock_calls, 1, 'a timeout 599 is not retried');
}

# --- Test: an HTTP status is never retried ---
{
    @mock_calls = ();
    mock_json_response(500, { message => 'Internal server error' });

    eval { $ipd->bulk(['8.8.8.8']) };
    like($@, qr/500/, 'bulk HTTP error is propagated');
    is(scalar @mock_calls, 1, 'an HTTP status is never retried');
}

# --- Test: GET is not retried by the module (HTTP::Tiny retries idempotent requests itself) ---
{
    @mock_calls = ();
    mock_network_error("Socket closed by remote server: Broken pipe\n");

    eval { $ipd->lookup('8.8.8.8') };
    like($@, qr/Network error: Socket closed/, 'GET stale-connection error is reported');
    is(scalar @mock_calls, 1, 'GET is not retried by the module');
}
