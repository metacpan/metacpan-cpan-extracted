use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::Wiki;

my $PK  = 'a' x 64;
my $PK2 = 'b' x 64;
my $EID = 'e' x 64;

###############################################################################
# POD example: article
###############################################################################

subtest 'POD: article' => sub {
    my $event = Net::Nostr::Wiki->article(
        pubkey     => $PK,
        identifier => 'wiki',
        title      => 'Wiki',
        content    => 'A wiki is a hypertext publication.',
    );
    is($event->kind, 30818, 'kind');
};

###############################################################################
# POD example: merge_request
###############################################################################

subtest 'POD: merge_request' => sub {
    my $source_id = 'f' x 64;
    my $event = Net::Nostr::Wiki->merge_request(
        pubkey       => $PK,
        target       => "30818:${PK2}:bitcoin",
        target_relay => 'wss://relay.com',
        source       => $source_id,
        source_relay => 'wss://relay.com',
        destination  => $PK2,
        content      => 'Added block size info',
    );
    is($event->kind, 818, 'kind');
};

###############################################################################
# POD example: redirect
###############################################################################

subtest 'POD: redirect' => sub {
    my $event = Net::Nostr::Wiki->redirect(
        pubkey       => $PK,
        identifier   => 'btc',
        target       => "30818:${PK2}:bitcoin",
        target_relay => 'wss://relay.com',
    );
    is($event->kind, 30819, 'kind');
};

###############################################################################
# POD example: normalize_dtag
###############################################################################

subtest 'POD: normalize_dtag' => sub {
    is(Net::Nostr::Wiki->normalize_dtag('Wiki Article'), 'wiki-article');
};

###############################################################################
# POD example: from_event
###############################################################################

subtest 'POD: from_event' => sub {
    my $event = Net::Nostr::Wiki->article(
        pubkey     => $PK,
        identifier => 'test',
        content    => 'content',
        title      => 'Test',
    );
    my $parsed = Net::Nostr::Wiki->from_event($event);
    is($parsed->identifier, 'test');
    is($parsed->title, 'Test');
};

###############################################################################
# POD example: validate
###############################################################################

subtest 'POD: validate' => sub {
    my $event = Net::Nostr::Wiki->article(
        pubkey => $PK, identifier => 'test', content => 'c',
    );
    ok(Net::Nostr::Wiki->validate($event), 'validate returns true');
};

###############################################################################
# POD example: resolve_wikilinks
###############################################################################

subtest 'POD: resolve_wikilinks' => sub {
    my $result = Net::Nostr::Wiki->resolve_wikilinks('[cryptocurrency][]');
    like($result, qr/nostr:30818:cryptocurrency/);
};

###############################################################################
# POD example: new
###############################################################################

subtest 'POD: new' => sub {
    my $w = Net::Nostr::Wiki->new(
        identifier => 'bitcoin',
        title      => 'Bitcoin',
    );
    is($w->identifier, 'bitcoin');
    is($w->title, 'Bitcoin');
};

###############################################################################
# Constructor: unknown args rejected
###############################################################################

subtest 'constructor: unknown args rejected' => sub {
    like(
        dies { Net::Nostr::Wiki->new(bogus => 1) },
        qr/unknown/i,
        'unknown arg rejected'
    );
};

###############################################################################
# Public methods available
###############################################################################

subtest 'public methods available' => sub {
    can_ok('Net::Nostr::Wiki',
        qw(new article merge_request redirect normalize_dtag
           from_event validate resolve_wikilinks
           identifier title summary
           target target_relay destination
           source source_relay base_version base_relay
           fork_a fork_e defer_a defer_e));
};

done_testing;
