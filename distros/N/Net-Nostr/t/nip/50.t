#!/usr/bin/perl

# NIP-50: Search Capability
# https://github.com/nostr-protocol/nips/blob/master/50.md

use strictures 2;

use Test2::V0 -no_srand => 1;
use JSON;

use Net::Nostr::Filter;
use Net::Nostr::Event;
use Net::Nostr::Message;

my %BASE_EVENT = (
    pubkey     => 'aa' x 32,
    kind       => 1,
    content    => 'best nostr apps for daily use',
    created_at => 1000,
    tags       => [],
);

###############################################################################
# "search" filter field
# "A new search field is introduced for REQ messages from clients"
###############################################################################

subtest 'search field in filter construction' => sub {
    my $filter = Net::Nostr::Filter->new(search => 'best nostr apps');
    is($filter->search, 'best nostr apps', 'search accessor returns value');
};

subtest 'search field is included in to_hash' => sub {
    my $filter = Net::Nostr::Filter->new(search => 'best nostr apps');
    my $h = $filter->to_hash;
    is($h->{search}, 'best nostr apps', 'search in hash');
};

subtest 'search field omitted from to_hash when not set' => sub {
    my $filter = Net::Nostr::Filter->new(kinds => [1]);
    my $h = $filter->to_hash;
    ok(!exists $h->{search}, 'search not in hash when unset');
};

###############################################################################
# "search field is a string describing a query in a human-readable form"
###############################################################################

subtest 'search can be any human-readable string' => sub {
    my $f1 = Net::Nostr::Filter->new(search => 'best nostr apps');
    is($f1->search, 'best nostr apps', 'multi-word search');

    my $f2 = Net::Nostr::Filter->new(search => 'orange');
    is($f2->search, 'orange', 'single-word search');
};

###############################################################################
# "Relays SHOULD perform matching against content event field"
# Client-side matches() for search
###############################################################################

subtest 'matches: search matches against content field' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT);
    my $filter = Net::Nostr::Filter->new(search => 'nostr');
    ok($filter->matches($event), 'word found in content matches');
};

subtest 'matches: search is case-insensitive' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT);
    my $filter = Net::Nostr::Filter->new(search => 'NOSTR');
    ok($filter->matches($event), 'uppercase search matches lowercase content');

    my $event2 = Net::Nostr::Event->new(%BASE_EVENT, content => 'NOSTR RULES');
    my $filter2 = Net::Nostr::Filter->new(search => 'nostr');
    ok($filter2->matches($event2), 'lowercase search matches uppercase content');
};

subtest 'matches: all search terms must match (AND)' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT); # 'best nostr apps for daily use'
    my $filter = Net::Nostr::Filter->new(search => 'nostr apps');
    ok($filter->matches($event), 'both words present');

    my $filter2 = Net::Nostr::Filter->new(search => 'nostr bitcoin');
    ok(!$filter2->matches($event), 'second word missing - no match');
};

subtest 'matches: search rejects event when no terms match' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT);
    my $filter = Net::Nostr::Filter->new(search => 'bitcoin lightning');
    ok(!$filter->matches($event), 'no terms match content');
};

###############################################################################
# "A query string may contain key:value pairs (two words separated by colon),
#  these are extensions"
# Extensions should be ignored during client-side matching
###############################################################################

subtest 'matches: extensions in search are ignored for content matching' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT);
    my $filter = Net::Nostr::Filter->new(search => 'nostr language:en');
    ok($filter->matches($event), 'extension ignored, nostr matches content');
};

subtest 'matches: search with only extensions matches any content' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT);
    my $filter = Net::Nostr::Filter->new(search => 'language:en domain:example.com');
    ok($filter->matches($event), 'only extensions = no content constraint');
};

###############################################################################
# "Clients may include kinds, ids and other filter field to restrict
#  the search results"
###############################################################################

