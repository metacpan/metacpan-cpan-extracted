use strictures 2;
use Test2::V0 -no_srand => 1;
use JSON ();

use lib 't/lib';
use TestFixtures qw(make_event make_key_from_hex);

use Net::Nostr::Zap qw(
    lud16_to_url
    encode_lnurl decode_lnurl
    bolt11_amount
    callback_url
    calculate_splits
);

my $JSON = JSON->new->utf8->canonical;

###############################################################################
# Spec example: Zap Request (Appendix A)
###############################################################################

subtest 'Appendix A: zap request from spec example' => sub {
    my $spec_request = make_event(
        id         => '30efed56a035b2549fcaeec0bf2c1595f9a9b3bb4b1a38abaf8ee9041c4b7d93',
        kind       => 9734,
        pubkey     => '97c70a44366a6535c145b333f973ea86dfdc2d7a99da618c40c64705ad98e322',
        created_at => 1679673265,
        content    => 'Zap!',
        tags       => [
            ['relays', 'wss://nostr-pub.wellorder.com', 'wss://anotherrelay.example.com'],
            ['amount', '21000'],
            ['lnurl', 'lnurl1dp68gurn8ghj7um5v93kketj9ehx2amn9uh8wetvdskkkmn0wahz7mrww4excup0dajx2mrv92x9xp'],
            ['p', '04c915daefee38317fa734444acee390a8269fe5810b2241e5e6dd343dfbecc9'],
            ['e', '9ae37aa68f48645127299e9453eb5d908a0cbb6058ff340d528ed4d37c8994fb'],
            ['k', '1'],
        ],
        sig => 'f2cb581a84ed10e4dc84937bd98e27acac71ab057255f6aa8dfa561808c981fe8870f4a03c1e3666784d82a9c802d3704e174371aa13d63e2aeaf24ff5374d9d',
    );

    my $zap = Net::Nostr::Zap->request_from_event($spec_request);
    is $zap->p, '04c915daefee38317fa734444acee390a8269fe5810b2241e5e6dd343dfbecc9',
        'p tag is recipient pubkey';
    is $zap->relays, ['wss://nostr-pub.wellorder.com', 'wss://anotherrelay.example.com'],
        'relays parsed correctly';
    is $zap->amount, '21000', 'amount is 21000 millisats';
    is $zap->lnurl, 'lnurl1dp68gurn8ghj7um5v93kketj9ehx2amn9uh8wetvdskkkmn0wahz7mrww4excup0dajx2mrv92x9xp',
        'lnurl tag preserved';
    is $zap->e, '9ae37aa68f48645127299e9453eb5d908a0cbb6058ff340d528ed4d37c8994fb',
        'e tag is zapped event id';
    is $zap->k, '1', 'k tag is target event kind';
    is $zap->content, 'Zap!', 'content is zap message';
};

###############################################################################
# Spec example: Zap Receipt (Appendix E)
###############################################################################

subtest 'Appendix E: zap receipt from spec example' => sub {
    my $description_json = '{"pubkey":"97c70a44366a6535c145b333f973ea86dfdc2d7a99da618c40c64705ad98e322","content":"","id":"d9cc14d50fcb8c27539aacf776882942c1a11ea4472f8cdec1dea82fab66279d","created_at":1674164539,"sig":"77127f636577e9029276be060332ea565deaf89ff215a494ccff16ae3f757065e2bc59b2e8c113dd407917a010b3abd36c8d7ad84c0e3ab7dab3a0b0caa9835d","kind":9734,"tags":[["e","3624762a1274dd9636e0c552b53086d70bc88c165bc4dc0f9e836a1eaf86c3b8"],["p","32e1827635450ebb3c5a7d12c1f8e7b2b514439ac10a67eef3d9fd9c5c68e245"],["relays","wss://relay.damus.io","wss://nostr-relay.wlvs.space","wss://nostr.fmt.wiz.biz","wss://relay.nostr.bg","wss://nostr.oxtr.dev","wss://nostr.v0l.io","wss://brb.io","wss://nostr.bitcoiner.social","ws://monad.jb55.com:8080","wss://relay.snort.social"]]}';

    my $bolt11 = 'lnbc10u1p3unwfusp5t9r3yymhpfqculx78u027lxspgxcr2n2987mx2j55nnfs95nxnzqpp5jmrh92pfld78spqs78v9euf2385t83uvpwk9ldrlvf6ch7tpascqhp5zvkrmemgth3tufcvflmzjzfvjt023nazlhljz2n9hattj4f8jq8qxqyjw5qcqpjrzjqtc4fc44feggv7065fqe5m4ytjarg3repr5j9el35xhmtfexc42yczarjuqqfzqqqqqqqqlgqqqqqqgq9q9qxpqysgq079nkq507a5tw7xgttmj4u990j7wfggtrasah5gd4ywfr2pjcn29383tphp4t48gquelz9z78p4cq7ml3nrrphw5w6eckhjwmhezhnqpy6gyf0';

    my $spec_receipt = make_event(
        id         => '67b48a14fb66c60c8f9070bdeb37afdfcc3d08ad01989460448e4081eddda446',
        kind       => 9735,
        pubkey     => '9630f464cca6a5147aa8a35f0bcdd3ce485324e732fd39e09233b1d848238f31',
        created_at => 1674164545,
        content    => '',
        tags       => [
            ['p', '32e1827635450ebb3c5a7d12c1f8e7b2b514439ac10a67eef3d9fd9c5c68e245'],
            ['P', '97c70a44366a6535c145b333f973ea86dfdc2d7a99da618c40c64705ad98e322'],
            ['e', '3624762a1274dd9636e0c552b53086d70bc88c165bc4dc0f9e836a1eaf86c3b8'],
            ['k', '1'],
            ['bolt11', $bolt11],
            ['description', $description_json],
            ['preimage', '5d006d2cf1e73c7148e7519a4c68adc81642ce0e25a432b2434c99f97344c15f'],
        ],
        sig => 'a' x 128,
    );

    my $zap = Net::Nostr::Zap->receipt_from_event($spec_receipt);
    is $zap->p, '32e1827635450ebb3c5a7d12c1f8e7b2b514439ac10a67eef3d9fd9c5c68e245',
        'p tag is zap recipient';
    is $zap->sender, '97c70a44366a6535c145b333f973ea86dfdc2d7a99da618c40c64705ad98e322',
        'P tag is zap sender';
    is $zap->e, '3624762a1274dd9636e0c552b53086d70bc88c165bc4dc0f9e836a1eaf86c3b8',
        'e tag from zap request';
    is $zap->k, '1', 'k tag from zap request';
    is $zap->bolt11, $bolt11, 'bolt11 invoice preserved';
    is $zap->description, $description_json, 'description is JSON-encoded zap request';
    is $zap->preimage, '5d006d2cf1e73c7148e7519a4c68adc81642ce0e25a432b2434c99f97344c15f',
        'preimage tag preserved';
    is $zap->content, '', 'content is empty';

    # Extract the embedded zap request
    my $embedded = $zap->zap_request;
    isa_ok $embedded, 'Net::Nostr::Event';
    is $embedded->kind, 9734, 'embedded zap request is kind 9734';
    is $embedded->pubkey, '97c70a44366a6535c145b333f973ea86dfdc2d7a99da618c40c64705ad98e322',
        'embedded request pubkey is the sender';
};

