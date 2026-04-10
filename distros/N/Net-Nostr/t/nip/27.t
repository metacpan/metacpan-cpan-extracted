use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::Mention qw(
    extract_mentions
    replace_mentions
    mention_pubkey
    mention_event
    mention_addr
);
use Net::Nostr::Bech32 qw(
    encode_npub encode_note
    encode_nprofile encode_nevent encode_naddr
    decode_nostr_uri
);
use Net::Nostr::Event;

my $pk1 = '3bf0c63fcb93463407af97a5e5ee64fa883d107ef9e558472c4eb9aaaefa459d';
my $pk2 = '2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc';
my $eid = 'deb8b23368b6c658c36cf16396927a045dee0b7707b4133d714fb67264cc10cc';

###############################################################################
# NIP-27 spec example: profile mention
###############################################################################

subtest 'NIP-27 spec example: profile mention in kind 1' => sub {
    my $content = 'hello nostr:nprofile1qqszclxx9f5haga8sfjjrulaxncvkfekj097t6f3pu65f86rvg49ehqj6f9dh';

    my @mentions = extract_mentions($content);
    is(scalar @mentions, 1, 'one mention found');
    is($mentions[0]{type}, 'nprofile', 'type is nprofile');
    is($mentions[0]{data}{pubkey}, $pk2, 'pubkey matches NIP-27 example');
    is($mentions[0]{uri}, 'nostr:nprofile1qqszclxx9f5haga8sfjjrulaxncvkfekj097t6f3pu65f86rvg49ehqj6f9dh',
        'uri captures full nostr: reference');
    is($mentions[0]{start}, 6, 'start offset is correct');
    is($mentions[0]{end}, length($content), 'end offset is correct');
};

###############################################################################
# extract_mentions
###############################################################################

subtest 'extract_mentions: no mentions' => sub {
    my @m = extract_mentions('just some text with no references');
    is(scalar @m, 0, 'empty list for no mentions');
};

subtest 'extract_mentions: npub mention' => sub {
    my $npub = encode_npub($pk1);
    my $content = "check out nostr:$npub for more";
    my @m = extract_mentions($content);
    is(scalar @m, 1, 'one mention');
    is($m[0]{type}, 'npub', 'type is npub');
    is($m[0]{data}, $pk1, 'data is hex pubkey');
};

subtest 'extract_mentions: note mention' => sub {
    my $note = encode_note($eid);
    my $content = "see nostr:$note";
    my @m = extract_mentions($content);
    is(scalar @m, 1, 'one mention');
    is($m[0]{type}, 'note', 'type is note');
    is($m[0]{data}, $eid, 'data is hex event id');
};

subtest 'extract_mentions: nevent mention' => sub {
    my $nevent = encode_nevent(id => $eid, relays => ['wss://relay.com'], author => $pk1, kind => 1);
    my $content = "look nostr:$nevent here";
    my @m = extract_mentions($content);
    is(scalar @m, 1, 'one mention');
    is($m[0]{type}, 'nevent', 'type is nevent');
    is($m[0]{data}{id}, $eid, 'event id matches');
    is($m[0]{data}{author}, $pk1, 'author matches');
    is($m[0]{data}{kind}, 1, 'kind matches');
    ok(scalar @{$m[0]{data}{relays}} >= 1, 'has relay');
};

subtest 'extract_mentions: naddr mention' => sub {
    my $naddr = encode_naddr(identifier => 'my-article', pubkey => $pk1, kind => 30023);
    my $content = "read nostr:$naddr";
    my @m = extract_mentions($content);
    is(scalar @m, 1, 'one mention');
    is($m[0]{type}, 'naddr', 'type is naddr');
    is($m[0]{data}{identifier}, 'my-article', 'identifier matches');
    is($m[0]{data}{pubkey}, $pk1, 'pubkey matches');
    is($m[0]{data}{kind}, 30023, 'kind matches');
};

subtest 'extract_mentions: multiple mentions' => sub {
    my $npub1 = encode_npub($pk1);
    my $npub2 = encode_npub($pk2);
    my $content = "nostr:$npub1 and nostr:$npub2";
    my @m = extract_mentions($content);
    is(scalar @m, 2, 'two mentions');
    is($m[0]{data}, $pk1, 'first is pk1');
    is($m[1]{data}, $pk2, 'second is pk2');
};

