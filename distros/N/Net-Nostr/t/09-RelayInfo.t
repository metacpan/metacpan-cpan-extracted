#!/usr/bin/perl

# Unit tests for Net::Nostr::RelayInfo

use strictures 2;

use Test2::V0 -no_srand => 1;
use JSON;

use Net::Nostr::RelayInfo;

my $JSON = JSON->new->utf8;
my $pk = 'a' x 64;

###############################################################################
# Constructor and accessors
###############################################################################

subtest 'new creates relay info' => sub {
    my $info = Net::Nostr::RelayInfo->new(name => 'test');
    isa_ok($info, 'Net::Nostr::RelayInfo');
    is($info->name, 'test', 'name');
};

subtest 'all top-level fields' => sub {
    my $info = Net::Nostr::RelayInfo->new(
        name             => 'My Relay',
        description      => 'A test relay',
        banner           => 'https://example.com/banner.png',
        icon             => 'https://example.com/icon.png',
        pubkey           => $pk,
        self             => $pk,
        contact          => 'mailto:admin@example.com',
        supported_nips   => [1, 9, 11, 42],
        software         => 'https://example.com/relay',
        version          => '1.0.0',
        terms_of_service => 'https://example.com/tos',
    );

    is($info->name, 'My Relay', 'name');
    is($info->description, 'A test relay', 'description');
    is($info->banner, 'https://example.com/banner.png', 'banner');
    is($info->icon, 'https://example.com/icon.png', 'icon');
    is($info->pubkey, $pk, 'pubkey');
    is($info->self, $pk, 'self');
    is($info->contact, 'mailto:admin@example.com', 'contact');
    is($info->supported_nips, [1, 9, 11, 42], 'supported_nips');
    is($info->software, 'https://example.com/relay', 'software');
    is($info->version, '1.0.0', 'version');
    is($info->terms_of_service, 'https://example.com/tos', 'terms_of_service');
};

subtest 'limitation' => sub {
    my $info = Net::Nostr::RelayInfo->new(
        limitation => {
            max_message_length => 16384,
            max_subscriptions  => 300,
            auth_required      => JSON::true,
        },
    );
    is($info->limitation->{max_message_length}, 16384, 'max_message_length');
    is($info->limitation->{max_subscriptions}, 300, 'max_subscriptions');
    ok($info->limitation->{auth_required}, 'auth_required');
};

subtest 'fees and payments_url' => sub {
    my $info = Net::Nostr::RelayInfo->new(
        payments_url => 'https://relay.example.com/payments',
        fees => {
            admission => [{ amount => 1000000, unit => 'msats' }],
        },
    );
    is($info->payments_url, 'https://relay.example.com/payments', 'payments_url');
    is($info->fees->{admission}[0]{amount}, 1000000, 'fee amount');
};

###############################################################################
# to_json
###############################################################################

subtest 'to_json includes set fields' => sub {
    my $info = Net::Nostr::RelayInfo->new(
        name           => 'Test',
        supported_nips => [1, 11],
        version        => '0.1',
    );
    my $doc = $JSON->decode($info->to_json);
    is($doc->{name}, 'Test', 'name');
    is($doc->{supported_nips}, [1, 11], 'supported_nips');
    is($doc->{version}, '0.1', 'version');
};

subtest 'to_json omits unset fields' => sub {
    my $info = Net::Nostr::RelayInfo->new(name => 'Test');
    my $doc = $JSON->decode($info->to_json);
    ok(exists $doc->{name}, 'name exists');
    ok(!exists $doc->{description}, 'description omitted');
    ok(!exists $doc->{pubkey}, 'pubkey omitted');
    ok(!exists $doc->{supported_nips}, 'supported_nips omitted');
    ok(!exists $doc->{limitation}, 'limitation omitted');
};