###############################################################################
# Zap Request creation (Appendix A)
###############################################################################

subtest 'zap request creation' => sub {
    my $key = make_key_from_hex('a' x 64);

    # MUST have p tag
    my $zap = Net::Nostr::Zap->new_request(
        p      => 'b' x 64,
        relays => ['wss://relay.example.com'],
    );
    my $event = $zap->to_event(pubkey => $key->pubkey_hex);
    is $event->kind, 9734, 'zap request is kind 9734';

    # Check required tags
    my %tags;
    for my $tag (@{$event->tags}) {
        $tags{$tag->[0]} //= [];
        push @{$tags{$tag->[0]}}, $tag;
    }
    ok $tags{p}, 'has p tag';
    is $tags{p}[0][1], 'b' x 64, 'p tag value is recipient pubkey';
    ok $tags{relays}, 'has relays tag';
    is $tags{relays}[0][1], 'wss://relay.example.com',
        'relays tag contains relay URLs (not nested)';
};

subtest 'zap request with all optional fields' => sub {
    my $zap = Net::Nostr::Zap->new_request(
        p       => 'b' x 64,
        relays  => ['wss://relay1.com', 'wss://relay2.com'],
        amount  => '21000',
        lnurl   => 'lnurl1abc',
        e       => 'c' x 64,
        a       => '30023:' . ('b' x 64) . ':my-article',
        k       => '1',
        content => 'Great post!',
    );
    my $event = $zap->to_event(pubkey => 'a' x 64);

    is $event->kind, 9734, 'kind is 9734';
    is $event->content, 'Great post!', 'content is zap message';

    my %tags;
    for my $tag (@{$event->tags}) {
        $tags{$tag->[0]} //= [];
        push @{$tags{$tag->[0]}}, $tag;
    }

    is scalar @{$tags{relays}[0]}, 3, 'relays tag has 2 URLs (not nested)';
    is $tags{relays}[0][1], 'wss://relay1.com', 'first relay';
    is $tags{relays}[0][2], 'wss://relay2.com', 'second relay';
    is $tags{amount}[0][1], '21000', 'amount in millisats';
    is $tags{lnurl}[0][1], 'lnurl1abc', 'lnurl tag';
    is $tags{e}[0][1], 'c' x 64, 'e tag';
    is $tags{a}[0][1], '30023:' . ('b' x 64) . ':my-article', 'a tag';
    is $tags{k}[0][1], '1', 'k tag';
};

subtest 'zap request content MAY be empty' => sub {
    my $zap = Net::Nostr::Zap->new_request(
        p      => 'b' x 64,
        relays => ['wss://relay.example.com'],
    );
    my $event = $zap->to_event(pubkey => 'a' x 64);
    is $event->content, '', 'default content is empty string';
};

subtest 'zap request requires p tag' => sub {
    like dies {
        Net::Nostr::Zap->new_request(relays => ['wss://relay.example.com']);
    }, qr/p.*required/i, 'p tag is required';
};

subtest 'zap request requires relays tag' => sub {
    like dies {
        Net::Nostr::Zap->new_request(p => 'b' x 64);
    }, qr/relays.*required/i, 'relays is required';
};

###############################################################################
# Zap Request round-trip
###############################################################################

subtest 'zap request round-trip' => sub {
    my $zap = Net::Nostr::Zap->new_request(
        p       => 'b' x 64,
        relays  => ['wss://r1.com', 'wss://r2.com'],
        amount  => '42000',
        lnurl   => 'lnurl1test',
        e       => 'c' x 64,
        a       => '30023:' . ('b' x 64) . ':slug',
        k       => '30023',
        content => 'tip!',
    );
    my $event = $zap->to_event(pubkey => 'a' x 64);

    my $parsed = Net::Nostr::Zap->request_from_event($event);
    is $parsed->p, 'b' x 64, 'p round-trips';
    is $parsed->relays, ['wss://r1.com', 'wss://r2.com'], 'relays round-trip';
    is $parsed->amount, '42000', 'amount round-trips';
    is $parsed->lnurl, 'lnurl1test', 'lnurl round-trips';
    is $parsed->e, 'c' x 64, 'e round-trips';
    is $parsed->a, '30023:' . ('b' x 64) . ':slug', 'a round-trips';
    is $parsed->k, '30023', 'k round-trips';
    is $parsed->content, 'tip!', 'content round-trips';
};

###############################################################################
# Zap Receipt creation (Appendix E)
###############################################################################

subtest 'zap receipt creation' => sub {
    my $description_json = $JSON->encode({
        kind       => 9734,
        pubkey     => 'a' x 64,
        content    => '',
        created_at => 1000000,
        tags       => [['p', 'b' x 64], ['relays', 'wss://r.com']],
        id         => 'f' x 64,
        sig        => 'e' x 128,
    });

    my $zap = Net::Nostr::Zap->new_receipt(
        p           => 'b' x 64,
        bolt11      => 'lnbc1test',
        description => $description_json,
    );
    my $event = $zap->to_event(pubkey => 'd' x 64);

    is $event->kind, 9735, 'zap receipt is kind 9735';
    is $event->content, '', 'content SHOULD be empty';

    my %tags;
    for my $tag (@{$event->tags}) {
        $tags{$tag->[0]} //= [];
        push @{$tags{$tag->[0]}}, $tag;
    }

    ok $tags{p}, 'has p tag';
    ok $tags{bolt11}, 'has bolt11 tag';
    ok $tags{description}, 'has description tag';
    is $tags{description}[0][1], $description_json, 'description is JSON zap request';
};

