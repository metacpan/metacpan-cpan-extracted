#!/usr/bin/perl

# NIP-21: nostr: URI scheme
# https://github.com/nostr-protocol/nips/blob/master/21.md

use strictures 2;

use Test2::V0 -no_srand => 1;

use Net::Nostr::Bech32 qw(
    encode_npub encode_nsec encode_note
    encode_nprofile encode_nevent encode_naddr
    encode_nostr_uri decode_nostr_uri
);

my $PUBKEY  = '7e7e9c42a91bfef19fa929e5fda1b72e0ebc1a4c1141673e2794234d86addf4e';
my $PRIVKEY = '67dea2ed018072d675f5415ecfaed7d2597555e202d85b3d65ea4e58d2d92ffa';
my $EVENTID = '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d';

###############################################################################
# "The scheme is nostr:"
# "The identifiers that come after are expected to be the same as those
#  defined in NIP-19 (except nsec)"
###############################################################################

subtest 'encode_nostr_uri: npub' => sub {
    my $npub = encode_npub($PUBKEY);
    my $uri = encode_nostr_uri($npub);
    is($uri, "nostr:$npub", 'nostr: prefix prepended to npub');
};

subtest 'encode_nostr_uri: note' => sub {
    my $note = encode_note($EVENTID);
    my $uri = encode_nostr_uri($note);
    is($uri, "nostr:$note", 'nostr: prefix prepended to note');
};

subtest 'encode_nostr_uri: nprofile' => sub {
    my $nprofile = encode_nprofile(pubkey => $PUBKEY, relays => ['wss://relay.com']);
    my $uri = encode_nostr_uri($nprofile);
    is($uri, "nostr:$nprofile", 'nostr: prefix prepended to nprofile');
};

subtest 'encode_nostr_uri: nevent' => sub {
    my $nevent = encode_nevent(id => $EVENTID, relays => ['wss://relay.com']);
    my $uri = encode_nostr_uri($nevent);
    is($uri, "nostr:$nevent", 'nostr: prefix prepended to nevent');
};

subtest 'encode_nostr_uri: naddr' => sub {
    my $naddr = encode_naddr(
        identifier => 'my-article',
        pubkey     => $PUBKEY,
        kind       => 30023,
    );
    my $uri = encode_nostr_uri($naddr);
    is($uri, "nostr:$naddr", 'nostr: prefix prepended to naddr');
};

subtest 'encode_nostr_uri: rejects nsec' => sub {
    my $nsec = encode_nsec($PRIVKEY);
    like(
        dies { encode_nostr_uri($nsec) },
        qr/nsec/i,
        'nsec rejected in nostr: URI'
    );
};

subtest 'encode_nostr_uri: rejects invalid bech32 prefix' => sub {
    like(
        dies { encode_nostr_uri('bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4') },
        qr/unknown|unsupported|invalid/i,
        'non-nostr bech32 rejected'
    );
};

subtest 'encode_nostr_uri: rejects undef' => sub {
    like(
        dies { encode_nostr_uri(undef) },
        qr/./,
        'undef rejected'
    );
};

###############################################################################
# decode_nostr_uri
###############################################################################

subtest 'decode_nostr_uri: npub' => sub {
    my $npub = encode_npub($PUBKEY);
    my $result = decode_nostr_uri("nostr:$npub");
    is($result->{type}, 'npub', 'type is npub');
    is($result->{data}, $PUBKEY, 'data is hex pubkey');
};

subtest 'decode_nostr_uri: note' => sub {
    my $note = encode_note($EVENTID);
    my $result = decode_nostr_uri("nostr:$note");
    is($result->{type}, 'note', 'type is note');
    is($result->{data}, $EVENTID, 'data is hex event id');
};

subtest 'decode_nostr_uri: nprofile' => sub {
    my $nprofile = encode_nprofile(pubkey => $PUBKEY, relays => ['wss://relay.com']);
    my $result = decode_nostr_uri("nostr:$nprofile");
    is($result->{type}, 'nprofile', 'type is nprofile');
    is($result->{data}{pubkey}, $PUBKEY, 'pubkey decoded');
    is($result->{data}{relays}, ['wss://relay.com'], 'relays decoded');
};

