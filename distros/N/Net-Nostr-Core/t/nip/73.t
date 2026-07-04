use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::ExternalId;

###############################################################################
# Spec: i tags are used for referencing external content ids, with k tags
# representing the external content id kind
###############################################################################

###############################################################################
# URLs (type: web)
###############################################################################

subtest 'url: basic' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->url_tags(
        'https://myblog.example.com/post/2012-03-27/hello-world',
    );
    is($i, ['i', 'https://myblog.example.com/post/2012-03-27/hello-world'],
        'i tag');
    is($k, ['k', 'web'], 'k tag');
};

# Spec example: exact JSON from NIP-73
subtest 'url: spec example' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->url_tags(
        'https://myblog.example.com/post/2012-03-27/hello-world',
    );
    is($i->[0], 'i');
    is($i->[1], 'https://myblog.example.com/post/2012-03-27/hello-world');
    is($k->[0], 'k');
    is($k->[1], 'web');
};

# Spec: URLs normalized, no fragment
subtest 'url: fragment stripped' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->url_tags(
        'https://example.com/page#section',
    );
    is($i->[1], 'https://example.com/page', 'fragment stripped');
};

# MAY: optional URL hint
subtest 'url: with hint' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->url_tags(
        'https://example.com/page',
        hint => 'https://example.com/alt',
    );
    is($i->[2], 'https://example.com/alt', 'hint in i tag');
};

###############################################################################
# Books (type: isbn)
###############################################################################

# Spec example: Book ISBN
subtest 'isbn: spec example' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->isbn_tags('9780765382030');
    is($i, ['i', 'isbn:9780765382030'], 'i tag');
    is($k, ['k', 'isbn'], 'k tag');
};

# Spec: ISBNs MUST be referenced without hyphens
subtest 'isbn: hyphens stripped' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->isbn_tags('978-0-7653-8203-0');
    is($i->[1], 'isbn:9780765382030', 'hyphens removed');
};

subtest 'isbn: with hint' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->isbn_tags(
        '9780765382030',
        hint => 'https://isbnsearch.org/isbn/9780765382030',
    );
    is($i->[2], 'https://isbnsearch.org/isbn/9780765382030', 'hint');
};

###############################################################################
# Geohashes (type: geo)
###############################################################################

# Spec example: Geohash
subtest 'geo: spec example' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->geo_tags('ezs42e44yx96');
    is($i, ['i', 'geo:ezs42e44yx96'], 'i tag');
    is($k, ['k', 'geo'], 'k tag');
};

# Spec: Geohashes MUST be lowercase
subtest 'geo: uppercased input lowered' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->geo_tags('EZS42E44YX96');
    is($i->[1], 'geo:ezs42e44yx96', 'lowercased');
};

subtest 'geo: with hint' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->geo_tags(
        'ezs42e44yx96',
        hint => 'https://www.movable-type.co.uk/scripts/geohash.html',
    );
    is($i->[2], 'https://www.movable-type.co.uk/scripts/geohash.html', 'hint');
};

###############################################################################
# Countries (type: iso3166)
###############################################################################

# Spec example: Country (Venezuela)
subtest 'country: spec example VE' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->country_tags('VE');
    is($i, ['i', 'iso3166:VE'], 'i tag');
    is($k, ['k', 'iso3166'], 'k tag');
};

# Spec example: Subdivision (California, USA)
subtest 'country: spec example US-CA' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->country_tags('US-CA');
    is($i, ['i', 'iso3166:US-CA'], 'i tag');
    is($k, ['k', 'iso3166'], 'k tag');
};

# Spec: ISO 3166 codes MUST be uppercase
subtest 'country: lowercased input uppercased' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->country_tags('ve');
    is($i->[1], 'iso3166:VE', 'uppercased');
};

subtest 'country: subdivision uppercased' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->country_tags('us-ca');
    is($i->[1], 'iso3166:US-CA', 'uppercased');
};

