use strictures 2;
use Test2::V0 -no_srand => 1;

use JSON ();
use Digest::SHA qw(sha256);

use lib 't/lib';
use TestFixtures qw(make_event);

use Net::Nostr::Message;
use Net::Nostr::Filter;
use Net::Nostr::Negentropy;

my $JSON = JSON->new->utf8;

# Access private binary protocol functions for spec testing
my $encode_varint  = \&Net::Nostr::Negentropy::_encode_varint;
my $decode_varint  = \&Net::Nostr::Negentropy::_decode_varint;
my $fingerprint    = \&Net::Nostr::Negentropy::_fingerprint;
my $encode_message = \&Net::Nostr::Negentropy::_encode_message;
my $decode_message = \&Net::Nostr::Negentropy::_decode_message;

###############################################################################
# NIP-77 spec: NEG-OPEN message format (lines 31-44)
###############################################################################

subtest 'NEG-OPEN: construct and serialize' => sub {
    my $filter = Net::Nostr::Filter->new(kinds => [1]);
    my $msg = Net::Nostr::Message->new(
        type            => 'NEG-OPEN',
        subscription_id => 'neg1',
        filter          => $filter,
        neg_msg         => '61',
    );
    is($msg->type, 'NEG-OPEN', 'type');
    is($msg->subscription_id, 'neg1', 'subscription_id');
    is($msg->neg_msg, '61', 'neg_msg');

    my $json = $msg->serialize;
    my $arr = $JSON->decode($json);
    is($arr->[0], 'NEG-OPEN', 'wire type');
    is($arr->[1], 'neg1', 'wire subscription_id');
    is(ref $arr->[2], 'HASH', 'wire filter is object');
    is($arr->[3], '61', 'wire initialMessage');
};

subtest 'NEG-OPEN: parse' => sub {
    my $json = '["NEG-OPEN","sub1",{"kinds":[1]},"61"]';
    my $msg = Net::Nostr::Message->parse($json);
    is($msg->type, 'NEG-OPEN', 'parsed type');
    is($msg->subscription_id, 'sub1', 'parsed subscription_id');
    isa_ok($msg->filter, 'Net::Nostr::Filter');
    is($msg->neg_msg, '61', 'parsed neg_msg');
};

subtest 'NEG-OPEN: round-trip' => sub {
    my $filter = Net::Nostr::Filter->new(kinds => [1], authors => ['aa' x 32]);
    my $msg = Net::Nostr::Message->new(
        type            => 'NEG-OPEN',
        subscription_id => 'rt1',
        filter          => $filter,
        neg_msg         => 'abcdef',
    );
    my $parsed = Net::Nostr::Message->parse($msg->serialize);
    is($parsed->subscription_id, 'rt1', 'subscription_id round-trips');
    is($parsed->neg_msg, 'abcdef', 'neg_msg round-trips');
};

subtest 'NEG-OPEN: filter is NIP-01 filter (spec line 43)' => sub {
    my $json = '["NEG-OPEN","x",{"kinds":[1,4],"#p":["' . ('aa' x 32) . '"]},"61"]';
    my $msg = Net::Nostr::Message->parse($json);
    isa_ok($msg->filter, ['Net::Nostr::Filter'], 'complex filter parsed');
};

subtest 'NEG-OPEN: validation' => sub {
    like(
        dies { Net::Nostr::Message->new(type => 'NEG-OPEN', subscription_id => 'x', neg_msg => '61') },
        qr/filter is required/i,
        'missing filter rejected'
    );
    my $f = Net::Nostr::Filter->new(kinds => [1]);
    like(
        dies { Net::Nostr::Message->new(type => 'NEG-OPEN', subscription_id => 'x', filter => $f) },
        qr/neg_msg is required/i,
        'missing neg_msg rejected'
    );
    like(
        dies { Net::Nostr::Message->new(type => 'NEG-OPEN', filter => $f, neg_msg => '61') },
        qr/subscription_id/i,
        'missing subscription_id rejected'
    );
};

subtest 'NEG-OPEN: neg_msg must be hex' => sub {
    my $f = Net::Nostr::Filter->new(kinds => [1]);
    like(
        dies { Net::Nostr::Message->new(type => 'NEG-OPEN', subscription_id => 'x', filter => $f, neg_msg => 'ZZZZ') },
        qr/hex/i,
        'non-hex neg_msg rejected'
    );
};

###############################################################################
# NIP-77 spec: NEG-ERR message format (lines 46-70)
###############################################################################

subtest 'NEG-ERR: construct and serialize' => sub {
    my $msg = Net::Nostr::Message->new(
        type            => 'NEG-ERR',
        subscription_id => 'neg1',
        message         => 'blocked: too many records',
    );
    is($msg->type, 'NEG-ERR', 'type');
    is($msg->message, 'blocked: too many records', 'message');
    is($msg->prefix, 'blocked', 'prefix extracted');

    my $arr = $JSON->decode($msg->serialize);
    is($arr->[0], 'NEG-ERR', 'wire type');
    is($arr->[1], 'neg1', 'wire subscription_id');
    is($arr->[2], 'blocked: too many records', 'wire reason');
};

subtest 'NEG-ERR: parse' => sub {
    my $msg = Net::Nostr::Message->parse('["NEG-ERR","neg1","closed: you took too long"]');
    is($msg->type, 'NEG-ERR', 'parsed type');
    is($msg->subscription_id, 'neg1', 'parsed subscription_id');
    is($msg->message, 'closed: you took too long', 'parsed reason');
    is($msg->prefix, 'closed', 'prefix parsed');
};

subtest 'NEG-ERR: blocked with optional max records (spec line 64)' => sub {
    my $msg = Net::Nostr::Message->new(
        type            => 'NEG-ERR',
        subscription_id => 'neg1',
        message         => 'blocked: this query is too big',
        neg_limit       => 100000,
    );
    my $arr = $JSON->decode($msg->serialize);
    is(scalar @$arr, 4, '4 elements when neg_limit present');
    is($arr->[3], 100000, 'max records in 4th element');
};

subtest 'NEG-ERR: parse with 4th element' => sub {
    my $msg = Net::Nostr::Message->parse('["NEG-ERR","neg1","blocked: too big",50000]');
    is($msg->neg_limit, 50000, 'neg_limit parsed from 4th element');
};