subtest 'search combined with kinds filter (AND)' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT); # kind 1
    my $filter = Net::Nostr::Filter->new(kinds => [1, 2], search => 'nostr');
    ok($filter->matches($event), 'kind matches AND search matches');

    my $filter2 = Net::Nostr::Filter->new(kinds => [3], search => 'nostr');
    ok(!$filter2->matches($event), 'kind mismatch rejects despite search match');

    my $filter3 = Net::Nostr::Filter->new(kinds => [1], search => 'bitcoin');
    ok(!$filter3->matches($event), 'search mismatch rejects despite kind match');
};

subtest 'search combined with ids filter (AND)' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT);
    my $filter = Net::Nostr::Filter->new(ids => [$event->id], search => 'nostr');
    ok($filter->matches($event), 'id AND search both match');

    my $filter2 = Net::Nostr::Filter->new(ids => ['ff' x 32], search => 'nostr');
    ok(!$filter2->matches($event), 'wrong id rejects despite search match');
};

subtest 'search combined with authors filter (AND)' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT);
    my $filter = Net::Nostr::Filter->new(authors => ['aa' x 32], search => 'nostr');
    ok($filter->matches($event), 'author AND search both match');

    my $filter2 = Net::Nostr::Filter->new(authors => ['bb' x 32], search => 'nostr');
    ok(!$filter2->matches($event), 'wrong author rejects');
};

###############################################################################
# "Clients may specify several search filters"
# Spec example: ["REQ", "", { "search": "orange" }, { "kinds": [1, 2], "search": "purple" }]
###############################################################################

subtest 'multiple search filters act as OR (matches_any)' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT, content => 'I like orange juice');
    my $f1 = Net::Nostr::Filter->new(search => 'orange');
    my $f2 = Net::Nostr::Filter->new(kinds => [1, 2], search => 'purple');
    ok(Net::Nostr::Filter->matches_any($event, $f1, $f2), 'first filter matches');

    my $event2 = Net::Nostr::Event->new(%BASE_EVENT, content => 'purple rain');
    ok(Net::Nostr::Filter->matches_any($event2, $f1, $f2), 'second filter matches');

    my $event3 = Net::Nostr::Event->new(%BASE_EVENT, content => 'green grass');
    ok(!Net::Nostr::Filter->matches_any($event3, $f1, $f2), 'neither filter matches');
};

subtest 'spec example: REQ with multiple search filters' => sub {
    my @filters = (
        Net::Nostr::Filter->new(search => 'orange'),
        Net::Nostr::Filter->new(kinds => [1, 2], search => 'purple'),
    );

    my $msg = Net::Nostr::Message->new(
        type            => 'REQ',
        subscription_id => 'sub-1',
        filters         => \@filters,
    );
    my $decoded = JSON::decode_json($msg->serialize);
    is($decoded->[0], 'REQ', 'REQ message');
    is($decoded->[1], 'sub-1', 'subscription id');
    is($decoded->[2]{search}, 'orange', 'first filter has search');
    is($decoded->[3]{search}, 'purple', 'second filter has search');
    is($decoded->[3]{kinds}, [1, 2], 'second filter has kinds');
};

###############################################################################
# parse_search_extensions - parse key:value extension pairs
###############################################################################

subtest 'parse_search_extensions: extracts extensions and terms' => sub {
    my $result = Net::Nostr::Filter->parse_search_extensions('best nostr apps language:en domain:example.com');
    is($result->{terms}, ['best', 'nostr', 'apps'], 'non-extension words as terms');
    is($result->{extensions}{language}, 'en', 'language extension');
    is($result->{extensions}{domain}, 'example.com', 'domain extension');
};

subtest 'parse_search_extensions: no extensions' => sub {
    my $result = Net::Nostr::Filter->parse_search_extensions('best nostr apps');
    is($result->{terms}, ['best', 'nostr', 'apps'], 'all words are terms');
    is($result->{extensions}, {}, 'no extensions');
};

