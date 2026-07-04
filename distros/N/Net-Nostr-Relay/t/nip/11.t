#!/usr/bin/perl

# NIP-11: Relay Information Document
# https://github.com/nostr-protocol/nips/blob/master/11.md

use strictures 2;

use Test2::V0 -no_srand => 1;
use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket qw(tcp_connect);
use IO::Socket::INET;
use JSON;

use AnyEvent::WebSocket::Client;

use Net::Nostr::Relay;
use Net::Nostr::RelayInfo;

my $JSON = JSON->new->utf8;
my $pk = 'a' x 64;

sub free_port {
    my $sock = IO::Socket::INET->new(
        Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0,
    );
    my $port = $sock->sockport;
    close $sock;
    return $port;
}

# Non-blocking HTTP request via AnyEvent
sub http_request {
    my ($port, %args) = @_;
    my $method = $args{method} // 'GET';
    my $accept = $args{accept} // 'application/nostr+json';

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    tcp_connect '127.0.0.1', $port, sub {
        my ($fh) = @_ or return $cv->croak("connect failed: $!");

        my $request = "$method / HTTP/1.1\r\nHost: 127.0.0.1:$port\r\n";
        $request .= "Accept: $accept\r\n" if defined $accept;
        $request .= "Connection: close\r\n\r\n";

        my $response = '';
        my $hdl; $hdl = AnyEvent::Handle->new(
            fh       => $fh,
            on_error => sub { undef $hdl; $cv->send($response) },
            on_eof   => sub { undef $hdl; $cv->send($response) },
            on_read  => sub { $response .= $_[0]->rbuf; $_[0]->rbuf = '' },
        );
        $hdl->push_write($request);
    };

    return $cv->recv;
}

sub parse_http_response {
    my ($resp) = @_;
    my ($headers, $body) = split /\r\n\r\n/, $resp, 2;
    my @lines = split /\r\n/, $headers;
    my $status_line = shift @lines;
    my %hdrs;
    for my $line (@lines) {
        my ($k, $v) = split /:\s*/, $line, 2;
        $hdrs{lc $k} = $v;
    }
    return ($status_line, \%hdrs, $body);
}

###############################################################################
# Relay information document structure
###############################################################################

subtest 'relay info document has correct structure' => sub {
    my $info = Net::Nostr::RelayInfo->new(
        name             => 'Test Relay',
        description      => 'A relay for testing',
        banner           => 'https://example.com/banner.jpg',
        icon             => 'https://example.com/icon.png',
        pubkey           => $pk,
        self             => $pk,
        contact          => 'mailto:admin@example.com',
        supported_nips   => [1, 9, 11, 42],
        software         => 'https://example.com/relay',
        version          => '1.0.0',
        terms_of_service => 'https://example.com/tos',
    );
    my $doc = $JSON->decode($info->to_json);

    is($doc->{name}, 'Test Relay', 'name is string');
    is($doc->{description}, 'A relay for testing', 'description is string');
    is($doc->{banner}, 'https://example.com/banner.jpg', 'banner is link');
    is($doc->{icon}, 'https://example.com/icon.png', 'icon is link');
    is($doc->{pubkey}, $pk, 'pubkey is 32-byte hex');
    is($doc->{self}, $pk, 'self is 32-byte hex');
    is($doc->{contact}, 'mailto:admin@example.com', 'contact is URI');
    is($doc->{supported_nips}, [1, 9, 11, 42], 'supported_nips is array of ints');
    is($doc->{software}, 'https://example.com/relay', 'software is URL');
    is($doc->{version}, '1.0.0', 'version is string');
    is($doc->{terms_of_service}, 'https://example.com/tos', 'terms_of_service is link');
};

subtest 'any field may be omitted' => sub {
    my $info = Net::Nostr::RelayInfo->new(name => 'Minimal');
    my $doc = $JSON->decode($info->to_json);
    is(scalar keys %$doc, 1, 'only name present');
    ok(!exists $doc->{description}, 'description omitted');
    ok(!exists $doc->{supported_nips}, 'supported_nips omitted');
};