###############################################################################
# Movies (type: isan)
###############################################################################

# Spec example: Movie ISAN
subtest 'isan: spec example' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->isan_tags('0000-0000-401A-0000-7');
    is($i, ['i', 'isan:0000-0000-401A-0000-7'], 'i tag');
    is($k, ['k', 'isan'], 'k tag');
};

# Spec: ISANs SHOULD be referenced without the version part — we accept as-is
subtest 'isan: with hint' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->isan_tags(
        '0000-0000-401A-0000-7',
        hint => 'https://www.imdb.com/title/tt0120737',
    );
    is($i->[2], 'https://www.imdb.com/title/tt0120737', 'hint');
};

###############################################################################
# Papers (type: doi)
###############################################################################

subtest 'doi: basic' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->doi_tags('10.1000/xyz123');
    is($i, ['i', 'doi:10.1000/xyz123'], 'i tag');
    is($k, ['k', 'doi'], 'k tag');
};

# Spec: DOI id MUST be lowercase
subtest 'doi: lowercased' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->doi_tags('10.1000/XYZ123');
    is($i->[1], 'doi:10.1000/xyz123', 'lowercased');
};

###############################################################################
# Hashtags (type: #)
###############################################################################

subtest 'hashtag: basic' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->hashtag_tags('nostr');
    is($i, ['i', '#nostr'], 'i tag');
    is($k, ['k', '#'], 'k tag');
};

# Spec: topic MUST be lowercase
subtest 'hashtag: lowercased' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->hashtag_tags('NoStr');
    is($i->[1], '#nostr', 'lowercased');
};

###############################################################################
# Podcast Feeds (type: podcast:guid)
###############################################################################

# Spec example: Podcast RSS Feed GUID
subtest 'podcast_feed: spec example' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->podcast_feed_tags(
        'c90e609a-df1e-596a-bd5e-57bcc8aad6cc',
    );
    is($i, ['i', 'podcast:guid:c90e609a-df1e-596a-bd5e-57bcc8aad6cc'], 'i tag');
    is($k, ['k', 'podcast:guid'], 'k tag');
};

###############################################################################
# Podcast Episodes (type: podcast:item:guid)
###############################################################################

# Spec example: Podcast RSS Item GUID
subtest 'podcast_episode: spec example' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->podcast_episode_tags(
        'd98d189b-dc7b-45b1-8720-d4b98690f31f',
    );
    is($i, ['i', 'podcast:item:guid:d98d189b-dc7b-45b1-8720-d4b98690f31f'], 'i tag');
    is($k, ['k', 'podcast:item:guid'], 'k tag');
};

# MAY: URL hint (spec example)
subtest 'podcast_episode: with hint (spec example)' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->podcast_episode_tags(
        'd98d189b-dc7b-45b1-8720-d4b98690f31f',
        hint => 'https://fountain.fm/episode/z1y9TMQRuqXl2awyrQxg',
    );
    is($i->[2], 'https://fountain.fm/episode/z1y9TMQRuqXl2awyrQxg', 'hint');
};

###############################################################################
# Podcast Publishers (type: podcast:publisher:guid)
###############################################################################

# Spec example: Podcast RSS Publisher GUID
subtest 'podcast_publisher: spec example' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->podcast_publisher_tags(
        '18bcbf10-6701-4ffb-b255-bc057390d738',
    );
    is($i, ['i', 'podcast:publisher:guid:18bcbf10-6701-4ffb-b255-bc057390d738'], 'i tag');
    is($k, ['k', 'podcast:publisher:guid'], 'k tag');
};

###############################################################################
# Blockchain Transactions
###############################################################################

# Spec example: Bitcoin tx
subtest 'blockchain_tx: bitcoin spec example' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->blockchain_tx_tags(
        'bitcoin',
        'a1075db55d416d3ca199f55b6084e2115b9345e16c5cf302fc80e9d5fbf5d48d',
    );
    is($i, ['i', 'bitcoin:tx:a1075db55d416d3ca199f55b6084e2115b9345e16c5cf302fc80e9d5fbf5d48d'],
        'i tag');
    is($k, ['k', 'bitcoin:tx'], 'k tag');
};