subtest 'zap receipt with all optional fields' => sub {
    my $description_json = '{"kind":9734}';

    my $zap = Net::Nostr::Zap->new_receipt(
        p           => 'b' x 64,
        bolt11      => 'lnbc1test',
        description => $description_json,
        e           => 'c' x 64,
        a           => '30023:' . ('b' x 64) . ':post',
        sender      => 'a' x 64,
        preimage    => 'f' x 64,
        k           => '1',
    );
    my $event = $zap->to_event(pubkey => 'd' x 64, created_at => 1674164545);

    my %tags;
    for my $tag (@{$event->tags}) {
        my $key = $tag->[0];
        $tags{$key} //= [];
        push @{$tags{$key}}, $tag;
    }

    is $tags{p}[0][1], 'b' x 64, 'p tag';
    is $tags{P}[0][1], 'a' x 64, 'P tag (sender)';
    is $tags{e}[0][1], 'c' x 64, 'e tag';
    is $tags{a}[0][1], '30023:' . ('b' x 64) . ':post', 'a tag';
    is $tags{k}[0][1], '1', 'k tag';
    is $tags{bolt11}[0][1], 'lnbc1test', 'bolt11 tag';
    is $tags{preimage}[0][1], 'f' x 64, 'preimage tag';
};

subtest 'zap receipt requires p, bolt11, description' => sub {
    like dies {
        Net::Nostr::Zap->new_receipt(bolt11 => 'x', description => 'y');
    }, qr/p.*required/i, 'p is required';

    like dies {
        Net::Nostr::Zap->new_receipt(p => 'b' x 64, description => 'y');
    }, qr/bolt11.*required/i, 'bolt11 is required';

    like dies {
        Net::Nostr::Zap->new_receipt(p => 'b' x 64, bolt11 => 'x');
    }, qr/description.*required/i, 'description is required';
};

###############################################################################
# Zap Receipt round-trip
###############################################################################

subtest 'zap receipt round-trip' => sub {
    my $zap = Net::Nostr::Zap->new_receipt(
        p           => 'b' x 64,
        bolt11      => 'lnbc10u1test',
        description => '{"kind":9734}',
        e           => 'c' x 64,
        a           => '30023:' . ('b' x 64) . ':test',
        sender      => 'a' x 64,
        preimage    => 'f' x 64,
        k           => '1',
    );
    my $event = $zap->to_event(pubkey => 'd' x 64);
    my $parsed = Net::Nostr::Zap->receipt_from_event($event);

    is $parsed->p, 'b' x 64, 'p round-trips';
    is $parsed->bolt11, 'lnbc10u1test', 'bolt11 round-trips';
    is $parsed->description, '{"kind":9734}', 'description round-trips';
    is $parsed->e, 'c' x 64, 'e round-trips';
    is $parsed->a, '30023:' . ('b' x 64) . ':test', 'a round-trips';
    is $parsed->sender, 'a' x 64, 'sender (P) round-trips';
    is $parsed->preimage, 'f' x 64, 'preimage round-trips';
    is $parsed->k, '1', 'k round-trips';
};

###############################################################################
# zap_request() extracts embedded request from receipt
###############################################################################

subtest 'zap_request() parses description into Event' => sub {
    my $req_json = $JSON->encode({
        kind       => 9734,
        pubkey     => 'a' x 64,
        content    => 'test zap',
        created_at => 1000000,
        id         => 'f' x 64,
        sig        => 'e' x 128,
        tags       => [
            ['p', 'b' x 64],
            ['relays', 'wss://relay.test'],
            ['amount', '5000'],
        ],
    });

    my $zap = Net::Nostr::Zap->new_receipt(
        p           => 'b' x 64,
        bolt11      => 'lnbc1test',
        description => $req_json,
    );
    my $embedded = $zap->zap_request;
    isa_ok $embedded, 'Net::Nostr::Event';
    is $embedded->kind, 9734, 'kind is 9734';
    is $embedded->content, 'test zap', 'content preserved';
    is $embedded->pubkey, 'a' x 64, 'pubkey is the sender';
};

###############################################################################
# Appendix D: Zap Request Validation
###############################################################################

subtest 'Appendix D: validate_request - valid request' => sub {
    my $key = make_key_from_hex('a' x 64);
    my $zap = Net::Nostr::Zap->new_request(
        p      => 'b' x 64,
        relays => ['wss://relay.com'],
        amount => '21000',
    );
    my $event = $zap->to_event(pubkey => $key->pubkey_hex);
    $key->sign_event($event);
    ok lives { Net::Nostr::Zap->validate_request($event) }, 'valid request passes';
};

subtest 'Appendix D rule 1: MUST have valid nostr signature' => sub {
    my $event = make_event(
        kind       => 9734,
        pubkey     => 'a' x 64,
        content    => '',
        tags       => [['p', 'b' x 64], ['relays', 'wss://r.com']],
        sig        => '0' x 128,
    );
    like dies { Net::Nostr::Zap->validate_request($event) },
        qr/signature/i, 'invalid signature rejected';
};

subtest 'Appendix D rule 2: MUST have tags' => sub {
    my $key = make_key_from_hex('a' x 64);
    my $event = make_event(
        kind    => 9734,
        pubkey  => $key->pubkey_hex,
        content => '',
        tags    => [],
    );
    $key->sign_event($event);
    like dies { Net::Nostr::Zap->validate_request($event) },
        qr/tags/i, 'empty tags rejected';
};

subtest 'Appendix D rule 3: MUST have only one p tag' => sub {
    my $key = make_key_from_hex('a' x 64);

    # Zero p tags
    my $event0 = make_event(
        kind    => 9734,
        pubkey  => $key->pubkey_hex,
        content => '',
        tags    => [['relays', 'wss://r.com']],
    );
    $key->sign_event($event0);
    like dies { Net::Nostr::Zap->validate_request($event0) },
        qr/one p tag/i, 'zero p tags rejected';

    # Two p tags
    my $event2 = make_event(
        kind    => 9734,
        pubkey  => $key->pubkey_hex,
        content => '',
        tags    => [['p', 'b' x 64], ['p', 'c' x 64], ['relays', 'wss://r.com']],
    );
    $key->sign_event($event2);
    like dies { Net::Nostr::Zap->validate_request($event2) },
        qr/one p tag/i, 'two p tags rejected';
};

subtest 'Appendix D rule 4: MUST have 0 or 1 e tags' => sub {
    my $key = make_key_from_hex('a' x 64);
    my $event = make_event(
        kind    => 9734,
        pubkey  => $key->pubkey_hex,
        content => '',
        tags    => [
            ['p', 'b' x 64],
            ['relays', 'wss://r.com'],
            ['e', 'c' x 64],
            ['e', 'd' x 64],
        ],
    );
    $key->sign_event($event);
    like dies { Net::Nostr::Zap->validate_request($event) },
        qr/e tag/i, 'two e tags rejected';
};

