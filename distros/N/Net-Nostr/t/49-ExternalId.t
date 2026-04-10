use strictures 2;
use Test2::V0 -no_srand => 1;

use Net::Nostr::ExternalId;

###############################################################################
# POD example: url_tags
###############################################################################

subtest 'POD: url_tags' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->url_tags(
        'https://myblog.example.com/post/2012-03-27/hello-world',
    );
    is($i, ['i', 'https://myblog.example.com/post/2012-03-27/hello-world']);
    is($k, ['k', 'web']);
};

###############################################################################
# POD example: isbn_tags (hyphens stripped)
###############################################################################

subtest 'POD: isbn_tags' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->isbn_tags('978-0-7653-8203-0');
    is($i, ['i', 'isbn:9780765382030']);
};

###############################################################################
# POD example: geo_tags (lowercased)
###############################################################################

subtest 'POD: geo_tags' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->geo_tags('EZS42E44YX96');
    is($i, ['i', 'geo:ezs42e44yx96']);
};

###############################################################################
# POD example: country_tags (uppercased)
###############################################################################

subtest 'POD: country_tags' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->country_tags('ve');
    is($i, ['i', 'iso3166:VE']);
};

###############################################################################
# POD example: isan_tags with hint
###############################################################################

subtest 'POD: isan_tags with hint' => sub {
    my ($i, $k) = Net::Nostr::ExternalId->isan_tags(
        '0000-0000-401A-0000-7',
        hint => 'https://www.imdb.com/title/tt0120737',
    );
    is($i, ['i', 'isan:0000-0000-401A-0000-7', 'https://www.imdb.com/title/tt0120737']);
};

###############################################################################
# POD example: parse
###############################################################################

subtest 'POD: parse' => sub {
    my $parsed = Net::Nostr::ExternalId->parse('isbn:9780765382030');
    is($parsed->{type}, 'isbn');
    is($parsed->{value}, '9780765382030');
};

###############################################################################
# POD example: kind_for
###############################################################################

subtest 'POD: kind_for' => sub {
    my $kind = Net::Nostr::ExternalId->kind_for('geo:ezs42e44yx96');
    is($kind, 'geo');
};

###############################################################################
# POD example: new
###############################################################################

subtest 'POD: new' => sub {
    my $id = Net::Nostr::ExternalId->new(
        type  => 'isbn',
        value => '9780765382030',
    );
    is($id->type, 'isbn');
    is($id->value, '9780765382030');
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

###############################################################################
# Public methods available
###############################################################################

subtest 'public methods available' => sub {
    can_ok('Net::Nostr::ExternalId',
        qw(new parse kind_for
           url_tags isbn_tags geo_tags country_tags isan_tags doi_tags
           hashtag_tags podcast_feed_tags podcast_episode_tags
           podcast_publisher_tags blockchain_tx_tags blockchain_address_tags
           type value blockchain chain_id hint));
};

done_testing;