subtest 'extract_mentions: mixed types' => sub {
    my $npub = encode_npub($pk1);
    my $note = encode_note($eid);
    my $content = "by nostr:$npub in nostr:$note";
    my @m = extract_mentions($content);
    is(scalar @m, 2, 'two mentions');
    is($m[0]{type}, 'npub', 'first is npub');
    is($m[1]{type}, 'note', 'second is note');
};

subtest 'extract_mentions: nsec ignored' => sub {
    # nsec must not appear in nostr: URIs per NIP-21
    my $content = 'nostr:nsec1vl029mgpspedva04g90vltkh6fvh240zqtv9k0t9af8935ke9laqsnlfe5';
    my @m = extract_mentions($content);
    is(scalar @m, 0, 'nsec mentions are skipped');
};

subtest 'extract_mentions: positions are correct' => sub {
    my $npub = encode_npub($pk1);
    my $content = "hello nostr:$npub world";
    my @m = extract_mentions($content);
    is(substr($content, $m[0]{start}, $m[0]{end} - $m[0]{start}),
        "nostr:$npub", 'start/end slice back to original URI');
};

subtest 'extract_mentions: adjacent to punctuation' => sub {
    my $npub = encode_npub($pk1);
    my $content = "(nostr:$npub)";
    my @m = extract_mentions($content);
    is(scalar @m, 1, 'mention found next to parens');
    is($m[0]{type}, 'npub', 'type correct');
};

subtest 'extract_mentions: case insensitive nostr: prefix' => sub {
    my $npub = encode_npub($pk1);
    my $content = "check Nostr:$npub";
    my @m = extract_mentions($content);
    is(scalar @m, 1, 'case-insensitive prefix matches');
};

subtest 'extract_mentions: invalid bech32 after nostr: is skipped' => sub {
    my $content = 'nostr:notvalidbech32string';
    my @m = extract_mentions($content);
    is(scalar @m, 0, 'invalid bech32 is silently skipped');
};

###############################################################################
# replace_mentions
###############################################################################

subtest 'replace_mentions: basic replacement' => sub {
    my $npub = encode_npub($pk1);
    my $content = "hello nostr:$npub world";
    my $result = replace_mentions($content, sub {
        my ($mention) = @_;
        return '@fiatjaf';
    });
    is($result, 'hello @fiatjaf world', 'mention replaced');
};

subtest 'replace_mentions: multiple replacements' => sub {
    my $npub1 = encode_npub($pk1);
    my $npub2 = encode_npub($pk2);
    my $content = "nostr:$npub1 and nostr:$npub2";
    my $result = replace_mentions($content, sub {
        my ($mention) = @_;
        return $mention->{type} eq 'npub' ? '@user' : $mention->{uri};
    });
    is($result, '@user and @user', 'both replaced');
};

subtest 'replace_mentions: no mentions leaves content unchanged' => sub {
    my $content = 'no mentions here';
    my $result = replace_mentions($content, sub { die 'should not be called' });
    is($result, $content, 'unchanged');
};

subtest 'replace_mentions: callback receives mention hash' => sub {
    my $npub = encode_npub($pk1);
    my $content = "nostr:$npub";
    my $got_type;
    replace_mentions($content, sub {
        $got_type = $_[0]{type};
        return '';
    });
    is($got_type, 'npub', 'callback got type');
};

subtest 'replace_mentions: preserves surrounding text' => sub {
    my $npub = encode_npub($pk1);
    my $content = "before nostr:$npub after";
    my $result = replace_mentions($content, sub { 'X' });
    is($result, 'before X after', 'surrounding text preserved');
};

###############################################################################
# mention_pubkey
###############################################################################

subtest 'mention_pubkey: bare npub' => sub {
    my $mention = mention_pubkey($pk1);
    like($mention, qr/\Anostr:npub1/, 'starts with nostr:npub1');
    my $decoded = decode_nostr_uri($mention);
    is($decoded->{type}, 'npub', 'decodes as npub');
    is($decoded->{data}, $pk1, 'round-trips pubkey');
};