subtest 'to_json includes limitation and fees' => sub {
    my $info = Net::Nostr::RelayInfo->new(
        limitation => { max_subscriptions => 50 },
        fees => { admission => [{ amount => 1000, unit => 'msats' }] },
    );
    my $doc = $JSON->decode($info->to_json);
    is($doc->{limitation}{max_subscriptions}, 50, 'limitation');
    is($doc->{fees}{admission}[0]{amount}, 1000, 'fees');
};

###############################################################################
# from_json
###############################################################################

subtest 'from_json round-trip' => sub {
    my $orig = Net::Nostr::RelayInfo->new(
        name           => 'Test Relay',
        description    => 'desc',
        supported_nips => [1, 9, 11],
        version        => '2.0',
    );
    my $parsed = Net::Nostr::RelayInfo->from_json($orig->to_json);
    is($parsed->name, 'Test Relay', 'name');
    is($parsed->description, 'desc', 'description');
    is($parsed->supported_nips, [1, 9, 11], 'supported_nips');
    is($parsed->version, '2.0', 'version');
};

subtest 'from_json ignores extra fields' => sub {
    my $json = $JSON->encode({
        name    => 'Test',
        unknown => 'ignored',
        custom  => { nested => 1 },
    });
    my $info = Net::Nostr::RelayInfo->from_json($json);
    is($info->name, 'Test', 'name');
};

subtest 'from_json with limitation' => sub {
    my $json = $JSON->encode({
        name => 'Test',
        limitation => {
            max_message_length => 16384,
            auth_required      => JSON::true,
        },
    });
    my $info = Net::Nostr::RelayInfo->from_json($json);
    is($info->limitation->{max_message_length}, 16384, 'max_message_length');
};

###############################################################################
# to_http_response
###############################################################################

subtest 'to_http_response status and content-type' => sub {
    my $info = Net::Nostr::RelayInfo->new(name => 'Test');
    my $resp = $info->to_http_response;
    like($resp, qr{^HTTP/1\.1 200 OK\r\n}, 'status line');
    like($resp, qr{Content-Type: application/nostr\+json\r\n}, 'content-type');
};

subtest 'to_http_response CORS headers' => sub {
    my $info = Net::Nostr::RelayInfo->new(name => 'Test');
    my $resp = $info->to_http_response;
    like($resp, qr{Access-Control-Allow-Origin: \*\r\n}, 'allow-origin');
    like($resp, qr{Access-Control-Allow-Headers:}, 'allow-headers');
    like($resp, qr{Access-Control-Allow-Methods:}, 'allow-methods');
};

subtest 'to_http_response body is valid JSON' => sub {
    my $info = Net::Nostr::RelayInfo->new(name => 'Test', version => '1.0');
    my $resp = $info->to_http_response;
    my ($body) = $resp =~ /\r\n\r\n(.+)/s;
    my $doc = $JSON->decode($body);
    is($doc->{name}, 'Test', 'name in body');
    is($doc->{version}, '1.0', 'version in body');
};

subtest 'to_http_response content-length' => sub {
    my $info = Net::Nostr::RelayInfo->new(name => 'Test');
    my $resp = $info->to_http_response;
    my ($len) = $resp =~ /Content-Length: (\d+)/;
    my ($body) = $resp =~ /\r\n\r\n(.+)/s;
    is($len, length($body), 'content-length matches body');
};

###############################################################################
# cors_preflight_response
###############################################################################

subtest 'cors_preflight_response' => sub {
    my $resp = Net::Nostr::RelayInfo->cors_preflight_response;
    like($resp, qr{^HTTP/1\.1 204 No Content\r\n}, 'status line');
    like($resp, qr{Access-Control-Allow-Origin: \*}, 'allow-origin');
    like($resp, qr{Access-Control-Allow-Headers:}, 'allow-headers');
    like($resp, qr{Access-Control-Allow-Methods:}, 'allow-methods');
};

###############################################################################
# Empty/minimal
###############################################################################

subtest 'empty relay info' => sub {
    my $info = Net::Nostr::RelayInfo->new;
    my $doc = $JSON->decode($info->to_json);
    is($doc, {}, 'empty object');
};