subtest 'NEG-ERR: round-trip' => sub {
    my $msg = Net::Nostr::Message->new(
        type            => 'NEG-ERR',
        subscription_id => 'rt',
        message         => 'blocked: test',
        neg_limit       => 999,
    );
    my $parsed = Net::Nostr::Message->parse($msg->serialize);
    is($parsed->message, 'blocked: test', 'message round-trips');
    is($parsed->neg_limit, 999, 'neg_limit round-trips');
};

subtest 'NEG-ERR: error reasons (spec lines 60-68)' => sub {
    for my $reason ('blocked: this query is too big', 'closed: you took too long to respond!') {
        my $msg = Net::Nostr::Message->new(
            type            => 'NEG-ERR',
            subscription_id => 'x',
            message         => $reason,
        );
        ok($msg->prefix, "prefix extracted from: $reason");
    }
};

###############################################################################
# NIP-77 spec: NEG-MSG message format (lines 72-84)
###############################################################################

subtest 'NEG-MSG: construct and serialize' => sub {
    my $msg = Net::Nostr::Message->new(
        type            => 'NEG-MSG',
        subscription_id => 'neg1',
        neg_msg         => 'abcdef0123',
    );
    is($msg->type, 'NEG-MSG', 'type');
    is($msg->neg_msg, 'abcdef0123', 'neg_msg');

    my $arr = $JSON->decode($msg->serialize);
    is($arr->[0], 'NEG-MSG', 'wire type');
    is($arr->[1], 'neg1', 'wire subscription_id');
    is($arr->[2], 'abcdef0123', 'wire message');
};

subtest 'NEG-MSG: parse' => sub {
    my $msg = Net::Nostr::Message->parse('["NEG-MSG","neg1","deadbeef"]');
    is($msg->type, 'NEG-MSG', 'parsed type');
    is($msg->neg_msg, 'deadbeef', 'parsed neg_msg');
};

subtest 'NEG-MSG: round-trip' => sub {
    my $msg = Net::Nostr::Message->new(
        type            => 'NEG-MSG',
        subscription_id => 'rt',
        neg_msg         => '6100',
    );
    my $parsed = Net::Nostr::Message->parse($msg->serialize);
    is($parsed->neg_msg, '6100', 'neg_msg round-trips');
};

subtest 'NEG-MSG: validation' => sub {
    like(
        dies { Net::Nostr::Message->new(type => 'NEG-MSG', subscription_id => 'x') },
        qr/neg_msg is required/i,
        'missing neg_msg rejected'
    );
};

###############################################################################
# NIP-77 spec: NEG-CLOSE message format (lines 86-95)
###############################################################################

subtest 'NEG-CLOSE: construct and serialize' => sub {
    my $msg = Net::Nostr::Message->new(
        type            => 'NEG-CLOSE',
        subscription_id => 'neg1',
    );
    my $arr = $JSON->decode($msg->serialize);
    is($arr, ['NEG-CLOSE', 'neg1'], 'wire format');
};

subtest 'NEG-CLOSE: parse' => sub {
    my $msg = Net::Nostr::Message->parse('["NEG-CLOSE","neg1"]');
    is($msg->type, 'NEG-CLOSE', 'parsed type');
    is($msg->subscription_id, 'neg1', 'parsed subscription_id');
};

subtest 'NEG-CLOSE: round-trip' => sub {
    my $msg = Net::Nostr::Message->new(type => 'NEG-CLOSE', subscription_id => 'rt');
    my $parsed = Net::Nostr::Message->parse($msg->serialize);
    is($parsed->subscription_id, 'rt', 'subscription_id round-trips');
};

###############################################################################
# Appendix: Varint encoding (spec lines 108-112)
###############################################################################

subtest 'varint: encode/decode round-trip' => sub {
    for my $n (0, 1, 127, 128, 255, 300, 16384, 65535, 2**21 - 1) {
        my $encoded = $encode_varint->($n);
        my ($decoded, $pos) = $decode_varint->($encoded, 0);
        is($decoded, $n, "varint round-trip for $n");
        is($pos, length($encoded), "consumed all bytes for $n");
    }
};

subtest 'varint: known encodings' => sub {
    # 0 → 0x00
    is(unpack('H*', $encode_varint->(0)), '00', '0 encodes to 0x00');
    # 127 → 0x7f
    is(unpack('H*', $encode_varint->(127)), '7f', '127 encodes to 0x7f');
    # 128 → 0x81 0x00
    is(unpack('H*', $encode_varint->(128)), '8100', '128 encodes to 0x8100');
    # 300 → 0x82 0x2c
    is(unpack('H*', $encode_varint->(300)), '822c', '300 encodes to 0x822c');
};

subtest 'varint: high bit set on non-last bytes (spec line 111)' => sub {
    my $encoded = $encode_varint->(16384);  # 3 bytes
    my @bytes = unpack('C*', $encoded);
    ok($bytes[0] & 0x80, 'first byte has high bit');
    ok($bytes[1] & 0x80, 'second byte has high bit');
    ok(!($bytes[2] & 0x80), 'last byte has no high bit');
};

###############################################################################
# Appendix: Message format (spec lines 120-127)
###############################################################################

subtest 'message: protocol version byte is 0x61 (spec line 126)' => sub {
    my $ne = Net::Nostr::Negentropy->new;
    $ne->seal;
    my $msg = $ne->initiate;
    is(substr($msg, 0, 2), '61', 'initial message starts with version 0x61');
};

subtest 'message: empty message is valid (zero ranges)' => sub {
    my $bytes = pack('H*', '61');
    my $ranges = $decode_message->($bytes);
    is($ranges, [], 'empty message decodes to no ranges');
};

###############################################################################
# Appendix: Range modes (spec lines 130-149)
###############################################################################

subtest 'range: mode 0 is Skip with empty payload (spec line 138)' => sub {
    my @ranges = ({
        upper   => [100, ''],
        mode    => 0,
        payload => undef,
    });
    my $bytes = $encode_message->(\@ranges);
    my $decoded = $decode_message->($bytes);
    is($decoded->[0]{mode}, 0, 'mode 0 decoded');
};