subtest 'parse_search_extensions: only extensions' => sub {
    my $result = Net::Nostr::Filter->parse_search_extensions('language:en nsfw:false');
    is($result->{terms}, [], 'no terms');
    is($result->{extensions}{language}, 'en', 'language');
    is($result->{extensions}{nsfw}, 'false', 'nsfw');
};

###############################################################################
# "Relay MAY support these extensions"
# include:spam, domain:<domain>, language:<code>, sentiment:<value>, nsfw:<bool>
###############################################################################

subtest 'parse_search_extensions: include:spam extension' => sub {
    my $result = Net::Nostr::Filter->parse_search_extensions('nostr include:spam');
    is($result->{extensions}{'include'}, 'spam', 'include:spam parsed');
};

subtest 'parse_search_extensions: domain extension' => sub {
    my $result = Net::Nostr::Filter->parse_search_extensions('news domain:example.com');
    is($result->{extensions}{domain}, 'example.com', 'domain parsed');
};

subtest 'parse_search_extensions: language extension' => sub {
    my $result = Net::Nostr::Filter->parse_search_extensions('hello language:en');
    is($result->{extensions}{language}, 'en', 'language code parsed');
};

subtest 'parse_search_extensions: sentiment extension' => sub {
    my $result = Net::Nostr::Filter->parse_search_extensions('sentiment:positive');
    is($result->{extensions}{sentiment}, 'positive', 'sentiment parsed');
};

subtest 'parse_search_extensions: nsfw extension' => sub {
    my $result = Net::Nostr::Filter->parse_search_extensions('art nsfw:false');
    is($result->{extensions}{nsfw}, 'false', 'nsfw parsed');
};

###############################################################################
# "Clients SHOULD use the supported_nips field to learn if a relay supports
#  search filter"
###############################################################################

subtest 'relay info supported_nips can include 50' => sub {
    require Net::Nostr::RelayInfo;
    my $info = Net::Nostr::RelayInfo->new(supported_nips => [1, 50]);
    my $has_50 = grep { $_ == 50 } @{$info->supported_nips};
    ok($has_50, 'NIP-50 can be in supported_nips');
};

###############################################################################
# Round-trip: REQ message with search parses back correctly
# "Clients MAY send search filter queries to any relay"
###############################################################################

subtest 'search field round-trips through REQ serialize/parse' => sub {
    my $filter = Net::Nostr::Filter->new(kinds => [1], search => 'nostr apps');
    my $msg = Net::Nostr::Message->new(
        type            => 'REQ',
        subscription_id => 'search-sub',
        filters         => [$filter],
    );
    my $json = $msg->serialize;
    my $parsed = Net::Nostr::Message->parse($json);
    is($parsed->filters->[0]->search, 'nostr apps', 'search preserved after round-trip');
    is($parsed->filters->[0]->kinds, [1], 'kinds preserved after round-trip');
};

###############################################################################
# Edge cases
###############################################################################

subtest 'matches: empty search string matches everything' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT);
    my $filter = Net::Nostr::Filter->new(search => '');
    ok($filter->matches($event), 'empty search matches any event');
};

subtest 'matches: search on event with empty content' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT, content => '');
    my $filter = Net::Nostr::Filter->new(search => 'nostr');
    ok(!$filter->matches($event), 'search term not found in empty content');
};

subtest 'matches: search with no filter does not constrain' => sub {
    my $event = Net::Nostr::Event->new(%BASE_EVENT);
    my $filter = Net::Nostr::Filter->new(kinds => [1]);
    ok($filter->matches($event), 'no search field means no search constraint');
};

subtest 'parse_search_extensions: empty string' => sub {
    my $result = Net::Nostr::Filter->parse_search_extensions('');
    is($result->{terms}, [], 'no terms from empty string');
    is($result->{extensions}, {}, 'no extensions from empty string');
};

subtest 'parse_search_extensions: undef returns empty' => sub {
    my $result = Net::Nostr::Filter->parse_search_extensions(undef);
    is($result->{terms}, [], 'no terms from undef');
    is($result->{extensions}, {}, 'no extensions from undef');
};

done_testing;
