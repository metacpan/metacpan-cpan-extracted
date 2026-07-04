use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::Mention qw(
    extract_mentions
    replace_mentions
    mention_pubkey
    mention_event
    mention_addr
);
use Net::Nostr::Bech32 qw(encode_npub encode_note);

my $pk  = 'aa' x 32;
my $eid = 'bb' x 32;

###############################################################################
# mention_pubkey
###############################################################################

subtest 'mention_pubkey: undef croaks' => sub {
    like(dies { mention_pubkey(undef) }, qr/pubkey must be/, 'undef rejected');
};

subtest 'mention_pubkey: uppercase hex croaks' => sub {
    like(dies { mention_pubkey(uc $pk) }, qr/pubkey must be/, 'uppercase rejected');
};

subtest 'mention_pubkey: empty relays uses npub' => sub {
    my $m = mention_pubkey($pk, relays => []);
    like($m, qr/\Anostr:npub1/, 'empty relays gives npub');
};

###############################################################################
# mention_event
###############################################################################

subtest 'mention_event: undef croaks' => sub {
    like(dies { mention_event(undef) }, qr/event id must be/, 'undef rejected');
};

subtest 'mention_event: author alone upgrades to nevent' => sub {
    my $m = mention_event($eid, author => $pk);
    like($m, qr/\Anostr:nevent1/, 'author triggers nevent');
};

subtest 'mention_event: kind alone upgrades to nevent' => sub {
    my $m = mention_event($eid, kind => 1);
    like($m, qr/\Anostr:nevent1/, 'kind triggers nevent');
};

subtest 'mention_event: kind 0 upgrades to nevent' => sub {
    my $m = mention_event($eid, kind => 0);
    like($m, qr/\Anostr:nevent1/, 'kind 0 triggers nevent');
};

###############################################################################
# mention_addr
###############################################################################

subtest 'mention_addr: empty identifier allowed' => sub {
    my $m = mention_addr(identifier => '', pubkey => $pk, kind => 30023);
    like($m, qr/\Anostr:naddr1/, 'empty identifier works');
};

###############################################################################
# extract_mentions
###############################################################################

subtest 'extract_mentions: undef returns empty' => sub {
    my @m = extract_mentions(undef);
    is(scalar @m, 0, 'undef gives no mentions');
};

subtest 'extract_mentions: mention order matches content order' => sub {
    my $n1 = encode_npub($pk);
    my $n2 = encode_note($eid);
    my @m = extract_mentions("nostr:$n1 nostr:$n2");
    is($m[0]{type}, 'npub', 'first is npub');
    is($m[1]{type}, 'note', 'second is note');
    ok($m[0]{start} < $m[1]{start}, 'ordered by position');
};

###############################################################################
# replace_mentions
###############################################################################

subtest 'replace_mentions: non-coderef callback croaks' => sub {
    like(dies { replace_mentions('text', 'not a ref') },
        qr/callback must be a code reference/, 'string rejected');
};

subtest 'replace_mentions: undef content returns undef' => sub {
    my $result = replace_mentions(undef, sub { 'x' });
    ok(!defined $result, 'undef returns undef');
};

done_testing;