subtest 'mention_pubkey: with relays produces nprofile' => sub {
    my $mention = mention_pubkey($pk1, relays => ['wss://relay.com']);
    like($mention, qr/\Anostr:nprofile1/, 'starts with nostr:nprofile1');
    my $decoded = decode_nostr_uri($mention);
    is($decoded->{type}, 'nprofile', 'decodes as nprofile');
    is($decoded->{data}{pubkey}, $pk1, 'pubkey round-trips');
    is($decoded->{data}{relays}, ['wss://relay.com'], 'relays round-trip');
};

subtest 'mention_pubkey: validates hex' => sub {
    like(
        dies { mention_pubkey('not-hex') },
        qr/pubkey must be 64-char lowercase hex/,
        'bad pubkey rejected'
    );
};

###############################################################################
# mention_event
###############################################################################

subtest 'mention_event: bare note' => sub {
    my $mention = mention_event($eid);
    like($mention, qr/\Anostr:note1/, 'starts with nostr:note1');
    my $decoded = decode_nostr_uri($mention);
    is($decoded->{type}, 'note', 'decodes as note');
    is($decoded->{data}, $eid, 'round-trips event id');
};

subtest 'mention_event: with metadata produces nevent' => sub {
    my $mention = mention_event($eid, relays => ['wss://r.com'], author => $pk1, kind => 1);
    like($mention, qr/\Anostr:nevent1/, 'starts with nostr:nevent1');
    my $decoded = decode_nostr_uri($mention);
    is($decoded->{type}, 'nevent', 'decodes as nevent');
    is($decoded->{data}{id}, $eid, 'id round-trips');
    is($decoded->{data}{author}, $pk1, 'author round-trips');
    is($decoded->{data}{kind}, 1, 'kind round-trips');
};

subtest 'mention_event: relays alone upgrades to nevent' => sub {
    my $mention = mention_event($eid, relays => ['wss://relay.com']);
    like($mention, qr/\Anostr:nevent1/, 'relays trigger nevent');
};

subtest 'mention_event: validates hex' => sub {
    like(
        dies { mention_event('bad') },
        qr/event id must be 64-char lowercase hex/,
        'bad event id rejected'
    );
};

###############################################################################
# mention_addr
###############################################################################

subtest 'mention_addr: basic' => sub {
    my $mention = mention_addr(identifier => 'my-article', pubkey => $pk1, kind => 30023);
    like($mention, qr/\Anostr:naddr1/, 'starts with nostr:naddr1');
    my $decoded = decode_nostr_uri($mention);
    is($decoded->{type}, 'naddr', 'decodes as naddr');
    is($decoded->{data}{identifier}, 'my-article', 'identifier round-trips');
    is($decoded->{data}{pubkey}, $pk1, 'pubkey round-trips');
    is($decoded->{data}{kind}, 30023, 'kind round-trips');
};

subtest 'mention_addr: with relays' => sub {
    my $mention = mention_addr(
        identifier => 'test', pubkey => $pk1, kind => 30023,
        relays => ['wss://relay.com'],
    );
    my $decoded = decode_nostr_uri($mention);
    is($decoded->{data}{relays}, ['wss://relay.com'], 'relays round-trip');
};

subtest 'mention_addr: required fields' => sub {
    like(
        dies { mention_addr(pubkey => $pk1, kind => 30023) },
        qr/requires 'identifier'/,
        'missing identifier croaks'
    );
    like(
        dies { mention_addr(identifier => 'x', kind => 30023) },
        qr/requires 'pubkey'/,
        'missing pubkey croaks'
    );
    like(
        dies { mention_addr(identifier => 'x', pubkey => $pk1) },
        qr/requires 'kind'/,
        'missing kind croaks'
    );
};

###############################################################################
# NIP-27 spec example JSON: full event round-trip
###############################################################################