subtest 'clients MUST ignore additional fields' => sub {
    my $json = $JSON->encode({
        name           => 'Test',
        custom_field   => 'ignored',
        nested_unknown => { foo => 'bar' },
    });
    my $info = Net::Nostr::RelayInfo->from_json($json);
    is($info->name, 'Test', 'known field parsed');
    # extra fields don't cause errors
};

###############################################################################
# supported_nips is integer array
###############################################################################

subtest 'supported_nips contains integer NIP numbers' => sub {
    my $info = Net::Nostr::RelayInfo->new(
        supported_nips => [1, 9, 11, 42, 44],
    );
    my $doc = $JSON->decode($info->to_json);
    for my $nip (@{$doc->{supported_nips}}) {
        ok($nip == int($nip), "NIP $nip is integer");
    }
};

###############################################################################
# Server limitations
###############################################################################

subtest 'limitation fields' => sub {
    my $info = Net::Nostr::RelayInfo->new(
        limitation => {
            max_message_length   => 16384,
            max_subscriptions    => 300,
            max_limit            => 5000,
            max_subid_length     => 100,
            max_event_tags       => 100,
            max_content_length   => 8196,
            min_pow_difficulty   => 30,
            auth_required        => JSON::true,
            payment_required     => JSON::true,
            restricted_writes    => JSON::true,
            created_at_lower_limit => 31536000,
            created_at_upper_limit => 3,
            default_limit        => 500,
        },
    );
    my $doc = $JSON->decode($info->to_json);
    my $lim = $doc->{limitation};
    is($lim->{max_message_length}, 16384, 'max_message_length');
    is($lim->{max_subscriptions}, 300, 'max_subscriptions');
    is($lim->{max_limit}, 5000, 'max_limit');
    is($lim->{max_subid_length}, 100, 'max_subid_length');
    is($lim->{max_event_tags}, 100, 'max_event_tags');
    is($lim->{max_content_length}, 8196, 'max_content_length');
    is($lim->{min_pow_difficulty}, 30, 'min_pow_difficulty');
    ok($lim->{auth_required}, 'auth_required');
    ok($lim->{payment_required}, 'payment_required');
    ok($lim->{restricted_writes}, 'restricted_writes');
    is($lim->{created_at_lower_limit}, 31536000, 'created_at_lower_limit');
    is($lim->{created_at_upper_limit}, 3, 'created_at_upper_limit');
    is($lim->{default_limit}, 500, 'default_limit');
};

###############################################################################
# Pay-to-relay fees
###############################################################################

subtest 'fees and payments_url' => sub {
    my $info = Net::Nostr::RelayInfo->new(
        payments_url => 'https://relay.example.com/payments',
        fees => {
            admission    => [{ amount => 1000000, unit => 'msats' }],
            subscription => [{ amount => 5000000, unit => 'msats', period => 2592000 }],
            publication  => [{ kinds => [4], amount => 100, unit => 'msats' }],
        },
    );
    my $doc = $JSON->decode($info->to_json);
    is($doc->{payments_url}, 'https://relay.example.com/payments', 'payments_url');
    is($doc->{fees}{admission}[0]{amount}, 1000000, 'admission fee');
    is($doc->{fees}{subscription}[0]{period}, 2592000, 'subscription period');
    is($doc->{fees}{publication}[0]{kinds}, [4], 'publication kinds');
};

###############################################################################
# CORS headers
###############################################################################

subtest 'CORS headers MUST be present in response' => sub {
    my $info = Net::Nostr::RelayInfo->new(name => 'Test');
    my $resp = $info->to_http_response;
    like($resp, qr{Access-Control-Allow-Origin: \*}, 'Access-Control-Allow-Origin');
    like($resp, qr{Access-Control-Allow-Headers:}, 'Access-Control-Allow-Headers');
    like($resp, qr{Access-Control-Allow-Methods:}, 'Access-Control-Allow-Methods');
};

###############################################################################
# Relay integration: serving the document
###############################################################################