subtest 'range: mode 1 is Fingerprint with 16 bytes (spec line 142)' => sub {
    my $fp = "\x01" x 16;
    my @ranges = ({
        upper   => [100, ''],
        mode    => 1,
        payload => $fp,
    });
    my $bytes = $encode_message->(\@ranges);
    my $decoded = $decode_message->($bytes);
    is($decoded->[0]{mode}, 1, 'mode 1 decoded');
    is(length($decoded->[0]{payload}), 16, 'fingerprint is 16 bytes');
    is($decoded->[0]{payload}, $fp, 'fingerprint matches');
};

subtest 'range: mode 2 is IdList with length + ids (spec lines 146-148)' => sub {
    my @ids = ("\xaa" x 32, "\xbb" x 32);
    my @ranges = ({
        upper   => [100, ''],
        mode    => 2,
        payload => \@ids,
    });
    my $bytes = $encode_message->(\@ranges);
    my $decoded = $decode_message->($bytes);
    is($decoded->[0]{mode}, 2, 'mode 2 decoded');
    is(scalar @{$decoded->[0]{payload}}, 2, '2 ids in list');
    is($decoded->[0]{payload}[0], "\xaa" x 32, 'first id');
    is($decoded->[0]{payload}[1], "\xbb" x 32, 'second id');
};

subtest 'range: mode 1 truncated fingerprint is rejected' => sub {
    like(
        dies { $decode_message->("\x61\x00\x00\x01\xaa") },
        qr/fingerprint.*16 bytes|truncated fingerprint/i,
        'truncated fingerprint rejected'
    );
};

subtest 'range: mode 2 truncated id list is rejected' => sub {
    like(
        dies { $decode_message->("\x61\x00\x00\x02\x01\xaa") },
        qr/id list.*32 bytes|truncated id list/i,
        'truncated id list rejected'
    );
};

###############################################################################
# Appendix: Bound encoding (spec lines 151-165)
###############################################################################

subtest 'bound: timestamp encoding (spec line 159)' => sub {
    # First range: offset from 0. Timestamp 100 → encoded as 1 + (100 - 0) = 101
    # Second range: offset from 100. Timestamp 200 → encoded as 1 + (200 - 100) = 101
    my @ranges = (
        { upper => [100, ''], mode => 0, payload => undef },
        { upper => [200, ''], mode => 0, payload => undef },
    );
    my $bytes = $encode_message->(\@ranges);
    my $decoded = $decode_message->($bytes);
    is($decoded->[0]{upper}[0], 100, 'first bound timestamp');
    is($decoded->[1]{upper}[0], 200, 'second bound timestamp');
};

subtest 'bound: id prefix 0-32 bytes (spec line 163)' => sub {
    my $prefix = "\xab\xcd";
    my @ranges = ({
        upper   => [100, $prefix],
        mode    => 0,
        payload => undef,
    });
    my $bytes = $encode_message->(\@ranges);
    my $decoded = $decode_message->($bytes);
    is($decoded->[0]{upper}[1], $prefix, 'id prefix preserved');
};

subtest 'bound: empty id prefix when timestamps differ (spec line 163)' => sub {
    my @ranges = ({
        upper   => [100, ''],
        mode    => 0,
        payload => undef,
    });
    my $bytes = $encode_message->(\@ranges);
    my $decoded = $decode_message->($bytes);
    is($decoded->[0]{upper}[1], '', 'empty prefix');
};

###############################################################################
# Appendix: Fingerprint algorithm (spec lines 168-176)
###############################################################################

subtest 'fingerprint: empty set' => sub {
    my $fp = $fingerprint->();
    # Sum = 0 (32 zero bytes), count = 0 (varint \x00)
    my $expected = substr(sha256("\x00" x 32 . "\x00"), 0, 16);
    is($fp, $expected, 'empty set fingerprint');
    is(length($fp), 16, 'fingerprint is 16 bytes');
};

subtest 'fingerprint: single item' => sub {
    my $id = "\x01" x 32;
    my $fp = $fingerprint->([1000, $id]);
    # Sum = id (LE), count = 1
    my $expected = substr(sha256($id . "\x01"), 0, 16);
    is($fp, $expected, 'single item fingerprint');
};

subtest 'fingerprint: two items, byte-level addition (spec line 172)' => sub {
    my $id1 = "\x01" x 32;
    my $id2 = "\x02" x 32;
    my $fp = $fingerprint->([1000, $id1], [2000, $id2]);
    # Sum = \x03 x 32, count = 2
    my $expected = substr(sha256("\x03" x 32 . "\x02"), 0, 16);
    is($fp, $expected, 'two item fingerprint');
};

subtest 'fingerprint: overflow mod 2^256 (spec line 172)' => sub {
    my $id1 = "\xff" x 32;
    my $id2 = "\x01" . "\x00" x 31;
    my $fp = $fingerprint->([1, $id1], [2, $id2]);
    # 0xfff...f + 0x0000...01 = 0x10000...00 mod 2^256 = 0
    my $expected = substr(sha256("\x00" x 32 . "\x02"), 0, 16);
    is($fp, $expected, 'overflow wraps mod 2^256');
};

subtest 'fingerprint: SHA-256 first 16 bytes (spec lines 174-175)' => sub {
    my $fp = $fingerprint->();
    is(length($fp), 16, 'always 16 bytes');
};

###############################################################################
# Reconciliation: end-to-end scenarios
###############################################################################

subtest 'reconcile: both empty — no differences' => sub {
    my $client = Net::Nostr::Negentropy->new;
    $client->seal;
    my $server = Net::Nostr::Negentropy->new;
    $server->seal;

    my $q1 = $client->initiate;
    my ($a1, $have, $need) = $server->reconcile($q1);
    is($have, [], 'server has nothing extra');
    is($need, [], 'server needs nothing');

    if (defined $a1) {
        my ($q2, $have2, $need2) = $client->reconcile($a1);
        is($have2, [], 'client has nothing extra');
        is($need2, [], 'client needs nothing');
    }
};