subtest 'Appendix D rule 5: SHOULD have relays tag' => sub {
    my $key = make_key_from_hex('a' x 64);
    my $event = make_event(
        kind    => 9734,
        pubkey  => $key->pubkey_hex,
        content => '',
        tags    => [['p', 'b' x 64]],
    );
    $key->sign_event($event);
    # SHOULD = warning, not rejection - but still validates
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    ok lives { Net::Nostr::Zap->validate_request($event) },
        'missing relays is allowed (SHOULD)';
    ok grep({ /relays/i } @warnings), 'warns about missing relays';
};

subtest 'Appendix D rule 6: amount tag MUST equal amount query param' => sub {
    my $key = make_key_from_hex('a' x 64);
    my $event = make_event(
        kind    => 9734,
        pubkey  => $key->pubkey_hex,
        content => '',
        tags    => [
            ['p', 'b' x 64],
            ['relays', 'wss://r.com'],
            ['amount', '21000'],
        ],
    );
    $key->sign_event($event);

    like dies {
        Net::Nostr::Zap->validate_request($event, amount => 42000)
    }, qr/amount/i, 'mismatched amount rejected';

    ok lives {
        Net::Nostr::Zap->validate_request($event, amount => 21000)
    }, 'matching amount passes';

    # No amount query param means skip check
    ok lives {
        Net::Nostr::Zap->validate_request($event)
    }, 'no amount param skips check';
};

subtest 'Appendix D rule 7: a tag MUST be valid event coordinate' => sub {
    my $key = make_key_from_hex('a' x 64);
    my $event = make_event(
        kind    => 9734,
        pubkey  => $key->pubkey_hex,
        content => '',
        tags    => [
            ['p', 'b' x 64],
            ['relays', 'wss://r.com'],
            ['a', 'not-a-valid-coordinate'],
        ],
    );
    $key->sign_event($event);
    like dies { Net::Nostr::Zap->validate_request($event) },
        qr/coordinate/i, 'invalid a tag coordinate rejected';
};

subtest 'Appendix D rule 7: valid a tag passes' => sub {
    my $key = make_key_from_hex('a' x 64);
    my $event = make_event(
        kind    => 9734,
        pubkey  => $key->pubkey_hex,
        content => '',
        tags    => [
            ['p', 'b' x 64],
            ['relays', 'wss://r.com'],
            ['a', '30023:' . ('b' x 64) . ':my-article'],
        ],
    );
    $key->sign_event($event);
    ok lives { Net::Nostr::Zap->validate_request($event) },
        'valid a tag coordinate passes';
};

subtest 'Appendix D rule 8: MUST have 0 or 1 P tags' => sub {
    my $key = make_key_from_hex('a' x 64);
    my $event = make_event(
        kind    => 9734,
        pubkey  => $key->pubkey_hex,
        content => '',
        tags    => [
            ['p', 'b' x 64],
            ['relays', 'wss://r.com'],
            ['P', 'c' x 64],
            ['P', 'd' x 64],
        ],
    );
    $key->sign_event($event);
    like dies { Net::Nostr::Zap->validate_request($event) },
        qr/P tag/i, 'two P tags rejected';
};

subtest 'Appendix D: kind must be 9734' => sub {
    my $event = make_event(
        kind    => 1,
        pubkey  => 'a' x 64,
        content => '',
        tags    => [['p', 'b' x 64], ['relays', 'wss://r.com']],
        sig     => '0' x 128,
    );
    like dies { Net::Nostr::Zap->validate_request($event) },
        qr/9734/i, 'wrong kind rejected';
};

###############################################################################
# Appendix F: Zap Receipt Validation
###############################################################################

subtest 'Appendix F: validate_receipt - valid receipt' => sub {
    my $description_json = $JSON->encode({
        kind       => 9734,
        pubkey     => 'a' x 64,
        content    => '',
        created_at => 1000000,
        id         => 'f' x 64,
        sig        => 'e' x 128,
        tags       => [['p', 'b' x 64], ['relays', 'wss://r.com'], ['amount', '1000000']],
    });

    my $receipt_event = make_event(
        kind    => 9735,
        pubkey  => 'd' x 64,
        content => '',
        tags    => [
            ['p', 'b' x 64],
            ['bolt11', 'lnbc10u1test'],
            ['description', $description_json],
        ],
    );

    ok lives {
        Net::Nostr::Zap->validate_receipt($receipt_event,
            nostr_pubkey => 'd' x 64,
        )
    }, 'valid receipt passes';
};

subtest 'Appendix F: receipt pubkey MUST equal nostrPubkey' => sub {
    my $receipt_event = make_event(
        kind    => 9735,
        pubkey  => 'd' x 64,
        content => '',
        tags    => [
            ['p', 'b' x 64],
            ['bolt11', 'lnbc1test'],
            ['description', '{"kind":9734,"tags":[["p","' . ('b' x 64) . '"]]}'],
        ],
    );

    like dies {
        Net::Nostr::Zap->validate_receipt($receipt_event,
            nostr_pubkey => 'e' x 64,
        )
    }, qr/pubkey/i, 'mismatched nostrPubkey rejected';
};

subtest 'Appendix F: invoiceAmount MUST equal zap request amount' => sub {
    # bolt11 lnbc10u = 10 micro BTC = 1,000,000 millisats
    my $description_json = $JSON->encode({
        kind       => 9734,
        pubkey     => 'a' x 64,
        content    => '',
        created_at => 1000000,
        id         => 'f' x 64,
        sig        => 'e' x 128,
        tags       => [['p', 'b' x 64], ['relays', 'wss://r.com'], ['amount', '999']],
    });

    my $receipt_event = make_event(
        kind    => 9735,
        pubkey  => 'd' x 64,
        content => '',
        tags    => [
            ['p', 'b' x 64],
            ['bolt11', 'lnbc10u1test'],
            ['description', $description_json],
        ],
    );

    like dies {
        Net::Nostr::Zap->validate_receipt($receipt_event,
            nostr_pubkey => 'd' x 64,
        )
    }, qr/amount/i, 'bolt11 amount mismatch with zap request amount rejected';
};

subtest 'Appendix F: kind must be 9735' => sub {
    my $event = make_event(
        kind    => 1,
        pubkey  => 'a' x 64,
        content => '',
        tags    => [['p', 'b' x 64]],
    );
    like dies { Net::Nostr::Zap->validate_receipt($event, nostr_pubkey => 'a' x 64) },
        qr/9735/i, 'wrong kind rejected';
};