# Spec: txid MUST be hex, lowercase
subtest 'blockchain_tx: txid lowercased' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->blockchain_tx_tags(
        'bitcoin',
        'A1075DB55D416D3CA199F55B6084E2115B9345E16C5CF302FC80E9D5FBF5D48D',
    );
    is($i->[1], 'bitcoin:tx:a1075db55d416d3ca199f55b6084e2115b9345e16c5cf302fc80e9d5fbf5d48d',
        'lowercased');
};

# Spec example: Ethereum tx with chainId
subtest 'blockchain_tx: ethereum mainnet spec example' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->blockchain_tx_tags(
        'ethereum',
        '0x98f7812be496f97f80e2e98d66358d1fc733cf34176a8356d171ea7fbbe97ccd',
        chain_id => 100,
    );
    is($i, ['i', 'ethereum:100:tx:0x98f7812be496f97f80e2e98d66358d1fc733cf34176a8356d171ea7fbbe97ccd'],
        'i tag');
    is($k, ['k', 'ethereum:tx'], 'k tag');
};

# Ethereum tx lowercased
subtest 'blockchain_tx: ethereum tx lowercased' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->blockchain_tx_tags(
        'ethereum',
        '0x98F7812BE496F97F80E2E98D66358D1FC733CF34176A8356D171EA7FBBE97CCD',
        chain_id => 1,
    );
    like($i->[1], qr/0x98f7812be496f97f80e2e98d66358d1fc733cf34176a8356d171ea7fbbe97ccd$/,
        'lowercased');
};

###############################################################################
# Blockchain Addresses
###############################################################################

# Spec example: Bitcoin address (base58, case sensitive)
subtest 'blockchain_address: bitcoin base58 spec example' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->blockchain_address_tags(
        'bitcoin',
        '1HQ3Go3ggs8pFnXuHVHRytPCq5fGG8Hbhx',
    );
    is($i, ['i', 'bitcoin:address:1HQ3Go3ggs8pFnXuHVHRytPCq5fGG8Hbhx'], 'i tag');
    is($k, ['k', 'bitcoin:address'], 'k tag');
};

# Spec: Bitcoin bech32 addresses are lowercase
subtest 'blockchain_address: bitcoin bech32 lowercase' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->blockchain_address_tags(
        'bitcoin',
        'bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq',
    );
    is($i->[1], 'bitcoin:address:bc1qar0srrr7xfkvy5l643lydnw9re59gtzzwf5mdq', 'bech32 preserved');
};

# Spec example: Ethereum address with chainId
subtest 'blockchain_address: ethereum spec example' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->blockchain_address_tags(
        'ethereum',
        '0xd8da6bf26964af9d7eed9e03e53415d37aa96045',
        chain_id => 1,
    );
    is($i, ['i', 'ethereum:1:address:0xd8da6bf26964af9d7eed9e03e53415d37aa96045'],
        'i tag');
    is($k, ['k', 'ethereum:address'], 'k tag');
};

# Spec: Ethereum addresses are hex, lowercase
subtest 'blockchain_address: ethereum address lowercased' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->blockchain_address_tags(
        'ethereum',
        '0xD8dA6BF26964aF9D7eEd9e03E53415D37aA96045',
        chain_id => 1,
    );
    is($i->[1], 'ethereum:1:address:0xd8da6bf26964af9d7eed9e03e53415d37aa96045',
        'lowercased');
};

###############################################################################
# parse: identify type from i tag value
###############################################################################

subtest 'parse: url' => sub {
    my $parsed = Net::Nostr::ExternalId->parse('https://example.com/page');
    is($parsed->{type}, 'web', 'type');
    is($parsed->{value}, 'https://example.com/page', 'value');
};