###############################################################################
# new() POD example
###############################################################################

subtest 'new() POD example' => sub {
    my $info = Net::Nostr::RelayInfo->new(
        name             => 'My Relay',
        description      => 'A relay for everyone',
        banner           => 'https://example.com/banner.jpg',
        icon             => 'https://example.com/icon.png',
        pubkey           => 'aa' x 32,
        self             => 'bb' x 32,
        contact          => 'mailto:admin@example.com',
        supported_nips   => [1, 9, 11],
        software         => 'https://example.com/relay',
        version          => '1.0.0',
        terms_of_service => 'https://example.com/tos',
        limitation       => { max_subscriptions => 50 },
        payments_url     => 'https://example.com/pay',
        fees             => { admission => [{ amount => 1000, unit => 'msats' }] },
    );
    is $info->name, 'My Relay';
    is $info->description, 'A relay for everyone';
    is $info->banner, 'https://example.com/banner.jpg';
    is $info->icon, 'https://example.com/icon.png';
    is $info->pubkey, 'aa' x 32;
    is $info->self, 'bb' x 32;
    is $info->contact, 'mailto:admin@example.com';
    is $info->supported_nips, [1, 9, 11];
    is $info->software, 'https://example.com/relay';
    is $info->version, '1.0.0';
    is $info->terms_of_service, 'https://example.com/tos';
    is $info->limitation, { max_subscriptions => 50 };
    is $info->payments_url, 'https://example.com/pay';
    is $info->fees, { admission => [{ amount => 1000, unit => 'msats' }] };
};

subtest 'new() rejects unknown arguments' => sub {
    like(
        dies { Net::Nostr::RelayInfo->new(name => 'test', bogus => 'value') },
        qr/unknown.+bogus/i,
        'unknown argument rejected'
    );
};

###############################################################################
# Defensive copying: caller/accessor mutation must not affect internal state
###############################################################################

subtest 'caller mutation of supported_nips does not affect object' => sub {
    my @nips = (1, 11);
    my $info = Net::Nostr::RelayInfo->new(supported_nips => \@nips);
    push @nips, 42;
    is scalar @{$info->supported_nips}, 2, 'supported_nips unaffected';
};

subtest 'accessor mutation of supported_nips does not affect object' => sub {
    my $info = Net::Nostr::RelayInfo->new(supported_nips => [1, 11]);
    my $got = $info->supported_nips;
    push @$got, 42;
    is scalar @{$info->supported_nips}, 2, 'supported_nips unaffected';
};

subtest 'caller mutation of limitation does not affect object' => sub {
    my %lim = (max_subscriptions => 50);
    my $info = Net::Nostr::RelayInfo->new(limitation => \%lim);
    $lim{auth_required} = 1;
    ok !exists $info->limitation->{auth_required}, 'limitation unaffected';
};

subtest 'accessor mutation of limitation does not affect object' => sub {
    my $info = Net::Nostr::RelayInfo->new(limitation => { max_subscriptions => 50 });
    my $got = $info->limitation;
    $got->{auth_required} = 1;
    ok !exists $info->limitation->{auth_required}, 'limitation unaffected';
};

subtest 'caller mutation of fees does not affect object' => sub {
    my %fees = (admission => [{ amount => 1000, unit => 'msats' }]);
    my $info = Net::Nostr::RelayInfo->new(fees => \%fees);
    $fees{subscription} = [{ amount => 5000, unit => 'msats' }];
    ok !exists $info->fees->{subscription}, 'fees unaffected';
};

subtest 'accessor mutation of fees does not affect object' => sub {
    my $info = Net::Nostr::RelayInfo->new(fees => { admission => [{ amount => 1000, unit => 'msats' }] });
    my $got = $info->fees;
    $got->{subscription} = [{ amount => 5000, unit => 'msats' }];
    ok !exists $info->fees->{subscription}, 'fees unaffected';
};

done_testing;