subtest 'reconcile: identical sets — no differences' => sub {
    my $id1 = '01' x 32;
    my $id2 = '02' x 32;

    my $client = Net::Nostr::Negentropy->new;
    $client->add_item(1000, $id1);
    $client->add_item(2000, $id2);
    $client->seal;

    my $server = Net::Nostr::Negentropy->new;
    $server->add_item(1000, $id1);
    $server->add_item(2000, $id2);
    $server->seal;

    my $q1 = $client->initiate;
    my ($a1, $shave, $sneed) = $server->reconcile($q1);

    my @all_have;
    my @all_need;
    if (defined $a1) {
        my ($q2, $chave, $cneed) = $client->reconcile($a1);
        push @all_have, @$chave;
        push @all_need, @$cneed;
    }
    is(\@all_have, [], 'no differences');
    is(\@all_need, [], 'no differences');
};

subtest 'reconcile: client has items server lacks' => sub {
    my $id1 = '01' x 32;
    my $id2 = '02' x 32;

    my $client = Net::Nostr::Negentropy->new;
    $client->add_item(1000, $id1);
    $client->add_item(2000, $id2);
    $client->seal;

    my $server = Net::Nostr::Negentropy->new;
    $server->seal;

    my @all_have;
    my @all_need;

    my $q = $client->initiate;
    while (defined $q) {
        my ($a, $shave, $sneed) = $server->reconcile($q);
        last unless defined $a;
        my ($q2, $chave, $cneed) = $client->reconcile($a);
        push @all_have, @$chave;
        push @all_need, @$cneed;
        $q = $q2;
    }

    my @sorted_have = sort @all_have;
    is(\@sorted_have, [sort($id1, $id2)], 'client has both items');
    is(\@all_need, [], 'client needs nothing');
};

subtest 'reconcile: server has items client lacks' => sub {
    my $id1 = '01' x 32;
    my $id2 = '02' x 32;

    my $client = Net::Nostr::Negentropy->new;
    $client->seal;

    my $server = Net::Nostr::Negentropy->new;
    $server->add_item(1000, $id1);
    $server->add_item(2000, $id2);
    $server->seal;

    my @all_have;
    my @all_need;

    my $q = $client->initiate;
    while (defined $q) {
        my ($a, $shave, $sneed) = $server->reconcile($q);
        last unless defined $a;
        my ($q2, $chave, $cneed) = $client->reconcile($a);
        push @all_have, @$chave;
        push @all_need, @$cneed;
        $q = $q2;
    }

    is(\@all_have, [], 'client has nothing extra');
    my @sorted_need = sort @all_need;
    is(\@sorted_need, [sort($id1, $id2)], 'client needs both items');
};

subtest 'reconcile: partial overlap' => sub {
    my $shared = '01' x 32;
    my $client_only = '02' x 32;
    my $server_only = '03' x 32;

    my $client = Net::Nostr::Negentropy->new;
    $client->add_item(1000, $shared);
    $client->add_item(2000, $client_only);
    $client->seal;

    my $server = Net::Nostr::Negentropy->new;
    $server->add_item(1000, $shared);
    $server->add_item(3000, $server_only);
    $server->seal;

    my @all_have;
    my @all_need;

    my $q = $client->initiate;
    while (defined $q) {
        my ($a, $shave, $sneed) = $server->reconcile($q);
        last unless defined $a;
        my ($q2, $chave, $cneed) = $client->reconcile($a);
        push @all_have, @$chave;
        push @all_need, @$cneed;
        $q = $q2;
    }

    is([sort @all_have], [$client_only], 'client has client_only');
    is([sort @all_need], [$server_only], 'client needs server_only');
};

subtest 'reconcile: larger set with multi-round' => sub {
    my @client_ids;
    my @server_ids;
    my @shared_ids;

    # Create 50 shared items, 10 client-only, 10 server-only
    for my $i (0 .. 49) {
        my $id = sprintf('%064x', $i);
        push @shared_ids, $id;
    }
    for my $i (50 .. 59) {
        my $id = sprintf('%064x', $i);
        push @client_ids, $id;
    }
    for my $i (60 .. 69) {
        my $id = sprintf('%064x', $i);
        push @server_ids, $id;
    }

    my $client = Net::Nostr::Negentropy->new;
    for my $id (@shared_ids, @client_ids) {
        $client->add_item(1000 + hex(substr($id, 0, 8)), $id);
    }
    $client->seal;

    my $server = Net::Nostr::Negentropy->new;
    for my $id (@shared_ids, @server_ids) {
        $server->add_item(1000 + hex(substr($id, 0, 8)), $id);
    }
    $server->seal;

    my @all_have;
    my @all_need;
    my $rounds = 0;

    my $q = $client->initiate;
    while (defined $q) {
        $rounds++;
        die "too many rounds" if $rounds > 20;
        my ($a, $shave, $sneed) = $server->reconcile($q);
        last unless defined $a;
        my ($q2, $chave, $cneed) = $client->reconcile($a);
        push @all_have, @$chave;
        push @all_need, @$cneed;
        $q = $q2;
    }

    is([sort @all_have], [sort @client_ids], 'correct client-only IDs');
    is([sort @all_need], [sort @server_ids], 'correct server-only IDs');
    ok($rounds <= 10, "converged in $rounds rounds");
};

###############################################################################
# Protocol flow (spec lines 15-27)
###############################################################################

subtest 'protocol: initiate requires seal' => sub {
    my $ne = Net::Nostr::Negentropy->new;
    like(
        dies { $ne->initiate },
        qr/seal/i,
        'initiate before seal rejected'
    );
};

subtest 'protocol: reconcile requires seal' => sub {
    my $ne = Net::Nostr::Negentropy->new;
    like(
        dies { $ne->reconcile('61') },
        qr/seal/i,
        'reconcile before seal rejected'
    );
};

subtest 'protocol: add_item after seal rejected' => sub {
    my $ne = Net::Nostr::Negentropy->new;
    $ne->seal;
    like(
        dies { $ne->add_item(1000, '01' x 32) },
        qr/sealed/i,
        'add_item after seal rejected'
    );
};

###############################################################################
# add_item validation
###############################################################################

subtest 'add_item: validates id format' => sub {
    my $ne = Net::Nostr::Negentropy->new;
    like(
        dies { $ne->add_item(1000, 'not-hex') },
        qr/must be 64-char/i,
        'bad id rejected'
    );
    like(
        dies { $ne->add_item(1000, 'AA' x 32) },
        qr/must be 64-char/i,
        'uppercase hex rejected'
    );
};