subtest 'parse: isbn' => sub {
    my $parsed = Net::Nostr::ExternalId->parse('isbn:9780765382030');
    is($parsed->{type}, 'isbn', 'type');
    is($parsed->{value}, '9780765382030', 'value');
};

subtest 'parse: geo' => sub {
    my $parsed = Net::Nostr::ExternalId->parse('geo:ezs42e44yx96');
    is($parsed->{type}, 'geo', 'type');
    is($parsed->{value}, 'ezs42e44yx96', 'value');
};

subtest 'parse: iso3166 country' => sub {
    my $parsed = Net::Nostr::ExternalId->parse('iso3166:VE');
    is($parsed->{type}, 'iso3166', 'type');
    is($parsed->{value}, 'VE', 'value');
};

subtest 'parse: iso3166 subdivision' => sub {
    my $parsed = Net::Nostr::ExternalId->parse('iso3166:US-CA');
    is($parsed->{type}, 'iso3166', 'type');
    is($parsed->{value}, 'US-CA', 'value');
};

subtest 'parse: isan' => sub {
    my $parsed = Net::Nostr::ExternalId->parse('isan:0000-0000-401A-0000-7');
    is($parsed->{type}, 'isan', 'type');
    is($parsed->{value}, '0000-0000-401A-0000-7', 'value');
};

subtest 'parse: doi' => sub {
    my $parsed = Net::Nostr::ExternalId->parse('doi:10.1000/xyz123');
    is($parsed->{type}, 'doi', 'type');
    is($parsed->{value}, '10.1000/xyz123', 'value');
};

subtest 'parse: hashtag' => sub {
    my $parsed = Net::Nostr::ExternalId->parse('#nostr');
    is($parsed->{type}, '#', 'type');
    is($parsed->{value}, 'nostr', 'value');
};

subtest 'parse: podcast feed' => sub {
    my $parsed = Net::Nostr::ExternalId->parse('podcast:guid:c90e609a-df1e-596a-bd5e-57bcc8aad6cc');
    is($parsed->{type}, 'podcast:guid', 'type');
    is($parsed->{value}, 'c90e609a-df1e-596a-bd5e-57bcc8aad6cc', 'value');
};

subtest 'parse: podcast episode' => sub {
    my $parsed = Net::Nostr::ExternalId->parse('podcast:item:guid:d98d189b-dc7b-45b1-8720-d4b98690f31f');
    is($parsed->{type}, 'podcast:item:guid', 'type');
    is($parsed->{value}, 'd98d189b-dc7b-45b1-8720-d4b98690f31f', 'value');
};

subtest 'parse: podcast publisher' => sub {
    my $parsed = Net::Nostr::ExternalId->parse('podcast:publisher:guid:18bcbf10-6701-4ffb-b255-bc057390d738');
    is($parsed->{type}, 'podcast:publisher:guid', 'type');
    is($parsed->{value}, '18bcbf10-6701-4ffb-b255-bc057390d738', 'value');
};

subtest 'parse: bitcoin tx' => sub {
    my $parsed = Net::Nostr::ExternalId->parse(
        'bitcoin:tx:a1075db55d416d3ca199f55b6084e2115b9345e16c5cf302fc80e9d5fbf5d48d',
    );
    is($parsed->{type}, 'bitcoin:tx', 'type');
    is($parsed->{value}, 'a1075db55d416d3ca199f55b6084e2115b9345e16c5cf302fc80e9d5fbf5d48d', 'value');
    is($parsed->{blockchain}, 'bitcoin', 'blockchain');
    is($parsed->{chain_id}, undef, 'no chain_id');
};

subtest 'parse: bitcoin address' => sub {
    my $parsed = Net::Nostr::ExternalId->parse(
        'bitcoin:address:1HQ3Go3ggs8pFnXuHVHRytPCq5fGG8Hbhx',
    );
    is($parsed->{type}, 'bitcoin:address', 'type');
    is($parsed->{value}, '1HQ3Go3ggs8pFnXuHVHRytPCq5fGG8Hbhx', 'value');
    is($parsed->{blockchain}, 'bitcoin', 'blockchain');
};

