use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::Negentropy;

###############################################################################
# POD example: basic reconciliation
###############################################################################

subtest 'POD: basic reconciliation' => sub {
    my $client = Net::Nostr::Negentropy->new;
    $client->add_item(1000, '01' x 32);
    $client->add_item(2000, '02' x 32);
    $client->seal;

    my $server = Net::Nostr::Negentropy->new;
    $server->add_item(1000, '01' x 32);
    $server->add_item(3000, '03' x 32);
    $server->seal;

    my $q = $client->initiate;
    ok(defined $q, 'initiate returns hex message');
    like($q, qr/\A[0-9a-f]+\z/, 'message is hex-encoded');

    my ($a, $shave, $sneed) = $server->reconcile($q);
    ok(defined $a, 'server returns response');

    my ($q2, $chave, $cneed) = $client->reconcile($a);
    is([sort @$chave], ['02' x 32], 'client has 02');
    is([sort @$cneed], ['03' x 32], 'client needs 03');
};

###############################################################################
# POD example: empty sets
###############################################################################

subtest 'POD: empty sets' => sub {
    my $ne = Net::Nostr::Negentropy->new;
    $ne->seal;
    my $msg = $ne->initiate;
    ok(defined $msg, 'empty set produces a message');
};

###############################################################################
# Constructor
###############################################################################

subtest 'constructor: no args' => sub {
    my $ne = Net::Nostr::Negentropy->new;
    isa_ok($ne, 'Net::Nostr::Negentropy');
};

subtest 'constructor: unknown args rejected' => sub {
    like(
        dies { Net::Nostr::Negentropy->new(bogus => 1) },
        qr/unknown/i,
        'unknown arg rejected'
    );
};

###############################################################################
# exports
###############################################################################

subtest 'POD: constructor with frame_size_limit' => sub {
    my $ne = Net::Nostr::Negentropy->new(frame_size_limit => 4096);
    isa_ok($ne, 'Net::Nostr::Negentropy');
};

subtest 'frame_size_limit: initiate rejects oversized messages' => sub {
    my $ne = Net::Nostr::Negentropy->new(frame_size_limit => 1);
    $ne->add_item(1000, '01' x 32);
    $ne->seal;

    like(
        dies { $ne->initiate },
        qr/frame_size_limit/i,
        'oversized initiate message rejected'
    );
};

subtest 'frame_size_limit: reconcile rejects oversized responses' => sub {
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
        'oversized reconcile response rejected'
    );
};

subtest 'exports: public methods available' => sub {
    can_ok('Net::Nostr::Negentropy', qw(new add_item seal initiate reconcile));
};

###############################################################################
# add_item: validation
###############################################################################

subtest 'add_item: rejects undef timestamp' => sub {
    my $ne = Net::Nostr::Negentropy->new;
    like(dies { $ne->add_item(undef, 'aa' x 32) },
        qr/timestamp/, 'undef timestamp rejected');
};

subtest 'add_item: rejects negative timestamp' => sub {
    my $ne = Net::Nostr::Negentropy->new;
    like(dies { $ne->add_item(-1, 'aa' x 32) },
        qr/timestamp/, 'negative timestamp rejected');
};

subtest 'add_item: rejects non-integer timestamp' => sub {
    my $ne = Net::Nostr::Negentropy->new;
    like(dies { $ne->add_item(1.5, 'aa' x 32) },
        qr/timestamp/, 'float timestamp rejected');
};

subtest 'add_item: rejects infinity timestamp' => sub {
    my $ne = Net::Nostr::Negentropy->new;
    like(dies { $ne->add_item(~0, 'aa' x 32) },
        qr/infinity/i, 'infinity timestamp rejected');
};

subtest 'add_item: accepts zero timestamp' => sub {
    my $ne = Net::Nostr::Negentropy->new;
    ok(lives { $ne->add_item(0, 'aa' x 32) }, 'zero timestamp accepted');
};

subtest 'add_item: rejects undef id' => sub {
    my $ne = Net::Nostr::Negentropy->new;
    like(dies { $ne->add_item(1000, undef) },
        qr/id/, 'undef id rejected');
};

subtest 'add_item: rejects short hex id' => sub {
    my $ne = Net::Nostr::Negentropy->new;
    like(dies { $ne->add_item(1000, 'aa' x 31) },
        qr/id/, 'short id rejected');
};

subtest 'add_item: rejects uppercase hex id' => sub {
    my $ne = Net::Nostr::Negentropy->new;
    like(dies { $ne->add_item(1000, 'AA' x 32) },
        qr/id/, 'uppercase id rejected');
};