subtest 'add_item: validates timestamp' => sub {
    my $ne = Net::Nostr::Negentropy->new;
    like(
        dies { $ne->add_item(-1, '01' x 32) },
        qr/timestamp/i,
        'negative timestamp rejected'
    );
};

###############################################################################
# Spec line 104: sorting after seal
###############################################################################

subtest 'seal: items sorted by timestamp then id (spec line 104)' => sub {
    my $id_a = '01' x 32;
    my $id_b = '02' x 32;
    my $id_c = '03' x 32;

    # Add out of order: higher ts first, then same-ts items with id_b before id_a
    my $client = Net::Nostr::Negentropy->new;
    $client->add_item(2000, $id_c);
    $client->add_item(1000, $id_b);
    $client->add_item(1000, $id_a);
    $client->seal;

    my $server = Net::Nostr::Negentropy->new;
    $server->seal;

    my @all_have;
    my $q = $client->initiate;
    while (defined $q) {
        my ($a, $shave, $sneed) = $server->reconcile($q);
        last unless defined $a;
        my ($q2, $chave, $cneed) = $client->reconcile($a);
        push @all_have, @$chave;
        $q = $q2;
    }

    # All three should be discovered regardless of insertion order
    is([sort @all_have], [sort($id_a, $id_b, $id_c)],
        'all items found despite out-of-order insertion');
};

###############################################################################
# Spec line 104: reserved infinity timestamp
###############################################################################

subtest 'add_item: reserved infinity timestamp rejected (spec line 104)' => sub {
    my $ne = Net::Nostr::Negentropy->new;
    like(
        dies { $ne->add_item(~0, '01' x 32) },
        qr/infinity|reserved/i,
        'max uint64 timestamp rejected'
    );
};

###############################################################################
# Spec line 126: unsupported protocol version
###############################################################################

subtest 'decode: unsupported protocol version (spec line 126)' => sub {
    # Version 0x62 (protocol version 2) is not supported
    like(
        dies { $decode_message->(chr(0x62)) },
        qr/unsupported.*version/i,
        'version 0x62 rejected'
    );
    # Version 0x00 is also unsupported
    like(
        dies { $decode_message->(chr(0x00)) },
        qr/unsupported.*version/i,
        'version 0x00 rejected'
    );
};

###############################################################################
# Spec line 159: infinity bound encoding
###############################################################################

subtest 'bound: infinity timestamp encoded as 0, round-trips (spec line 159)' => sub {
    my $inf = Net::Nostr::Negentropy::INFINITY_TS();
    my @ranges = ({
        upper   => [$inf, ''],
        mode    => 0,
        payload => undef,
    });
    my $bytes = $encode_message->(\@ranges);
    my $decoded = $decode_message->($bytes);
    is($decoded->[0]{upper}[0], $inf, 'infinity timestamp round-trips');
    is($decoded->[0]{upper}[1], '', 'infinity bound has empty prefix');
};

###############################################################################
# Spec line 128: implicit infinity skip
###############################################################################

subtest 'reconcile: non-infinity last range handled (spec line 128)' => sub {
    # Build a message with a single range that does NOT end at infinity
    # The reconciler should treat everything beyond it as an implicit Skip
    my @ranges = ({
        upper   => [500, ''],
        mode    => 2,
        payload => [],
    });
    my $msg_bytes = $encode_message->(\@ranges);
    my $msg_hex = unpack('H*', $msg_bytes);

    # Server has items both inside and outside the range
    my $server = Net::Nostr::Negentropy->new;
    $server->add_item(100, '01' x 32);   # inside [0, 500)
    $server->add_item(1000, '02' x 32);  # outside — implicit skip
    $server->seal;

    # Should not croak, items outside the range are ignored
    my ($resp, $have, $need) = $server->reconcile($msg_hex);
    ok(1, 'non-infinity last range does not croak');
};

###############################################################################
# Parse validation negative tests for NEG-* messages
###############################################################################

subtest 'NEG-OPEN: parse rejects wrong element count' => sub {
    like(
        dies { Net::Nostr::Message->parse('["NEG-OPEN","x"]') },
        qr/requires 4 elements/i,
        'too few elements rejected'
    );
    like(
        dies { Net::Nostr::Message->parse('["NEG-OPEN","x",{},"61","extra"]') },
        qr/requires 4 elements/i,
        'too many elements rejected'
    );
};

subtest 'NEG-OPEN: parse rejects non-object filter' => sub {
    like(
        dies { Net::Nostr::Message->parse('["NEG-OPEN","x","not-a-filter","61"]') },
        qr/filter must be a JSON object/i,
        'string filter rejected'
    );
};

subtest 'NEG-OPEN: parse rejects non-hex neg_msg' => sub {
    like(
        dies { Net::Nostr::Message->parse('["NEG-OPEN","x",{},"ZZZZ"]') },
        qr/hex/i,
        'non-hex neg_msg rejected on parse'
    );
};

subtest 'NEG-MSG: parse rejects wrong element count' => sub {
    like(
        dies { Net::Nostr::Message->parse('["NEG-MSG","x"]') },
        qr/requires 3 elements/i,
        'too few elements rejected'
    );
    like(
        dies { Net::Nostr::Message->parse('["NEG-MSG","x","ab","extra"]') },
        qr/requires 3 elements/i,
        'too many elements rejected'
    );
};

subtest 'NEG-MSG: parse rejects non-hex neg_msg' => sub {
    like(
        dies { Net::Nostr::Message->parse('["NEG-MSG","x","ZZZZ"]') },
        qr/hex/i,
        'non-hex neg_msg rejected on parse'
    );
};

subtest 'NEG-MSG: construct rejects non-hex neg_msg' => sub {
    like(
        dies { Net::Nostr::Message->new(type => 'NEG-MSG', subscription_id => 'x', neg_msg => 'ZZZZ') },
        qr/hex/i,
        'non-hex neg_msg rejected on construct'
    );
};

subtest 'NEG-CLOSE: parse rejects wrong element count' => sub {
    like(
        dies { Net::Nostr::Message->parse('["NEG-CLOSE"]') },
        qr/requires 2 elements/i,
        'too few elements rejected'
    );
    like(
        dies { Net::Nostr::Message->parse('["NEG-CLOSE","x","extra"]') },
        qr/requires 2 elements/i,
        'too many elements rejected'
    );
};