subtest 'relay serves NIP-11 document on Accept: application/nostr+json' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        relay_info => Net::Nostr::RelayInfo->new(
            name           => 'Test Relay',
            supported_nips => [1, 11],
            version        => '0.1.0',
        ),
    );
    $relay->start('127.0.0.1', $port);

    my $resp = http_request($port);
    my ($status, $hdrs, $body) = parse_http_response($resp);

    like($status, qr{200 OK}, 'HTTP 200');
    is($hdrs->{'content-type'}, 'application/nostr+json', 'content-type');
    is($hdrs->{'access-control-allow-origin'}, '*', 'CORS allow-origin');
    ok(exists $hdrs->{'access-control-allow-headers'}, 'CORS allow-headers');
    ok(exists $hdrs->{'access-control-allow-methods'}, 'CORS allow-methods');

    is($hdrs->{'content-length'}, length($body), 'Content-Length matches body');
    ok(eval { $JSON->decode($body); 1 }, 'response body is valid JSON');

    my $doc = $JSON->decode($body);
    is($doc->{name}, 'Test Relay', 'name');
    is($doc->{supported_nips}, [1, 11], 'supported_nips');
    is($doc->{version}, '0.1.0', 'version');

    $relay->stop;
};

subtest 'relay still accepts WebSocket after NIP-11 support' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        relay_info => Net::Nostr::RelayInfo->new(name => 'Test'),
    );
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my $client = AnyEvent::WebSocket::Client->new;
    my $client_conn;
    $client->connect("ws://127.0.0.1:$port")->cb(sub {
        $client_conn = eval { shift->recv };
        if ($client_conn) {
            $cv->send('connected');
        } else {
            $cv->croak("ws connect failed: $@");
        }
    });

    is($cv->recv, 'connected', 'WebSocket connects normally');
    $relay->stop;
};

subtest 'relay handles CORS preflight OPTIONS request' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        relay_info => Net::Nostr::RelayInfo->new(name => 'Test'),
    );
    $relay->start('127.0.0.1', $port);

    my $resp = http_request($port, method => 'OPTIONS');
    my ($status, $hdrs) = parse_http_response($resp);

    like($status, qr{204 No Content}, 'HTTP 204');
    is($hdrs->{'access-control-allow-origin'}, '*', 'allow-origin');
    ok(exists $hdrs->{'access-control-allow-headers'}, 'allow-headers');
    ok(exists $hdrs->{'access-control-allow-methods'}, 'allow-methods');

    $relay->stop;
};

subtest 'relay without relay_info does not serve NIP-11' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    # WebSocket should still work
    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    my $client = AnyEvent::WebSocket::Client->new;
    my $client_conn;
    $client->connect("ws://127.0.0.1:$port")->cb(sub {
        $client_conn = eval { shift->recv };
        $cv->send($client_conn ? 'ok' : 'fail');
    });

    is($cv->recv, 'ok', 'WebSocket works without relay_info');
    $relay->stop;
};

###############################################################################
# Real-world example from spec (nostr.wine)
###############################################################################

subtest 'parse nostr.wine example from spec' => sub {
    my $json = $JSON->encode({
        contact        => 'wino@nostr.wine',
        description    => 'A paid nostr relay for wine enthusiasts and everyone else.',
        fees           => { admission => [{ amount => 18888000, unit => 'msats' }] },
        icon           => 'https://image.nostr.build/example.png',
        limitation     => {
            auth_required        => JSON::false,
            created_at_lower_limit => 94608000,
            created_at_upper_limit => 300,
            max_event_tags       => 4000,
            max_limit            => 1000,
            max_message_length   => 524288,
            max_subid_length     => 71,
            max_subscriptions    => 50,
            min_pow_difficulty   => 0,
            payment_required     => JSON::true,
            restricted_writes    => JSON::true,
        },
        name           => 'nostr.wine',
        payments_url   => 'https://nostr.wine/invoices',
        pubkey         => '4918eb332a41b71ba9a74b1dc64276cfff592e55107b93baae38af3520e55975',
        software       => 'https://nostr.wine',
        supported_nips => [1, 2, 4, 9, 11, 40, 42, 50, 70, 77],
        terms_of_service => 'https://nostr.wine/terms',
        version        => '0.3.3',
    });

    my $info = Net::Nostr::RelayInfo->from_json($json);
    is($info->name, 'nostr.wine', 'name');
    is($info->pubkey, '4918eb332a41b71ba9a74b1dc64276cfff592e55107b93baae38af3520e55975', 'pubkey');
    is(scalar @{$info->supported_nips}, 10, 'supported_nips count');
    ok($info->limitation->{payment_required}, 'payment_required');
    is($info->fees->{admission}[0]{amount}, 18888000, 'admission fee');
};