subtest 'add_item: rejects non-hex id' => sub {
    my $ne = Net::Nostr::Negentropy->new;
    like(dies { $ne->add_item(1000, 'zz' x 32) },
        qr/id/, 'non-hex id rejected');
};

subtest 'add_item: rejects adding after seal' => sub {
    my $ne = Net::Nostr::Negentropy->new;
    $ne->seal;
    like(dies { $ne->add_item(1000, 'aa' x 32) },
        qr/sealed/, 'add after seal rejected');
};

###############################################################################
# seal
###############################################################################

subtest 'seal: empty set is valid' => sub {
    my $ne = Net::Nostr::Negentropy->new;
    ok(lives { $ne->seal }, 'empty seal succeeds');
};

subtest 'seal: preserves sort order by timestamp then id' => sub {
    my $ne = Net::Nostr::Negentropy->new;
    # Add out of order; same timestamp, different ids
    $ne->add_item(1000, 'bb' x 32);
    $ne->add_item(1000, 'aa' x 32);
    $ne->add_item(500, 'cc' x 32);
    $ne->seal;
    # Verify by initiating — if sort is wrong, reconciliation will differ
    my $msg = $ne->initiate;
    ok(defined $msg, 'initiate works after out-of-order add + seal');
};

###############################################################################
# initiate: requires seal
###############################################################################

subtest 'initiate: rejects if not sealed' => sub {
    my $ne = Net::Nostr::Negentropy->new;
    $ne->add_item(1000, 'aa' x 32);
    like(dies { $ne->initiate }, qr/seal/, 'initiate before seal rejected');
};

###############################################################################
# reconcile: requires seal
###############################################################################

subtest 'reconcile: rejects if not sealed' => sub {
    my $ne = Net::Nostr::Negentropy->new;
    $ne->add_item(1000, 'aa' x 32);
    like(dies { $ne->reconcile('00') },
        qr/seal/, 'reconcile before seal rejected');
};

###############################################################################
# reconcile: malformed messages
###############################################################################

subtest 'reconcile: rejects empty message' => sub {
    my $ne = Net::Nostr::Negentropy->new;
    $ne->seal;
    like(dies { $ne->reconcile('') },
        qr/empty/i, 'empty message rejected');
};

subtest 'reconcile: rejects unsupported protocol version' => sub {
    my $ne = Net::Nostr::Negentropy->new;
    $ne->seal;
    # Version byte 0xff followed by minimal data
    like(dies { $ne->reconcile('ff') },
        qr/version/i, 'bad version rejected');
};

###############################################################################
# reconcile: protocol completion
###############################################################################

subtest 'reconcile: identical sets complete in one round' => sub {
    my $a = Net::Nostr::Negentropy->new;
    my $b = Net::Nostr::Negentropy->new;
    for my $i (1 .. 5) {
        my $id = sprintf('%02x', $i) x 32;
        $a->add_item($i * 100, $id);
        $b->add_item($i * 100, $id);
    }
    $a->seal;
    $b->seal;

    my $q = $a->initiate;
    my ($resp, $b_have, $b_need) = $b->reconcile($q);

    my ($q2, $a_have, $a_need) = $a->reconcile($resp);
    is $a_have, [], 'no extras on client';
    is $a_need, [], 'no missing on client';
    is $q2, undef, 'protocol complete (nil response)';
};

###############################################################################
# reconcile: large set (triggers fingerprint mode)
###############################################################################

subtest 'reconcile: large sets use fingerprint mode' => sub {
    my $client = Net::Nostr::Negentropy->new;
    my $server = Net::Nostr::Negentropy->new;

    # 100 shared items
    for my $i (1 .. 100) {
        my $id = sprintf('%064x', $i);
        $client->add_item($i, $id);
        $server->add_item($i, $id);
    }
    # 1 extra on each side
    my $client_extra = sprintf('%064x', 999);
    my $server_extra = sprintf('%064x', 998);
    $client->add_item(999, $client_extra);
    $server->add_item(998, $server_extra);

    $client->seal;
    $server->seal;

    my $q = $client->initiate;
    my ($a, $shave, $sneed) = $server->reconcile($q);
    ok(defined $a, 'server responds');

    # May need multiple rounds; accumulate have/need across them
    my (@all_have, @all_need);
    while (defined $a) {
        my ($next, $have, $need) = $client->reconcile($a);
        push @all_have, @$have;
        push @all_need, @$need;
        if (defined $next) {
            ($a, $shave, $sneed) = $server->reconcile($next);
        } else {
            last;
        }
    }
    is [sort @all_have], [$client_extra], 'client has its extra';
    is [sort @all_need], [$server_extra], 'client needs server extra';
};

done_testing;