subtest 'decode_nostr_uri: nevent' => sub {
    my $nevent = encode_nevent(id => $EVENTID, relays => ['wss://relay.com'], kind => 1);
    my $result = decode_nostr_uri("nostr:$nevent");
    is($result->{type}, 'nevent', 'type is nevent');
    is($result->{data}{id}, $EVENTID, 'id decoded');
    is($result->{data}{kind}, 1, 'kind decoded');
};

subtest 'decode_nostr_uri: naddr' => sub {
    my $naddr = encode_naddr(
        identifier => 'my-article',
        pubkey     => $PUBKEY,
        kind       => 30023,
    );
    my $result = decode_nostr_uri("nostr:$naddr");
    is($result->{type}, 'naddr', 'type is naddr');
    is($result->{data}{identifier}, 'my-article', 'identifier decoded');
    is($result->{data}{kind}, 30023, 'kind decoded');
};

subtest 'decode_nostr_uri: rejects nsec URI' => sub {
    my $nsec = encode_nsec($PRIVKEY);
    like(
        dies { decode_nostr_uri("nostr:$nsec") },
        qr/nsec/i,
        'nsec rejected in decode'
    );
};

subtest 'decode_nostr_uri: rejects missing nostr: prefix' => sub {
    my $npub = encode_npub($PUBKEY);
    like(
        dies { decode_nostr_uri($npub) },
        qr/nostr:/i,
        'missing nostr: prefix rejected'
    );
};

subtest 'decode_nostr_uri: rejects undef' => sub {
    like(
        dies { decode_nostr_uri(undef) },
        qr/./,
        'undef rejected'
    );
};

subtest 'decode_nostr_uri: rejects empty string' => sub {
    like(
        dies { decode_nostr_uri('') },
        qr/nostr:/i,
        'empty string rejected'
    );
};

###############################################################################
# Spec examples
# "nostr:npub1sn0wdenkukak0d9dfczzeacvhkrgz92ak56egt7vdgzn8pv2wfqqhrjdv9"
# "nostr:nprofile1qqsrhuxx8l9ex335q7he0f09aej04zpazpl0ne2cgukyawd24mayt8gpp4mhxue69uhhytnc9e3k7mgpz4mhxue69uhkg6nzv9ejuumpv34kytnrdaksjlyr9p"
# "nostr:nevent1qqstna2yrezu5wghjvswqqculvvwxsrcvu7uc0f78gan4xqhvz49d9spr3mhxue69uhkummnw3ez6un9d3shjtn4de6x2argwghx6egpr4mhxue69uhkummnw3ez6ur4vgh8wetvd3hhyer9wghxuet5nxnepm"
###############################################################################

subtest 'spec example: npub URI decodes successfully' => sub {
    my $uri = 'nostr:npub1sn0wdenkukak0d9dfczzeacvhkrgz92ak56egt7vdgzn8pv2wfqqhrjdv9';
    my $result = decode_nostr_uri($uri);
    is($result->{type}, 'npub', 'type is npub');
    is(length($result->{data}), 64, 'data is 64-char hex');
};

subtest 'spec example: nprofile URI decodes successfully' => sub {
    my $uri = 'nostr:nprofile1qqsrhuxx8l9ex335q7he0f09aej04zpazpl0ne2cgukyawd24mayt8gpp4mhxue69uhhytnc9e3k7mgpz4mhxue69uhkg6nzv9ejuumpv34kytnrdaksjlyr9p';
    my $result = decode_nostr_uri($uri);
    is($result->{type}, 'nprofile', 'type is nprofile');
    ok(defined $result->{data}{pubkey}, 'pubkey present');
    ok(ref $result->{data}{relays} eq 'ARRAY', 'relays is array');
};

subtest 'spec example: nevent URI decodes successfully' => sub {
    my $uri = 'nostr:nevent1qqstna2yrezu5wghjvswqqculvvwxsrcvu7uc0f78gan4xqhvz49d9spr3mhxue69uhkummnw3ez6un9d3shjtn4de6x2argwghx6egpr4mhxue69uhkummnw3ez6ur4vgh8wetvd3hhyer9wghxuet5nxnepm';
    my $result = decode_nostr_uri($uri);
    is($result->{type}, 'nevent', 'type is nevent');
    ok(defined $result->{data}{id}, 'id present');
};

###############################################################################
# Round-trip: encode -> URI -> decode
###############################################################################