###############################################################################
# name SHOULD be less than 30 characters
###############################################################################

subtest 'name field works with short and long values' => sub {
    my $short = Net::Nostr::RelayInfo->new(name => 'short');
    is($short->name, 'short', 'short name');

    my $long = Net::Nostr::RelayInfo->new(name => 'a' x 50);
    is(length($long->name), 50, 'long name accepted (no enforcement)');
};

###############################################################################
# Round-trip with all fields
###############################################################################

subtest 'full round-trip' => sub {
    my $orig = Net::Nostr::RelayInfo->new(
        name             => 'Full Test',
        description      => 'desc',
        banner           => 'https://example.com/b.jpg',
        icon             => 'https://example.com/i.png',
        pubkey           => $pk,
        self             => $pk,
        contact          => 'mailto:a@b.com',
        supported_nips   => [1, 11],
        software         => 'https://example.com',
        version          => '2.0',
        terms_of_service => 'https://example.com/tos',
        limitation       => { max_subscriptions => 10 },
        payments_url     => 'https://example.com/pay',
        fees             => { admission => [{ amount => 100, unit => 'msats' }] },
    );
    my $parsed = Net::Nostr::RelayInfo->from_json($orig->to_json);
    is($parsed->name, 'Full Test', 'name');
    is($parsed->self, $pk, 'self');
    is($parsed->limitation->{max_subscriptions}, 10, 'limitation');
    is($parsed->fees->{admission}[0]{amount}, 100, 'fees');
};

###############################################################################
# Real-world example from spec (nostr.land)
###############################################################################

subtest 'parse nostr.land example from spec' => sub {
    my $json = $JSON->encode({
        description    => '[✨ NFDB] nostr.land family of relays (fi-01 [tiger])',
        name           => '[✨ NFDB] nostr.land',
        pubkey         => '52b4a076bcbbbdc3a1aefa3735816cf74993b1b8db202b01c883c58be7fad8bd',
        software       => 'NFDB',
        icon           => 'https://i.nostr.build/b3thno790aodH8lE.jpg',
        supported_nips => [1, 2, 4, 8, 9, 10, 11, 13, 14, 15, 16, 17, 18, 19,
                           21, 22, 23, 24, 25, 27, 28, 30, 31, 32, 34, 35, 36,
                           37, 38, 39, 40, 42, 44, 46, 47, 48, 51, 52, 53, 54,
                           55, 56, 57, 58, 59, 60, 61, 64, 65, 68, 69, 71, 72,
                           73, 75, 78, 84, 88, 89, 90, 92, 99],
        version        => '1.0.0',
        limitation     => {
            payment_required   => JSON::true,
            max_message_length => 65535,
            max_event_tags     => 2000,
            max_subscriptions  => 200,
            auth_required      => JSON::false,
        },
        payments_url     => 'https://nostr.land',
        fees             => {
            subscription => [{ amount => 4000000, unit => 'msats', period => 2592000 }],
        },
        terms_of_service => 'https://nostr.land/terms',
    });

    my $info = Net::Nostr::RelayInfo->from_json($json);
    is($info->name, '[✨ NFDB] nostr.land', 'name with unicode');
    is($info->software, 'NFDB', 'software without URL');
    is(scalar @{$info->supported_nips}, 62, 'supported_nips count');
    ok($info->limitation->{payment_required}, 'payment_required');
    ok(!$info->limitation->{auth_required}, 'auth_required false');
    is($info->fees->{subscription}[0]{period}, 2592000, 'subscription period');
};