subtest 'NEG-ERR: parse rejects wrong element count' => sub {
    like(
        dies { Net::Nostr::Message->parse('["NEG-ERR","x"]') },
        qr/requires 3 or 4 elements/i,
        'too few elements rejected'
    );
    like(
        dies { Net::Nostr::Message->parse('["NEG-ERR","x","msg",1,"extra"]') },
        qr/requires 3 or 4 elements/i,
        'too many elements rejected'
    );
};

###############################################################################
# NEG-ERR: 3-element serialization without neg_limit
###############################################################################

subtest 'NEG-ERR: serializes 3 elements without neg_limit' => sub {
    my $msg = Net::Nostr::Message->new(
        type            => 'NEG-ERR',
        subscription_id => 'neg1',
        message         => 'blocked: test',
    );
    my $arr = $JSON->decode($msg->serialize);
    is(scalar @$arr, 3, 'exactly 3 elements without neg_limit');
    is($arr->[0], 'NEG-ERR', 'type');
    is($arr->[1], 'neg1', 'subscription_id');
    is($arr->[2], 'blocked: test', 'message');
};

###############################################################################
# frame_size_limit constructor option
###############################################################################

subtest 'constructor: frame_size_limit accepted' => sub {
    my $ne = Net::Nostr::Negentropy->new(frame_size_limit => 4096);
    isa_ok($ne, 'Net::Nostr::Negentropy');
};

subtest 'frame_size_limit: initiate enforces maximum encoded message size' => sub {
    my $ne = Net::Nostr::Negentropy->new(frame_size_limit => 1);
    $ne->add_item(1000, '01' x 32);
    $ne->seal;

    like(
        dies { $ne->initiate },
        qr/frame_size_limit/i,
        'oversized initiate message rejected'
    );
};

subtest 'frame_size_limit: reconcile enforces maximum encoded response size' => sub {
    my $client = Net::Nostr::Negentropy->new;
    $client->add_item(1000, '01' x 32);
    $client->seal;

    my $server = Net::Nostr::Negentropy->new(frame_size_limit => 1);
    $server->add_item(2000, '02' x 32);
    $server->seal;

    my $q = $client->initiate;
    like(
        dies { $server->reconcile($q) },
        qr/frame_size_limit/i,
        'oversized response rejected'
    );
};

###############################################################################
# Spec line 163: _compute_bound prefix rules
###############################################################################

my $compute_bound = \&Net::Nostr::Negentropy::_compute_bound;

subtest 'compute_bound: different timestamps produce empty prefix (spec line 163)' => sub {
    my $item_a = [100, pack('H*', 'aa' x 32)];
    my $item_b = [200, pack('H*', 'bb' x 32)];
    my $bound = $compute_bound->($item_a, $item_b);
    is($bound->[0], 200, 'timestamp is from item_b');
    is($bound->[1], '', 'prefix is empty when timestamps differ');
};

subtest 'compute_bound: same timestamp, common prefix + 1 (spec line 163)' => sub {
    # IDs share first 2 bytes (0xaa, 0xbb) then differ at byte 3
    my $id_a = pack('H*', 'aabb01' . ('00' x 29));
    my $id_b = pack('H*', 'aabb02' . ('00' x 29));
    my $item_a = [100, $id_a];
    my $item_b = [100, $id_b];
    my $bound = $compute_bound->($item_a, $item_b);
    is($bound->[0], 100, 'timestamp is from item_b');
    is(length($bound->[1]), 3, 'prefix length = common prefix (2) + 1');
    is($bound->[1], substr($id_b, 0, 3), 'prefix is first 3 bytes of item_b');
};

subtest 'compute_bound: same timestamp, completely different IDs (spec line 163)' => sub {
    my $id_a = pack('H*', '01' . ('00' x 31));
    my $id_b = pack('H*', '02' . ('00' x 31));
    my $item_a = [100, $id_a];
    my $item_b = [100, $id_b];
    my $bound = $compute_bound->($item_a, $item_b);
    is(length($bound->[1]), 1, 'prefix length = 0 common + 1');
    is($bound->[1], substr($id_b, 0, 1), 'prefix is first byte of item_b');
};

###############################################################################
# Spec line 163: 32-byte (full) id prefix
###############################################################################

subtest 'bound: full 32-byte id prefix round-trips (spec line 163)' => sub {
    my $full_prefix = "\xab" x 32;
    my @ranges = ({
        upper   => [100, $full_prefix],
        mode    => 0,
        payload => undef,
    });
    my $bytes = $encode_message->(\@ranges);
    my $decoded = $decode_message->($bytes);
    is(length($decoded->[0]{upper}[1]), 32, 'full 32-byte prefix preserved');
    is($decoded->[0]{upper}[1], $full_prefix, 'prefix content matches');
};

###############################################################################
# Spec line 104: same-timestamp reconciliation with non-empty peer
###############################################################################

subtest 'reconcile: same-timestamp items sorted by ID (spec line 104)' => sub {
    # All items share timestamp 1000, differ only by ID
    # This exercises _compute_bound with same-timestamp id-prefix boundaries
    my $shared1     = '01' x 32;
    my $shared2     = '03' x 32;
    my $client_only = '02' x 32;  # between shared1 and shared2 lexically
    my $server_only = '04' x 32;

    my $client = Net::Nostr::Negentropy->new;
    $client->add_item(1000, $shared1);
    $client->add_item(1000, $shared2);
    $client->add_item(1000, $client_only);
    $client->seal;

    my $server = Net::Nostr::Negentropy->new;
    $server->add_item(1000, $shared1);
    $server->add_item(1000, $shared2);
    $server->add_item(1000, $server_only);
    $server->seal;

    my @all_have;
    my @all_need;

    my $q = $client->initiate;
    while (defined $q) {
        my ($a, $shave, $sneed) = $server->reconcile($q);
        last unless defined $a;
        my ($q2, $chave, $cneed) = $client->reconcile($a);
        push @all_have, @$chave;
        push @all_need, @$cneed;
        $q = $q2;
    }

    is([sort @all_have], [$client_only], 'client-only ID found');
    is([sort @all_need], [$server_only], 'server-only ID found');
};

###############################################################################
# Transport integration: Client + Relay end-to-end negentropy sync
###############################################################################