subtest 'Appendix F: receipt MUST have bolt11 tag' => sub {
    my $event = make_event(
        kind    => 9735,
        pubkey  => 'd' x 64,
        content => '',
        tags    => [
            ['p', 'b' x 64],
            ['description', '{"kind":9734,"tags":[["p","' . ('b' x 64) . '"]]}'],
        ],
    );
    like dies {
        Net::Nostr::Zap->validate_receipt($event, nostr_pubkey => 'd' x 64)
    }, qr/bolt11/i, 'missing bolt11 rejected';
};

subtest 'Appendix F: receipt MUST have description tag' => sub {
    my $event = make_event(
        kind    => 9735,
        pubkey  => 'd' x 64,
        content => '',
        tags    => [
            ['p', 'b' x 64],
            ['bolt11', 'lnbc1test'],
        ],
    );
    like dies {
        Net::Nostr::Zap->validate_receipt($event, nostr_pubkey => 'd' x 64)
    }, qr/description/i, 'missing description rejected';
};

subtest 'Appendix F: receipt MUST have p tag' => sub {
    my $event = make_event(
        kind    => 9735,
        pubkey  => 'd' x 64,
        content => '',
        tags    => [
            ['bolt11', 'lnbc1test'],
            ['description', '{"kind":9734,"tags":[]}'],
        ],
    );
    like dies {
        Net::Nostr::Zap->validate_receipt($event, nostr_pubkey => 'd' x 64)
    }, qr/p tag/i, 'missing p tag rejected';
};

###############################################################################
# lud16_to_url
###############################################################################

subtest 'lud16_to_url converts lightning address to LNURL pay endpoint' => sub {
    is lud16_to_url('alice@example.com'),
        'https://example.com/.well-known/lnurlp/alice',
        'basic lightning address';
    is lud16_to_url('bob@pay.domain.org'),
        'https://pay.domain.org/.well-known/lnurlp/bob',
        'subdomain lightning address';
};

subtest 'lud16_to_url rejects invalid addresses' => sub {
    like dies { lud16_to_url('noatsign') }, qr/invalid/i, 'no @ rejected';
    like dies { lud16_to_url('') }, qr/invalid/i, 'empty rejected';
    like dies { lud16_to_url(undef) }, qr/invalid/i, 'undef rejected';
};

###############################################################################
# LNURL encode/decode
###############################################################################

subtest 'lnurl encode/decode round-trip' => sub {
    my $url = 'https://example.com/.well-known/lnurlp/user';
    my $encoded = encode_lnurl($url);
    like $encoded, qr/^lnurl1/, 'encoded starts with lnurl1';
    is decode_lnurl($encoded), $url, 'round-trips correctly';
};

subtest 'decode_lnurl rejects wrong prefix' => sub {
    like dies { decode_lnurl('npub1abc') }, qr/lnurl/i, 'wrong prefix rejected';
};

###############################################################################
# bolt11_amount (Appendix F validation needs this)
###############################################################################

subtest 'bolt11_amount parses invoice amounts' => sub {
    # Multiplier: m = milli (10^-3 BTC), u = micro (10^-6), n = nano (10^-9), p = pico (10^-12)
    # 1 BTC = 100_000_000_000 millisats

    is bolt11_amount('lnbc10u1p3unwfu'), 1_000_000,
        '10u = 10 micro BTC = 1,000,000 millisats';
    is bolt11_amount('lnbc1m1test'), 100_000_000,
        '1m = 1 milli BTC = 100,000,000 millisats';
    is bolt11_amount('lnbc20m1test'), 2_000_000_000,
        '20m = 20 milli BTC = 2,000,000,000 millisats';
    is bolt11_amount('lnbc1500n1test'), 150_000,
        '1500n = 1500 nano BTC = 150,000 millisats';
    is bolt11_amount('lnbc10n1test'), 1_000,
        '10n = 10 nano BTC = 1,000 millisats';
    is bolt11_amount('lnbc1p1test'), 0,
        '1p = 0.1 millisats truncates to 0 (sub-millisat)';
    is bolt11_amount('lnbc10p1test'), 1,
        '10p = 10 pico BTC = 1 millisat';
    is bolt11_amount('lnbc2500u1test'), 250_000_000,
        '2500u = 250,000,000 millisats';
    is bolt11_amount('lnbc11test'), 100_000_000_000,
        '1 BTC = 100,000,000,000 millisats';
};

subtest 'bolt11_amount handles testnet' => sub {
    is bolt11_amount('lntb10u1test'), 1_000_000,
        'testnet invoice';
    is bolt11_amount('lnbcrt10u1test'), 1_000_000,
        'regtest invoice';
};

subtest 'bolt11_amount returns undef for no amount' => sub {
    is bolt11_amount('lnbc1test'), undef,
        'no amount returns undef';
};

subtest 'bolt11_amount rejects invalid invoice' => sub {
    like dies { bolt11_amount('notaninvoice') }, qr/bolt11/i, 'invalid format';
};

###############################################################################
# callback_url (Appendix B)
###############################################################################