subtest 'NIP-27 spec JSON example: full event with p tag cross-reference' => sub {
    # Exact event from the NIP-27 spec (lines 27-42)
    my $event = Net::Nostr::Event->new(
        id         => 'f39e9b451a73d62abc5016cffdd294b1a904e2f34536a208874fe5e22bbd47cf',
        pubkey     => '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798',
        created_at => 1679790774,
        kind       => 1,
        content    => 'hello nostr:nprofile1qqszclxx9f5haga8sfjjrulaxncvkfekj097t6f3pu65f86rvg49ehqj6f9dh',
        tags       => [['p', '2c7cc62a697ea3a7826521f3fd34f0cb273693cbe5e9310f35449f43622a5cdc']],
        sig        => 'f8c8bab1b90cc3d2ae1ad999e6af8af449ad8bb4edf64807386493163e29162b5852a796a8f474d6b1001cddbaac0de4392838574f5366f03cc94cf5dfb43f4d',
    );

    my @m = extract_mentions($event->content);
    is(scalar @m, 1, 'one mention in spec example event');
    is($m[0]{type}, 'nprofile', 'type is nprofile');

    # Cross-reference: extracted pubkey must match the p tag
    my $p_tag_pubkey = $event->tags->[0][1];
    is($m[0]{data}{pubkey}, $p_tag_pubkey,
        'extracted pubkey matches p tag in spec example event');

    # Line 44: "Alternatively, the mention could have been a nostr:npub1... URL."
    my $alt_content = 'hello ' . mention_pubkey($m[0]{data}{pubkey});
    my @m2 = extract_mentions($alt_content);
    is(scalar @m2, 1, 'npub alternative also works');
    is($m2[0]{data}, $m[0]{data}{pubkey}, 'same pubkey either way');
};

###############################################################################
# NIP-21 examples used as test vectors
###############################################################################

subtest 'NIP-21 example URIs parse correctly' => sub {
    # From NIP-21 spec
    my @uris = (
        'nostr:npub1sn0wdenkukak0d9dfczzeacvhkrgz92ak56egt7vdgzn8pv2wfqqhrjdv9',
        'nostr:nprofile1qqsrhuxx8l9ex335q7he0f09aej04zpazpl0ne2cgukyawd24mayt8gpp4mhxue69uhhytnc9e3k7mgpz4mhxue69uhkg6nzv9ejuumpv34kytnrdaksjlyr9p',
        'nostr:nevent1qqstna2yrezu5wghjvswqqculvvwxsrcvu7uc0f78gan4xqhvz49d9spr3mhxue69uhkummnw3ez6un9d3shjtn4de6x2argwghx6egpr4mhxue69uhkummnw3ez6ur4vgh8wetvd3hhyer9wghxuet5nxnepm',
    );

    for my $uri (@uris) {
        my @m = extract_mentions($uri);
        is(scalar @m, 1, "one mention in ${\substr($uri, 0, 25)}...");
        ok(defined $m[0]{type}, 'has type');
        ok(defined $m[0]{data}, 'has data');
    }
};

###############################################################################
# NIP-27 spec line 13/53/54: tags are optional for all mention types
###############################################################################

subtest 'NIP-27: all mention_* return plain strings, not tags' => sub {
    # NIP-27 line 13: "Including NIP-18's quote tags [...] for each reference
    # is optional"
    # Line 53: client can choose not to create ["p", ...] tag
    # Line 54: client can choose not to create ["e", ...] tag
    # mention_* functions produce only the content string; tag creation
    # is the caller's responsibility.
    my $m_pub = mention_pubkey($pk1);
    ok(!ref $m_pub, 'mention_pubkey returns a plain string');
    like($m_pub, qr/\Anostr:/, 'mention_pubkey starts with nostr:');

    my $m_evt = mention_event($eid);
    ok(!ref $m_evt, 'mention_event returns a plain string');
    like($m_evt, qr/\Anostr:/, 'mention_event starts with nostr:');

    my $m_addr = mention_addr(identifier => 'x', pubkey => $pk1, kind => 30023);
    ok(!ref $m_addr, 'mention_addr returns a plain string');
    like($m_addr, qr/\Anostr:/, 'mention_addr starts with nostr:');
};

###############################################################################
# Edge cases
###############################################################################