use AnyEvent;
use IO::Socket::INET;
use Net::Nostr::Client;
use Net::Nostr::Relay;
use Net::Nostr::Key;

my $port;
{
    my $sock = IO::Socket::INET->new(
        Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0,
    );
    $port = $sock->sockport;
    close $sock;
}

subtest 'end-to-end negentropy sync via Client + Relay' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    # Store some events in the relay
    my $key = Net::Nostr::Key->new;
    my @relay_events;
    for my $i (1 .. 3) {
        my $ev = $key->create_event(
            kind    => 1,
            content => "relay event $i",
            tags    => [],
            created_at => 1000 + $i,
        );
        $relay->store->store($ev);
        push @relay_events, $ev;
    }

    # Client connects
    my $client = Net::Nostr::Client->new;
    $client->connect("ws://127.0.0.1:$port");

    # Wait for AUTH challenge
    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    # Client has event 1 and 2 locally, wants to sync
    my $ne = Net::Nostr::Negentropy->new;
    $ne->add_item($relay_events[0]->created_at, $relay_events[0]->id);
    $ne->add_item($relay_events[1]->created_at, $relay_events[1]->id);
    $ne->seal;

    my $initial_msg = $ne->initiate;

    # Set up callbacks to collect NEG-MSG responses
    my @neg_msgs;
    my $neg_err;
    $client->on(neg_msg => sub {
        my ($sub_id, $msg) = @_;
        push @neg_msgs, { sub_id => $sub_id, msg => $msg };
    });
    $client->on(neg_err => sub {
        my ($sub_id, $reason) = @_;
        $neg_err = { sub_id => $sub_id, reason => $reason };
    });

    # Send NEG-OPEN
    my $filter = Net::Nostr::Filter->new(kinds => [1]);
    $client->neg_open('neg1', $filter, $initial_msg);

    # Wait for relay response
    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.2, cb => sub { $cv->send });
    $cv->recv;

    ok scalar @neg_msgs >= 1, 'received at least one NEG-MSG response';
    is $neg_msgs[0]{sub_id}, 'neg1', 'subscription ID matches';
    ok !$neg_err, 'no NEG-ERR received';

    # Process response with negentropy
    my ($next, $have, $need) = $ne->reconcile($neg_msgs[0]{msg});

    # Client has events 1 and 2, relay has 1, 2, and 3
    # So client needs event 3
    is scalar @$need, 1, 'client needs one event';
    is $need->[0], $relay_events[2]->id, 'client needs event 3';

    # If more rounds needed, continue
    if (defined $next) {
        $client->neg_msg('neg1', $next);
        $cv = AnyEvent->condvar;
        $w = AnyEvent->timer(after => 0.2, cb => sub { $cv->send });
        $cv->recv;
    }

    # Close the negentropy session
    $client->neg_close('neg1');

    $client->disconnect;
    $relay->stop;
};

subtest 'relay sends NEG-ERR for parse failures' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $client = Net::Nostr::Client->new;
    my $neg_err;
    $client->on(neg_err => sub {
        my ($sub_id, $reason) = @_;
        $neg_err = { sub_id => $sub_id, reason => $reason };
    });
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    # Send a NEG-OPEN with invalid (non-hex) neg_msg via raw WebSocket
    my $raw = JSON::encode_json(['NEG-OPEN', 'neg1', { kinds => [1] }, 'not_hex!!!']);
    $client->_conn->send($raw);

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.2, cb => sub { $cv->send });
    $cv->recv;

    ok $neg_err, 'received NEG-ERR';
    is $neg_err->{sub_id}, 'neg1', 'subscription ID matches' if $neg_err;

    $client->disconnect;
    $relay->stop;
};

subtest 'NEG-OPEN replaces existing session with same sub_id' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $key = Net::Nostr::Key->new;
    my $ev = $key->create_event(
        kind => 1, content => 'test', tags => [], created_at => 1000,
    );
    $relay->store->store($ev);

    my $client = Net::Nostr::Client->new;
    my @neg_msgs;
    $client->on(neg_msg => sub {
        my ($sub_id, $msg) = @_;
        push @neg_msgs, { sub_id => $sub_id, msg => $msg };
    });
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    # First NEG-OPEN
    my $ne1 = Net::Nostr::Negentropy->new;
    $ne1->seal;
    my $filter = Net::Nostr::Filter->new(kinds => [1]);
    $client->neg_open('neg1', $filter, $ne1->initiate);

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.2, cb => sub { $cv->send });
    $cv->recv;

    ok scalar @neg_msgs >= 1, 'got response from first NEG-OPEN';

    # Second NEG-OPEN with same ID replaces session
    @neg_msgs = ();
    my $ne2 = Net::Nostr::Negentropy->new;
    $ne2->seal;
    $client->neg_open('neg1', $filter, $ne2->initiate);

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.2, cb => sub { $cv->send });
    $cv->recv;

    ok scalar @neg_msgs >= 1, 'got response from replacement NEG-OPEN';

    $client->neg_close('neg1');
    $client->disconnect;
    $relay->stop;
};

subtest 'relay cleans up neg sessions on disconnect' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $client = Net::Nostr::Client->new;
    $client->on(neg_msg => sub {});
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    my $ne = Net::Nostr::Negentropy->new;
    $ne->seal;
    my $filter = Net::Nostr::Filter->new(kinds => [1]);
    $client->neg_open('neg1', $filter, $ne->initiate);

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.2, cb => sub { $cv->send });
    $cv->recv;

    $client->disconnect;

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    # Verify internal neg sessions are cleaned up
    my $neg_sessions = $relay->{_neg_sessions} || {};
    is scalar keys %$neg_sessions, 0, 'neg sessions cleaned up after disconnect';

    $relay->stop;
};

subtest 'relay sends NEG-ERR for NEG-MSG on non-existent session' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $client = Net::Nostr::Client->new;
    my $neg_err;
    $client->on(neg_err => sub {
        my ($sub_id, $reason) = @_;
        $neg_err = { sub_id => $sub_id, reason => $reason };
    });
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    # Send NEG-MSG for a session that was never opened
    $client->neg_msg('nonexistent', '61');

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.2, cb => sub { $cv->send });
    $cv->recv;

    ok $neg_err, 'received NEG-ERR for non-existent session';
    is $neg_err->{sub_id}, 'nonexistent', 'subscription ID matches';
    like $neg_err->{reason}, qr/closed/i, 'reason indicates closed session';

    $client->disconnect;
    $relay->stop;
};