subtest 'Appendix B: callback_url constructs GET URL' => sub {
    my $event = make_event(
        kind    => 9734,
        pubkey  => 'a' x 64,
        content => '',
        tags    => [['p', 'b' x 64], ['relays', 'wss://r.com']],
    );

    my $url = callback_url(
        'https://lnurl.example.com/callback',
        amount => 21000,
        nostr  => $event,
        lnurl  => 'lnurl1test',
    );

    like $url, qr{^https://lnurl\.example\.com/callback\?}, 'base URL';
    like $url, qr{amount=21000}, 'amount param';
    like $url, qr{lnurl=lnurl1test}, 'lnurl param';
    like $url, qr{nostr=}, 'nostr param present';

    # The nostr param should be URI-encoded JSON of the event
    my ($nostr_param) = $url =~ /nostr=([^&]+)/;
    (my $decoded = $nostr_param) =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
    my $parsed = JSON->new->utf8->decode($decoded);
    is $parsed->{kind}, 9734, 'nostr param is the zap request event JSON';
};

###############################################################################
# calculate_splits (Appendix G)
###############################################################################

subtest 'Appendix G: calculate_splits with weights' => sub {
    my @tags = (
        ['zap', '82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2', 'wss://nostr.oxtr.dev', '1'],
        ['zap', 'fa984bd7dbb282f07e16e7ae87b26a2a7b9b90b7246a44771f0cf5ae58018f52', 'wss://nostr.wine/', '1'],
        ['zap', '460c25e682fda7832b52d1f22d3d22b3176d972f60dcdc3212ed8c92ef85065c', 'wss://nos.lol/', '2'],
    );

    my @splits = calculate_splits(@tags);
    is scalar @splits, 3, 'three recipients';

    # First: weight 1 / total 4 = 0.25
    is $splits[0]{pubkey}, '82341f882b6eabcd2ba7f1ef90aad961cf074af15b9ef44a09f9d2a8fbfbe6a2', 'first pubkey';
    is $splits[0]{relay}, 'wss://nostr.oxtr.dev', 'first relay';
    ok abs($splits[0]{percentage} - 25.0) < 0.01, 'first gets 25%';

    # Second: weight 1 / total 4 = 0.25
    ok abs($splits[1]{percentage} - 25.0) < 0.01, 'second gets 25%';

    # Third: weight 2 / total 4 = 0.50
    ok abs($splits[2]{percentage} - 50.0) < 0.01, 'third gets 50%';
};

subtest 'Appendix G: calculate_splits without weights - equal split' => sub {
    my @tags = (
        ['zap', 'a' x 64, 'wss://r1.com'],
        ['zap', 'b' x 64, 'wss://r2.com'],
    );

    my @splits = calculate_splits(@tags);
    is scalar @splits, 2, 'two recipients';
    ok abs($splits[0]{percentage} - 50.0) < 0.01, 'equal split 50%';
    ok abs($splits[1]{percentage} - 50.0) < 0.01, 'equal split 50%';
};

subtest 'Appendix G: partial weights - missing weight gets 0' => sub {
    my @tags = (
        ['zap', 'a' x 64, 'wss://r1.com', '3'],
        ['zap', 'b' x 64, 'wss://r2.com'],         # no weight
        ['zap', 'c' x 64, 'wss://r3.com', '1'],
    );

    my @splits = calculate_splits(@tags);
    is scalar @splits, 3, 'three recipients';
    ok abs($splits[0]{percentage} - 75.0) < 0.01, 'weighted gets 75%';
    ok abs($splits[1]{percentage} - 0.0) < 0.01, 'missing weight gets 0%';
    ok abs($splits[2]{percentage} - 25.0) < 0.01, 'weighted gets 25%';
};

subtest 'Appendix G: empty zap tags' => sub {
    my @splits = calculate_splits();
    is scalar @splits, 0, 'no tags = no splits';
};

subtest 'Appendix G: all zero weights' => sub {
    my @tags = (
        ['zap', 'a' x 64, 'wss://r1.com', '0'],
        ['zap', 'b' x 64, 'wss://r2.com', '0'],
    );
    my @splits = calculate_splits(@tags);
    ok abs($splits[0]{percentage} - 0.0) < 0.01, 'zero weight gets 0%';
    ok abs($splits[1]{percentage} - 0.0) < 0.01, 'zero weight gets 0%';
};

###############################################################################
# Negative tests
###############################################################################

subtest 'request_from_event rejects non-9734 events' => sub {
    my $event = make_event(kind => 1, pubkey => 'a' x 64, content => '', tags => []);
    like dies { Net::Nostr::Zap->request_from_event($event) },
        qr/9734/, 'wrong kind rejected';
};

subtest 'receipt_from_event rejects non-9735 events' => sub {
    my $event = make_event(kind => 1, pubkey => 'a' x 64, content => '', tags => []);
    like dies { Net::Nostr::Zap->receipt_from_event($event) },
        qr/9735/, 'wrong kind rejected';
};

subtest 'zap request amount must be string of millisats' => sub {
    my $zap = Net::Nostr::Zap->new_request(
        p      => 'b' x 64,
        relays => ['wss://r.com'],
        amount => '21000',
    );
    my $event = $zap->to_event(pubkey => 'a' x 64);
    my %tags;
    for my $tag (@{$event->tags}) {
        $tags{$tag->[0]} //= $tag;
    }
    like $tags{amount}[1], qr/^\d+$/, 'amount is numeric string';
};

###############################################################################
# MAY behaviors with defaults
###############################################################################

subtest 'MAY: zap request e tag is optional' => sub {
    my $zap = Net::Nostr::Zap->new_request(
        p      => 'b' x 64,
        relays => ['wss://r.com'],
    );
    is $zap->e, undef, 'e is undef by default';
    my $event = $zap->to_event(pubkey => 'a' x 64);
    my @e_tags = grep { $_->[0] eq 'e' } @{$event->tags};
    is scalar @e_tags, 0, 'no e tag in event when not set';
};

subtest 'MAY: zap request a tag is optional' => sub {
    my $zap = Net::Nostr::Zap->new_request(
        p      => 'b' x 64,
        relays => ['wss://r.com'],
    );
    is $zap->a, undef, 'a is undef by default';
};

subtest 'MAY: zap request k tag is optional' => sub {
    my $zap = Net::Nostr::Zap->new_request(
        p      => 'b' x 64,
        relays => ['wss://r.com'],
    );
    is $zap->k, undef, 'k is undef by default';
};

subtest 'MAY: zap request amount is recommended but optional' => sub {
    my $zap = Net::Nostr::Zap->new_request(
        p      => 'b' x 64,
        relays => ['wss://r.com'],
    );
    is $zap->amount, undef, 'amount is undef by default';
    my $event = $zap->to_event(pubkey => 'a' x 64);
    my @amount_tags = grep { $_->[0] eq 'amount' } @{$event->tags};
    is scalar @amount_tags, 0, 'no amount tag when not set';
};

subtest 'MAY: zap request lnurl is recommended but optional' => sub {
    my $zap = Net::Nostr::Zap->new_request(
        p      => 'b' x 64,
        relays => ['wss://r.com'],
    );
    is $zap->lnurl, undef, 'lnurl is undef by default';
};

subtest 'MAY: zap receipt preimage is optional' => sub {
    my $zap = Net::Nostr::Zap->new_receipt(
        p           => 'b' x 64,
        bolt11      => 'lnbc1test',
        description => '{"kind":9734}',
    );
    is $zap->preimage, undef, 'preimage is undef by default';
};

subtest 'MAY: zap receipt sender (P tag) is optional' => sub {
    my $zap = Net::Nostr::Zap->new_receipt(
        p           => 'b' x 64,
        bolt11      => 'lnbc1test',
        description => '{"kind":9734}',
    );
    is $zap->sender, undef, 'sender is undef by default';
    my $event = $zap->to_event(pubkey => 'd' x 64);
    my @P_tags = grep { $_->[0] eq 'P' } @{$event->tags};
    is scalar @P_tags, 0, 'no P tag when sender not set';
};

subtest 'MAY: client may pay invoice or pass to app' => sub {
    # This is a protocol-level MAY about client behavior.
    # We test that callback_url produces a valid URL that could be used either way.
    my $event = make_event(
        kind    => 9734,
        pubkey  => 'a' x 64,
        content => '',
        tags    => [['p', 'b' x 64], ['relays', 'wss://r.com']],
    );
    my $url = callback_url('https://cb.test/pay', amount => 1000, nostr => $event);
    like $url, qr{^https://cb\.test/pay\?}, 'callback URL is well-formed';
};

###############################################################################
# Additional coverage: positive validation cases
###############################################################################

subtest 'Appendix D rule 4: 1 e tag passes validation' => sub {
    my $key = make_key_from_hex('a' x 64);
    my $event = make_event(
        kind    => 9734,
        pubkey  => $key->pubkey_hex,
        content => '',
        tags    => [
            ['p', 'b' x 64],
            ['relays', 'wss://r.com'],
            ['e', 'c' x 64],
        ],
    );
    $key->sign_event($event);
    ok lives { Net::Nostr::Zap->validate_request($event) },
        'exactly 1 e tag passes';
};

subtest 'Appendix D rule 8: 1 P tag passes validation' => sub {
    my $key = make_key_from_hex('a' x 64);
    my $event = make_event(
        kind    => 9734,
        pubkey  => $key->pubkey_hex,
        content => '',
        tags    => [
            ['p', 'b' x 64],
            ['relays', 'wss://r.com'],
            ['P', 'd' x 64],
        ],
    );
    $key->sign_event($event);
    ok lives { Net::Nostr::Zap->validate_request($event) },
        '1 P tag passes';
};

subtest 'Appendix D rule 8: P tag value MUST equal receipt pubkey' => sub {
    my $key = make_key_from_hex('a' x 64);
    my $event = make_event(
        kind    => 9734,
        pubkey  => $key->pubkey_hex,
        content => '',
        tags    => [
            ['p', 'b' x 64],
            ['relays', 'wss://r.com'],
            ['P', 'c' x 64],
        ],
    );
    $key->sign_event($event);
    like dies {
        Net::Nostr::Zap->validate_request($event, receipt_pubkey => 'd' x 64)
    }, qr/P tag/i, 'P tag not matching receipt pubkey rejected';

    ok lives {
        Net::Nostr::Zap->validate_request($event, receipt_pubkey => 'c' x 64)
    }, 'P tag matching receipt pubkey passes';
};

###############################################################################
# Additional coverage: receipt carrying tags from request
###############################################################################

subtest 'Appendix E: receipt carries e/a/k tags from zap request' => sub {
    my $key = make_key_from_hex('a' x 64);
    my $req = Net::Nostr::Zap->new_request(
        p      => 'b' x 64,
        relays => ['wss://r.com'],
        e      => 'c' x 64,
        a      => '30023:' . ('b' x 64) . ':article',
        k      => '30023',
    );
    my $req_event = $req->to_event(pubkey => $key->pubkey_hex);
    $key->sign_event($req_event);
    my $req_json = $JSON->encode($req_event->to_hash);

    my $receipt = Net::Nostr::Zap->new_receipt(
        p           => 'b' x 64,
        bolt11      => 'lnbc1test',
        description => $req_json,
        sender      => $key->pubkey_hex,
        e           => 'c' x 64,
        a           => '30023:' . ('b' x 64) . ':article',
        k           => '30023',
    );
    my $receipt_event = $receipt->to_event(pubkey => 'd' x 64);

    my %tags;
    for my $tag (@{$receipt_event->tags}) {
        $tags{$tag->[0]} //= [];
        push @{$tags{$tag->[0]}}, $tag;
    }

    is $tags{e}[0][1], 'c' x 64, 'e tag carried from request';
    is $tags{a}[0][1], '30023:' . ('b' x 64) . ':article', 'a tag carried from request';
    is $tags{k}[0][1], '30023', 'k tag carried from request';
    is $tags{P}[0][1], $key->pubkey_hex, 'P tag is sender pubkey';
};

###############################################################################
# Additional coverage: validate_receipt edge cases
###############################################################################

subtest 'Appendix F: receipt valid when zap request has no amount tag' => sub {
    my $description_json = $JSON->encode({
        kind       => 9734,
        pubkey     => 'a' x 64,
        content    => '',
        created_at => 1000000,
        id         => 'f' x 64,
        sig        => 'e' x 128,
        tags       => [['p', 'b' x 64], ['relays', 'wss://r.com']],
    });

    my $receipt_event = make_event(
        kind    => 9735,
        pubkey  => 'd' x 64,
        content => '',
        tags    => [
            ['p', 'b' x 64],
            ['bolt11', 'lnbc10u1test'],
            ['description', $description_json],
        ],
    );

    ok lives {
        Net::Nostr::Zap->validate_receipt($receipt_event, nostr_pubkey => 'd' x 64)
    }, 'receipt valid when zap request has no amount';
};

subtest 'Appendix F: omitting nostr_pubkey skips pubkey check' => sub {
    my $receipt_event = make_event(
        kind    => 9735,
        pubkey  => 'd' x 64,
        content => '',
        tags    => [
            ['p', 'b' x 64],
            ['bolt11', 'lnbc1test'],
            ['description', '{"kind":9734,"tags":[["p","' . ('b' x 64) . '"]]}'],
        ],
    );

    ok lives {
        Net::Nostr::Zap->validate_receipt($receipt_event)
    }, 'validates without nostr_pubkey (skips pubkey check)';
};

###############################################################################
# Cross-NIP: NIP-01 filter for zap receipts
###############################################################################

subtest 'NIP-01 cross-NIP: filter for zap receipts by event' => sub {
    require Net::Nostr::Filter;
    my $filter = Net::Nostr::Filter->new(
        kinds => [9735],
        '#e'  => ['c' x 64],
    );

    my $matching = make_event(
        kind    => 9735,
        pubkey  => 'd' x 64,
        content => '',
        tags    => [
            ['p', 'b' x 64],
            ['e', 'c' x 64],
            ['bolt11', 'lnbc1test'],
            ['description', '{}'],
        ],
    );
    ok $filter->matches($matching), 'filter matches receipt with e tag';

    my $non_matching = make_event(
        kind    => 9735,
        pubkey  => 'd' x 64,
        content => '',
        tags    => [
            ['p', 'b' x 64],
            ['e', 'f' x 64],
            ['bolt11', 'lnbc1test'],
            ['description', '{}'],
        ],
    );
    ok !$filter->matches($non_matching), 'filter rejects receipt with different e tag';
};

###############################################################################
# POD example: encode_lnurl in new_request
###############################################################################

subtest 'POD example: encode_lnurl used in new_request' => sub {
    my $lnurl = encode_lnurl('https://example.com/.well-known/lnurlp/alice');
    my $zap = Net::Nostr::Zap->new_request(
        p      => 'b' x 64,
        relays => ['wss://relay.example.com'],
        amount => '21000',
        lnurl  => $lnurl,
    );
    my $event = $zap->to_event(pubkey => 'a' x 64);
    my ($lnurl_tag) = grep { $_->[0] eq 'lnurl' } @{$event->tags};
    like $lnurl_tag->[1], qr/^lnurl1/, 'lnurl tag is bech32 encoded';
    is decode_lnurl($lnurl_tag->[1]),
        'https://example.com/.well-known/lnurlp/alice',
        'decodes back to original URL';
};

###############################################################################
# Appendix E: created_at SHOULD be set to paid_at
###############################################################################

subtest 'Appendix E: created_at passed through to receipt event' => sub {
    my $paid_at = 1674164545;
    my $zap = Net::Nostr::Zap->new_receipt(
        p           => 'b' x 64,
        bolt11      => 'lnbc1test',
        description => '{"kind":9734}',
    );
    my $event = $zap->to_event(pubkey => 'd' x 64, created_at => $paid_at);
    is $event->created_at, $paid_at,
        'created_at set to paid_at for idempotency (SHOULD)';
};

###############################################################################
# Appendix F line 171: lnurl SHOULD match recipient's lnurl
###############################################################################

subtest 'Appendix F: lnurl in request SHOULD equal recipient lnurl' => sub {
    my $description_json = $JSON->encode({
        kind       => 9734,
        pubkey     => 'a' x 64,
        content    => '',
        created_at => 1000000,
        id         => 'f' x 64,
        sig        => 'e' x 128,
        tags       => [
            ['p', 'b' x 64],
            ['relays', 'wss://r.com'],
            ['lnurl', 'lnurl1match'],
        ],
    });

    my $receipt_event = make_event(
        kind    => 9735,
        pubkey  => 'd' x 64,
        content => '',
        tags    => [
            ['p', 'b' x 64],
            ['bolt11', 'lnbc1test'],
            ['description', $description_json],
        ],
    );

    # Matching lnurl - no warning
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    ok lives {
        Net::Nostr::Zap->validate_receipt($receipt_event,
            nostr_pubkey => 'd' x 64,
            lnurl        => 'lnurl1match',
        )
    }, 'matching lnurl passes';
    ok !grep({ /lnurl/i } @warnings), 'no lnurl warning when matching';

    # Mismatching lnurl - warns (SHOULD)
    @warnings = ();
    ok lives {
        Net::Nostr::Zap->validate_receipt($receipt_event,
            nostr_pubkey => 'd' x 64,
            lnurl        => 'lnurl1different',
        )
    }, 'mismatched lnurl still passes (SHOULD, not MUST)';
    ok grep({ /lnurl/i } @warnings), 'warns about lnurl mismatch';
};

###############################################################################
# Appendix A line 31: relays should not be nested
###############################################################################

subtest 'Appendix A: relays are flat, not nested' => sub {
    my $zap = Net::Nostr::Zap->new_request(
        p      => 'b' x 64,
        relays => ['wss://r1.com', 'wss://r2.com'],
    );
    my $event = $zap->to_event(pubkey => 'a' x 64);

    my ($relays_tag) = grep { $_->[0] eq 'relays' } @{$event->tags};
    for my $i (1 .. $#$relays_tag) {
        ok !ref($relays_tag->[$i]),
            "relay at position $i is a plain string, not nested";
    }
};

###############################################################################
# Appendix E line 137: SHA256(description) SHOULD match bolt11 desc hash
# Parsing bolt11 tagged data fields is beyond this library's scope.
# We verify the description is valid JSON suitable for hashing.
###############################################################################

subtest 'Appendix E: description is hashable JSON for bolt11 desc hash' => sub {
    my $req_json = $JSON->encode({
        kind       => 9734,
        pubkey     => 'a' x 64,
        content    => '',
        tags       => [['p', 'b' x 64]],
        created_at => 1000000,
        id         => 'f' x 64,
        sig        => 'e' x 128,
    });

    my $zap = Net::Nostr::Zap->new_receipt(
        p           => 'b' x 64,
        bolt11      => 'lnbc1test',
        description => $req_json,
    );
    my $event = $zap->to_event(pubkey => 'd' x 64);

    my ($desc_tag) = grep { $_->[0] eq 'description' } @{$event->tags};
    my $parsed = eval { JSON->new->utf8->decode($desc_tag->[1]) };
    ok $parsed, 'description tag is valid JSON';
    is $parsed->{kind}, 9734, 'description contains the zap request';

    require Digest::SHA;
    my $hash = Digest::SHA::sha256_hex($desc_tag->[1]);
    like $hash, qr/^[0-9a-f]{64}$/, 'SHA256(description) computable for bolt11 verification';
};

###############################################################################
# Appendix D rule 5: positive case - relays present = no warning
###############################################################################

subtest 'Appendix D rule 5: relays present produces no warning' => sub {
    my $key = make_key_from_hex('a' x 64);
    my $event = make_event(
        kind    => 9734,
        pubkey  => $key->pubkey_hex,
        content => '',
        tags    => [
            ['p', 'b' x 64],
            ['relays', 'wss://r.com'],
        ],
    );
    $key->sign_event($event);

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    ok lives { Net::Nostr::Zap->validate_request($event) },
        'request with relays passes';
    ok !grep({ /relays/i } @warnings), 'no relays warning when present';
};

###############################################################################
# Appendix G: malformed zap tags
###############################################################################

subtest 'Appendix G: malformed zap tag missing relay' => sub {
    my @tags = (
        ['zap', 'a' x 64],  # missing relay
    );
    my @splits = calculate_splits(@tags);
    is scalar @splits, 1, 'still produces a split';
    is $splits[0]{pubkey}, 'a' x 64, 'pubkey extracted';
    is $splits[0]{relay}, undef, 'relay is undef when missing';
};

subtest 'Appendix G: malformed zap tag missing pubkey' => sub {
    my @tags = (
        ['zap'],  # missing everything
    );
    my @splits = calculate_splits(@tags);
    is scalar @splits, 1, 'still produces a split';
    is $splits[0]{pubkey}, undef, 'pubkey is undef when missing';
};

done_testing;