subtest 'extract_mentions: nostr: at start of string' => sub {
    my $npub = encode_npub($pk1);
    my $content = "nostr:$npub";
    my @m = extract_mentions($content);
    is(scalar @m, 1, 'mention at start');
    is($m[0]{start}, 0, 'start is 0');
};

subtest 'extract_mentions: nostr: at end of string' => sub {
    my $npub = encode_npub($pk1);
    my $content = "text nostr:$npub";
    my @m = extract_mentions($content);
    is(scalar @m, 1, 'mention at end');
    is($m[0]{end}, length($content), 'end is string length');
};

subtest 'extract_mentions: back-to-back mentions' => sub {
    my $npub = encode_npub($pk1);
    my $content = "nostr:$npub nostr:$npub";
    my @m = extract_mentions($content);
    is(scalar @m, 2, 'two adjacent mentions');
};

subtest 'extract_mentions: empty string' => sub {
    my @m = extract_mentions('');
    is(scalar @m, 0, 'empty string yields no mentions');
};

subtest 'replace_mentions: callback can return empty string' => sub {
    my $npub = encode_npub($pk1);
    my $content = "a nostr:$npub b";
    my $result = replace_mentions($content, sub { '' });
    is($result, 'a  b', 'empty replacement works');
};

subtest 'replace_mentions: callback can return longer text' => sub {
    my $npub = encode_npub($pk1);
    my $content = "nostr:$npub";
    my $result = replace_mentions($content, sub { 'a very long replacement string' });
    is($result, 'a very long replacement string', 'longer replacement works');
};

###############################################################################
# NIP-27 spec line 9: works with kind 30023 (long-form content)
###############################################################################

subtest 'NIP-27: mentions in kind 30023 long-form content' => sub {
    # Spec line 9: "such as kinds 1 and 30023"
    my $profile_mention = mention_pubkey($pk1, relays => ['wss://relay.example.com']);
    my $event_mention   = mention_event($eid);
    my $content = "This article references $profile_mention and cites $event_mention in its analysis.";

    my @m = extract_mentions($content);
    is(scalar @m, 2, 'two mentions in long-form content');
    is($m[0]{type}, 'nprofile', 'first is nprofile');
    is($m[1]{type}, 'note', 'second is note');
};

###############################################################################
# NIP-27 spec line 46: Carol's flow (extract -> lookup -> replace)
###############################################################################

subtest 'NIP-27: reader client extract-and-replace flow (spec line 46)' => sub {
    # "Carol sees it, her client will initially display the .content as it
    #  is, but later it will parse the .content and see that there is a
    #  nostr: URL in there, decode it, extract the public key from it (and
    #  possibly relay hints), fetch that profile [...], then replace the full
    #  URL with the name @mattn"
    my $content = 'hello nostr:nprofile1qqszclxx9f5haga8sfjjrulaxncvkfekj097t6f3pu65f86rvg49ehqj6f9dh';

    # Step 1: parse and extract pubkey + relay hints
    my @m = extract_mentions($content);
    is($m[0]{data}{pubkey}, $pk2, 'extracted pubkey');
    is(ref $m[0]{data}{relays}, 'ARRAY', 'relay hints available');

    # Step 2: replace with display name (simulating profile lookup)
    my %profiles = ($pk2 => '@mattn');
    my $display = replace_mentions($content, sub {
        my ($mention) = @_;
        my $pk = $mention->{type} eq 'nprofile' ? $mention->{data}{pubkey}
               : $mention->{type} eq 'npub'     ? $mention->{data}
               : return $mention->{uri};
        return $profiles{$pk} // $mention->{uri};
    });
    is($display, 'hello @mattn', 'Carol sees "hello @mattn"');
};

###############################################################################
# NIP-27 spec line 15: replace with different link types
###############################################################################

subtest 'NIP-27: replace with NIP-21 link (keep as nostr: URI)' => sub {
    # Spec line 15: "they could become [...] NIP-21 links"
    my $npub = encode_npub($pk1);
    my $content = "follow nostr:$npub for updates";
    my $result = replace_mentions($content, sub { $_[0]{uri} });
    is($result, $content, 'keeping nostr: URI is a valid replacement strategy');
};