###############################################################################
# Description with double newline paragraphs
###############################################################################

subtest 'description with double newline paragraphs round-trips' => sub {
    my $desc = "First paragraph about the relay.\n\nSecond paragraph with more detail.\n\nThird paragraph.";
    my $info = Net::Nostr::RelayInfo->new(description => $desc);
    my $parsed = Net::Nostr::RelayInfo->from_json($info->to_json);
    is($parsed->description, $desc, 'double newline paragraphs preserved');
};

###############################################################################
# Relay with minimal RelayInfo serves empty document
###############################################################################

subtest 'relay with empty RelayInfo serves empty document' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        relay_info => Net::Nostr::RelayInfo->new(),
    );
    $relay->start('127.0.0.1', $port);

    my $resp = http_request($port);
    my ($status, $hdrs, $body) = parse_http_response($resp);

    like($status, qr{200 OK}, 'HTTP 200');
    my $doc = $JSON->decode($body);
    is(scalar keys %$doc, 0, 'empty document');

    $relay->stop;
};

###############################################################################
# Fragmented HTTP request must still be correctly classified
###############################################################################

subtest 'fragmented NIP-11 request is correctly handled' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        relay_info => Net::Nostr::RelayInfo->new(name => 'Fragment Test'),
    );
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    tcp_connect '127.0.0.1', $port, sub {
        my ($fh) = @_ or return $cv->croak("connect failed: $!");

        my $part1 = "GET / HTTP/1.1\r\nHost: 127.0.0.1:$port\r\n";
        my $part2 = "Accept: application/nostr+json\r\nConnection: close\r\n\r\n";

        my $response = '';
        my $hdl; $hdl = AnyEvent::Handle->new(
            fh       => $fh,
            on_error => sub { undef $hdl; $cv->send($response) },
            on_eof   => sub { undef $hdl; $cv->send($response) },
            on_read  => sub { $response .= $_[0]->rbuf; $_[0]->rbuf = '' },
        );

        # Send first fragment without \r\n\r\n
        $hdl->push_write($part1);

        # Send remainder after a short delay
        my $t; $t = AnyEvent->timer(after => 0.1, cb => sub {
            undef $t;
            $hdl->push_write($part2);
        });
    };

    my $resp = $cv->recv;
    my ($status, $hdrs, $body) = parse_http_response($resp);

    like($status, qr{200 OK}, 'fragmented request gets HTTP 200');
    my $doc = $JSON->decode($body);
    is($doc->{name}, 'Fragment Test', 'NIP-11 response body correct');

    $relay->stop;
};

subtest 'fragmented OPTIONS request is correctly handled' => sub {
    my $port = free_port();
    my $relay = Net::Nostr::Relay->new(
        verify_signatures => 0,
        relay_info => Net::Nostr::RelayInfo->new(name => 'Fragment Test'),
    );
    $relay->start('127.0.0.1', $port);

    my $cv = AnyEvent->condvar;
    my $timeout = AnyEvent->timer(after => 5, cb => sub { $cv->croak("timeout") });

    tcp_connect '127.0.0.1', $port, sub {
        my ($fh) = @_ or return $cv->croak("connect failed: $!");

        my $part1 = "OPTIONS / HTTP/1.1\r\n";
        my $part2 = "Host: 127.0.0.1:$port\r\nConnection: close\r\n\r\n";

        my $response = '';
        my $hdl; $hdl = AnyEvent::Handle->new(
            fh       => $fh,
            on_error => sub { undef $hdl; $cv->send($response) },
            on_eof   => sub { undef $hdl; $cv->send($response) },
            on_read  => sub { $response .= $_[0]->rbuf; $_[0]->rbuf = '' },
        );

        $hdl->push_write($part1);
        my $t; $t = AnyEvent->timer(after => 0.1, cb => sub {
            undef $t;
            $hdl->push_write($part2);
        });
    };

    my $resp = $cv->recv;
    my ($status) = parse_http_response($resp);
    like($status, qr{204 No Content}, 'fragmented OPTIONS gets HTTP 204');

    $relay->stop;
};

done_testing;