subtest 'parse: ethereum tx with chain_id' => sub {
    my $parsed = Net::Nostr::ExternalId->parse(
        'ethereum:100:tx:0x98f7812be496f97f80e2e98d66358d1fc733cf34176a8356d171ea7fbbe97ccd',
    );
    is($parsed->{type}, 'ethereum:tx', 'type');
    is($parsed->{value}, '0x98f7812be496f97f80e2e98d66358d1fc733cf34176a8356d171ea7fbbe97ccd', 'value');
    is($parsed->{blockchain}, 'ethereum', 'blockchain');
    is($parsed->{chain_id}, 100, 'chain_id');
};

subtest 'parse: ethereum address with chain_id' => sub {
    my $parsed = Net::Nostr::ExternalId->parse(
        'ethereum:1:address:0xd8da6bf26964af9d7eed9e03e53415d37aa96045',
    );
    is($parsed->{type}, 'ethereum:address', 'type');
    is($parsed->{value}, '0xd8da6bf26964af9d7eed9e03e53415d37aa96045', 'value');
    is($parsed->{blockchain}, 'ethereum', 'blockchain');
    is($parsed->{chain_id}, 1, 'chain_id');
};

subtest 'parse: unknown returns undef' => sub {
    my $parsed = Net::Nostr::ExternalId->parse('unknown:value');
    is($parsed, undef, 'undef for unknown');
};

###############################################################################
# kind_for: derive k tag value from i tag value
###############################################################################

subtest 'kind_for: all types' => sub {
    is(Net::Nostr::ExternalId->kind_for('https://example.com'), 'web', 'url');
    is(Net::Nostr::ExternalId->kind_for('isbn:123'), 'isbn', 'isbn');
    is(Net::Nostr::ExternalId->kind_for('geo:abc'), 'geo', 'geo');
    is(Net::Nostr::ExternalId->kind_for('iso3166:US'), 'iso3166', 'iso3166');
    is(Net::Nostr::ExternalId->kind_for('isan:0000'), 'isan', 'isan');
    is(Net::Nostr::ExternalId->kind_for('doi:10.1000/x'), 'doi', 'doi');
    is(Net::Nostr::ExternalId->kind_for('#nostr'), '#', 'hashtag');
    is(Net::Nostr::ExternalId->kind_for('podcast:guid:abc'), 'podcast:guid', 'podcast feed');
    is(Net::Nostr::ExternalId->kind_for('podcast:item:guid:abc'), 'podcast:item:guid', 'podcast episode');
    is(Net::Nostr::ExternalId->kind_for('podcast:publisher:guid:abc'), 'podcast:publisher:guid', 'podcast publisher');
    is(Net::Nostr::ExternalId->kind_for('bitcoin:tx:abc'), 'bitcoin:tx', 'bitcoin tx');
    is(Net::Nostr::ExternalId->kind_for('bitcoin:address:abc'), 'bitcoin:address', 'bitcoin address');
    is(Net::Nostr::ExternalId->kind_for('ethereum:1:tx:abc'), 'ethereum:tx', 'ethereum tx');
    is(Net::Nostr::ExternalId->kind_for('ethereum:1:address:abc'), 'ethereum:address', 'ethereum address');
};

subtest 'kind_for: unknown returns undef' => sub {
    is(Net::Nostr::ExternalId->kind_for('unknown:value'), undef, 'undef');
};

###############################################################################
# Constructor: unknown args rejected
###############################################################################

subtest 'constructor: unknown args rejected' => sub {
    like(
        dies { Net::Nostr::ExternalId->new(bogus => 1) },
        qr/unknown/i,
        'unknown arg rejected'
    );
};

done_testing;