subtest 'NEG-CLOSE then NEG-MSG produces NEG-ERR' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $key = Net::Nostr::Key->new;
    my $ev = $key->create_event(
        kind => 1, content => 'test', tags => [], created_at => 1000,
    );
    $relay->store->store($ev);

    my $client = Net::Nostr::Client->new;
    my @neg_msgs;
    my $neg_err;
    $client->on(neg_msg => sub { push @neg_msgs, [@_] });
    $client->on(neg_err => sub { $neg_err = { sub_id => $_[0], reason => $_[1] } });
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    # Open a session
    my $ne = Net::Nostr::Negentropy->new;
    $ne->seal;
    my $filter = Net::Nostr::Filter->new(kinds => [1]);
    $client->neg_open('neg1', $filter, $ne->initiate);

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.2, cb => sub { $cv->send });
    $cv->recv;

    ok @neg_msgs >= 1, 'got initial response';

    # Close the session, then try to continue
    $client->neg_close('neg1');
    $neg_err = undef;
    $client->neg_msg('neg1', '61');

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.2, cb => sub { $cv->send });
    $cv->recv;

    ok $neg_err, 'NEG-ERR received after NEG-CLOSE';
    like $neg_err->{reason}, qr/closed/i, 'reason indicates closed session';

    $client->disconnect;
    $relay->stop;
};

subtest 'multiple concurrent negentropy sessions' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    my $key = Net::Nostr::Key->new;
    my $ev1 = $key->create_event(
        kind => 1, content => 'kind1', tags => [], created_at => 1000,
    );
    my $ev2 = $key->create_event(
        kind => 2, content => 'kind2', tags => [], created_at => 2000,
    );
    $relay->store->store($ev1);
    $relay->store->store($ev2);

    my $client = Net::Nostr::Client->new;
    my %neg_msgs;
    $client->on(neg_msg => sub {
        my ($sub_id, $msg) = @_;
        push @{$neg_msgs{$sub_id}}, $msg;
    });
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    # Open two sessions with different filters
    my $ne1 = Net::Nostr::Negentropy->new;
    $ne1->seal;
    my $ne2 = Net::Nostr::Negentropy->new;
    $ne2->seal;

    $client->neg_open('kind1_sync', Net::Nostr::Filter->new(kinds => [1]), $ne1->initiate);
    $client->neg_open('kind2_sync', Net::Nostr::Filter->new(kinds => [2]), $ne2->initiate);

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.3, cb => sub { $cv->send });
    $cv->recv;

    ok exists $neg_msgs{kind1_sync}, 'session 1 received response';
    ok exists $neg_msgs{kind2_sync}, 'session 2 received response';

    # Process each independently
    my ($r1, $have1, $need1) = $ne1->reconcile($neg_msgs{kind1_sync}[0]);
    my ($r2, $have2, $need2) = $ne2->reconcile($neg_msgs{kind2_sync}[0]);

    is scalar @$need1, 1, 'session 1: needs one event';
    is $need1->[0], $ev1->id, 'session 1: needs the kind=1 event';
    is scalar @$need2, 1, 'session 2: needs one event';
    is $need2->[0], $ev2->id, 'session 2: needs the kind=2 event';

    # Close one, the other should still work
    $client->neg_close('kind1_sync');

    $client->neg_close('kind2_sync');
    $client->disconnect;
    $relay->stop;
};

subtest 'negentropy sync with empty relay result set' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    # Relay has no events

    my $client = Net::Nostr::Client->new;
    my @neg_msgs;
    $client->on(neg_msg => sub { push @neg_msgs, [@_] });
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    # Client has one event, relay has none
    my $ne = Net::Nostr::Negentropy->new;
    $ne->add_item(1000, 'ab' x 32);
    $ne->seal;

    $client->neg_open('neg1', Net::Nostr::Filter->new(kinds => [1]), $ne->initiate);

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.2, cb => sub { $cv->send });
    $cv->recv;

    ok @neg_msgs >= 1, 'relay responded even with no matching events';

    my ($next, $have, $need) = $ne->reconcile($neg_msgs[0][1]);
    is scalar @$have, 1, 'client has one event relay lacks';
    is $have->[0], 'ab' x 32, 'correct ID';
    is scalar @$need, 0, 'client needs nothing';

    $client->neg_close('neg1');
    $client->disconnect;
    $relay->stop;
};

subtest 'relay strips filter limit for negentropy (needs ALL events)' => sub {
    my $relay = Net::Nostr::Relay->new(verify_signatures => 0);
    $relay->start('127.0.0.1', $port);

    # Store 5 events in the relay
    my $key = Net::Nostr::Key->new;
    my @relay_events;
    for my $i (1 .. 5) {
        my $ev = $key->create_event(
            kind => 1, content => "event $i", tags => [], created_at => 1000 + $i,
        );
        $relay->store->store($ev);
        push @relay_events, $ev;
    }

    my $client = Net::Nostr::Client->new;
    my @neg_msgs;
    $client->on(neg_msg => sub { push @neg_msgs, [@_] });
    $client->connect("ws://127.0.0.1:$port");

    my $cv = AnyEvent->condvar;
    my $w = AnyEvent->timer(after => 0.1, cb => sub { $cv->send });
    $cv->recv;

    # Client has none, sends filter with limit=2
    # Relay must still use ALL 5 events for negentropy
    my $ne = Net::Nostr::Negentropy->new;
    $ne->seal;

    my $filter = Net::Nostr::Filter->new(kinds => [1], limit => 2);
    $client->neg_open('neg1', $filter, $ne->initiate);

    $cv = AnyEvent->condvar;
    $w = AnyEvent->timer(after => 0.2, cb => sub { $cv->send });
    $cv->recv;

    ok @neg_msgs >= 1, 'got response';

    my ($next, $have, $need) = $ne->reconcile($neg_msgs[0][1]);
    is scalar @$need, 5, 'client needs all 5 events despite limit=2 in filter';

    $client->neg_close('neg1');
    $client->disconnect;
    $relay->stop;
};

done_testing;