subtest 'round-trip: npub through nostr: URI' => sub {
    my $npub = encode_npub($PUBKEY);
    my $uri = encode_nostr_uri($npub);
    my $result = decode_nostr_uri($uri);
    is($result->{type}, 'npub', 'type preserved');
    is($result->{data}, $PUBKEY, 'pubkey preserved');
};

subtest 'round-trip: note through nostr: URI' => sub {
    my $note = encode_note($EVENTID);
    my $uri = encode_nostr_uri($note);
    my $result = decode_nostr_uri($uri);
    is($result->{type}, 'note', 'type preserved');
    is($result->{data}, $EVENTID, 'event id preserved');
};

subtest 'round-trip: nprofile through nostr: URI' => sub {
    my $nprofile = encode_nprofile(pubkey => $PUBKEY, relays => ['wss://r1.com', 'wss://r2.com']);
    my $uri = encode_nostr_uri($nprofile);
    my $result = decode_nostr_uri($uri);
    is($result->{type}, 'nprofile', 'type preserved');
    is($result->{data}{pubkey}, $PUBKEY, 'pubkey preserved');
    is($result->{data}{relays}, ['wss://r1.com', 'wss://r2.com'], 'relays preserved');
};

subtest 'round-trip: nevent through nostr: URI' => sub {
    my $nevent = encode_nevent(id => $EVENTID, author => $PUBKEY, kind => 1);
    my $uri = encode_nostr_uri($nevent);
    my $result = decode_nostr_uri($uri);
    is($result->{type}, 'nevent', 'type preserved');
    is($result->{data}{id}, $EVENTID, 'id preserved');
    is($result->{data}{author}, $PUBKEY, 'author preserved');
    is($result->{data}{kind}, 1, 'kind preserved');
};

subtest 'round-trip: naddr through nostr: URI' => sub {
    my $naddr = encode_naddr(
        identifier => 'test-id',
        pubkey     => $PUBKEY,
        kind       => 30023,
        relays     => ['wss://relay.example'],
    );
    my $uri = encode_nostr_uri($naddr);
    my $result = decode_nostr_uri($uri);
    is($result->{type}, 'naddr', 'type preserved');
    is($result->{data}{identifier}, 'test-id', 'identifier preserved');
    is($result->{data}{pubkey}, $PUBKEY, 'pubkey preserved');
    is($result->{data}{kind}, 30023, 'kind preserved');
};

###############################################################################
# Case handling: nostr: prefix should be case-insensitive on decode
###############################################################################

subtest 'decode_nostr_uri: case-insensitive prefix' => sub {
    my $npub = encode_npub($PUBKEY);
    my $result = decode_nostr_uri("NOSTR:$npub");
    is($result->{type}, 'npub', 'uppercase NOSTR: prefix accepted');

    my $result2 = decode_nostr_uri("Nostr:$npub");
    is($result2->{type}, 'npub', 'mixed case Nostr: prefix accepted');
};

###############################################################################
# HTML linking examples from spec (informational, just verify URI format)
###############################################################################

subtest 'spec HTML: naddr URI for rel=alternate' => sub {
    my $uri = 'nostr:naddr1qqyrzwrxvc6ngvfkqyghwumn8ghj7enfv96x5ctx9e3k7mgzyqalp33lewf5vdq847t6te0wvnags0gs0mu72kz8938tn24wlfze6qcyqqq823cph95ag';
    my $result = decode_nostr_uri($uri);
    is($result->{type}, 'naddr', 'naddr from HTML link example decoded');
    ok(defined $result->{data}{identifier}, 'identifier present');
    ok(defined $result->{data}{pubkey}, 'pubkey present');
};

subtest 'spec HTML: nprofile URI for rel=me' => sub {
    my $uri = 'nostr:nprofile1qyxhwumn8ghj7mn0wvhxcmmvqyd8wumn8ghj7un9d3shjtnhv4ehgetjde38gcewvdhk6qpq80cvv07tjdrrgpa0j7j7tmnyl2yr6yr7l8j4s3evf6u64th6gkwswpnfsn';
    my $result = decode_nostr_uri($uri);
    is($result->{type}, 'nprofile', 'nprofile from HTML link example decoded');
    ok(defined $result->{data}{pubkey}, 'pubkey present');
};

done_testing;