subtest 'NIP-27: replace with web client link' => sub {
    # Spec line 15: "or direct links to web clients that will handle
    # these references"
    my $npub = encode_npub($pk1);
    my $content = "follow nostr:$npub";
    my $result = replace_mentions($content, sub {
        my ($m) = @_;
        return "https://njump.me/${\substr($m->{uri}, 6)}" if $m->{type} eq 'npub';
        return $m->{uri};
    });
    like($result, qr{^follow https://njump\.me/npub1}, 'replaced with web link');
};

###############################################################################
# NIP-27 spec line 52: naddr in kind 1 content -> web link
###############################################################################

subtest 'NIP-27: naddr mention in kind 1 turned into web link (spec line 52)' => sub {
    # "a client that is designed for dealing with only kind:1 text notes
    #  sees, for example, a kind:30023 nostr:naddr1... URL reference in the
    #  .content, it can [...] turn that into a link to some hardcoded webapp"
    my $naddr = encode_naddr(identifier => 'my-article', pubkey => $pk1, kind => 30023);
    my $content = "read this: nostr:$naddr";
    my $result = replace_mentions($content, sub {
        my ($m) = @_;
        if ($m->{type} eq 'naddr') {
            return "https://habla.news/a/${\substr($m->{uri}, 6)}";
        }
        return $m->{uri};
    });
    like($result, qr{^read this: https://habla\.news/a/naddr1}, 'naddr turned into webapp link');
};

###############################################################################
# NIP-27 spec line 50: raw NIP-19 codes pasted and prefixed with nostr:
###############################################################################

subtest 'NIP-27: raw NIP-19 code prefixed with nostr: (spec line 50)' => sub {
    # "clients that do not support autocomplete at all, so they just allow
    #  users to paste raw NIP-19 codes into the body of text, then prefix
    #  these with nostr: before publishing"
    my $nevent = encode_nevent(id => $eid, relays => ['wss://nos.lol']);
    # Simulate: user pasted raw nevent, client prefixes with nostr:
    my $content = "check this nostr:$nevent out";
    my @m = extract_mentions($content);
    is(scalar @m, 1, 'pasted nevent found');
    is($m[0]{type}, 'nevent', 'type is nevent');
    is($m[0]{data}{id}, $eid, 'event id extracted');
    is($m[0]{data}{relays}, ['wss://nos.lol'], 'relay hint preserved');
};

###############################################################################
# extract_mentions: nprofile with relay hints accessible
###############################################################################

subtest 'extract_mentions: nprofile relay hints are accessible' => sub {
    my @relays = ('wss://relay1.example.com', 'wss://relay2.example.com');
    my $nprofile = encode_nprofile(pubkey => $pk1, relays => \@relays);
    my $content = "nostr:$nprofile";
    my @m = extract_mentions($content);
    is(scalar @m, 1, 'one mention');
    is($m[0]{type}, 'nprofile', 'type is nprofile');
    is($m[0]{data}{pubkey}, $pk1, 'pubkey extracted');
    is($m[0]{data}{relays}, \@relays, 'relay hints extracted and accessible');
};

###############################################################################
# Round-trip: mention_* -> extract_mentions
###############################################################################

subtest 'round-trip: mention_pubkey -> extract' => sub {
    my $mention = mention_pubkey($pk1);
    my @m = extract_mentions("hello $mention world");
    is(scalar @m, 1, 'extracted one');
    is($m[0]{type}, 'npub', 'type preserved');
    is($m[0]{data}, $pk1, 'data preserved');
};

subtest 'round-trip: mention_event -> extract' => sub {
    my $mention = mention_event($eid, author => $pk1, kind => 1);
    my @m = extract_mentions("see $mention");
    is(scalar @m, 1, 'extracted one');
    is($m[0]{type}, 'nevent', 'type preserved');
    is($m[0]{data}{id}, $eid, 'id preserved');
};

subtest 'round-trip: mention_addr -> extract' => sub {
    my $mention = mention_addr(identifier => 'test', pubkey => $pk1, kind => 30023);
    my @m = extract_mentions("read $mention");
    is(scalar @m, 1, 'extracted one');
    is($m[0]{type}, 'naddr', 'type preserved');
    is($m[0]{data}{identifier}, 'test', 'identifier preserved');
};

###############################################################################
# POD code examples
###############################################################################

subtest 'POD: SYNOPSIS extract + replace' => sub {
    my $pk = '7e7e9c42a91bfef19fa929e5fda1b72e0ebc1a4c1141673e2794234d86addf4e';
    my $id = 'aaf9dd42b3de2a1a2f95e50fdbbef66e1afb165152a581a3ee75ac39a0559cd2';

    my $m1 = mention_pubkey($pk);
    like($m1, qr/\Anostr:npub1/, 'mention_pubkey produces nostr:npub1...');
    my $m3 = mention_event($id);
    like($m3, qr/\Anostr:note1/, 'mention_event produces nostr:note1...');

    my $content = "hello $m1 see also $m3";
    my @mentions = extract_mentions($content);
    is(scalar @mentions, 2, 'two mentions extracted');
    is($mentions[0]{type}, 'npub', 'first is npub');
    is($mentions[0]{data}, $pk, 'first data is pubkey');
    is($mentions[1]{type}, 'note', 'second is note');
    is($mentions[1]{data}, $id, 'second data is event id');

    my $display = replace_mentions($content, sub {
        my ($mention) = @_;
        return '@someone' if $mention->{type} eq 'npub';
        return '[event]'  if $mention->{type} eq 'note';
        return $mention->{uri};
    });
    is($display, 'hello @someone see also [event]', 'SYNOPSIS replace example');
};

subtest 'POD: extract_mentions example' => sub {
    my $npub = encode_npub('aa' x 32);
    my $content = "hello nostr:$npub world";
    my @m = extract_mentions($content);
    is($m[0]{type}, 'npub', 'type is npub');
    is($m[0]{start}, 6, 'start is 6');
    is(substr($content, $m[0]{start}, $m[0]{end} - $m[0]{start}),
        "nostr:$npub", 'substr recovers full URI');
    is($m[0]{data}, 'aa' x 32, 'data is hex pubkey');
};

subtest 'POD: replace_mentions example' => sub {
    my $npub = encode_npub('aa' x 32);
    my $note = encode_note('bb' x 32);
    my $content = "by nostr:$npub see nostr:$note";
    my $display = replace_mentions($content, sub {
        my ($m) = @_;
        return '@' . substr($m->{data}, 0, 8) . '...' if $m->{type} eq 'npub';
        return '[event]' if $m->{type} eq 'note' || $m->{type} eq 'nevent';
        return $m->{uri};
    });
    is($display, 'by @aaaaaaaa... see [event]', 'replace_mentions POD example');
};

subtest 'POD: mention_pubkey example' => sub {
    my $pk = 'aa' x 32;
    my $content = "hello " . mention_pubkey($pk) . " how are you?";
    like($content, qr/\Ahello nostr:npub1.+ how are you\?\z/, 'mention_pubkey in content');
    my @m = extract_mentions($content);
    is(scalar @m, 1, 'one mention');
    is($m[0]{data}, $pk, 'pubkey round-trips through content');
};

subtest 'POD: mention_event example' => sub {
    my $pk = 'aa' x 32;
    my $id = 'bb' x 32;
    my $content = "see " . mention_event($id, author => $pk, kind => 1);
    like($content, qr/\Asee nostr:nevent1/, 'mention_event with author+kind in content');
    my @m = extract_mentions($content);
    is(scalar @m, 1, 'one mention');
    is($m[0]{data}{id}, $id, 'event id round-trips');
    is($m[0]{data}{author}, $pk, 'author round-trips');
};

subtest 'POD: mention_addr example' => sub {
    my $pk = 'aa' x 32;
    my $content = "read " . mention_addr(
        identifier => 'my-article', pubkey => $pk, kind => 30023,
    );
    like($content, qr/\Aread nostr:naddr1/, 'mention_addr in content');
    my @m = extract_mentions($content);
    is(scalar @m, 1, 'one mention');
    is($m[0]{data}{identifier}, 'my-article', 'identifier round-trips');
    is($m[0]{data}{kind}, 30023, 'kind round-trips');
};

done_testing;
