#!/usr/bin/env perl
# Mock-backed unit tests translated from
# signalwire-python/tests/unit/rest/test_registry_mock.py.
#
# The 10DLC Campaign Registry namespace exposes four sub-resources:
# brands, campaigns, orders, numbers. All endpoints sit under
# /api/relay/rest/registry/beta.

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Test::More;

use MockTest;

my $REG_BASE = '/api/relay/rest/registry/beta';

# ---- Brands --------------------------------------------------------------

subtest 'TestRegistryBrands' => sub {
    subtest 'test_list_returns_dict' => sub {
        my $client = MockTest::client();
        my $body = $client->registry->brands->list();
        is(ref $body, 'HASH', 'expected hashref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'GET', 'GET recorded');
        is($last->{path}, "$REG_BASE/brands", 'path matches');
        isnt($last->{matched_route}, undef, 'matched_route set');
    };

    subtest 'test_get_uses_id_in_path' => sub {
        my $client = MockTest::client();
        my $body = $client->registry->brands->get('brand-77');
        is(ref $body, 'HASH', 'expected hashref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'GET', 'GET recorded');
        is($last->{path}, "$REG_BASE/brands/brand-77", 'path matches');
    };

    subtest 'test_list_campaigns_uses_brand_subpath' => sub {
        my $client = MockTest::client();
        my $body = $client->registry->brands->list_campaigns('brand-1');
        is(ref $body, 'HASH', 'expected hashref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'GET', 'GET recorded');
        is($last->{path}, "$REG_BASE/brands/brand-1/campaigns",
            'path matches');
        isnt($last->{matched_route}, undef, 'matched_route set');
    };

    subtest 'test_create_campaign_posts_to_brand_subpath' => sub {
        my $client = MockTest::client();
        my $body = $client->registry->brands->create_campaign(
            'brand-2',
            usecase     => 'LOW_VOLUME',
            description => 'MFA',
        );
        is(ref $body, 'HASH', 'expected hashref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'POST', 'POST recorded');
        is($last->{path}, "$REG_BASE/brands/brand-2/campaigns",
            'path matches');
        is(ref $last->{body}, 'HASH', 'body is hashref');
        is($last->{body}{usecase}, 'LOW_VOLUME', 'usecase forwarded');
        is($last->{body}{description}, 'MFA', 'description forwarded');
    };
};

# ---- Campaigns -----------------------------------------------------------

subtest 'TestRegistryCampaigns' => sub {
    subtest 'test_get_uses_id_in_path' => sub {
        my $client = MockTest::client();
        my $body = $client->registry->campaigns->get('camp-1');
        is(ref $body, 'HASH', 'expected hashref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'GET', 'GET recorded');
        is($last->{path}, "$REG_BASE/campaigns/camp-1", 'path matches');
    };

    subtest 'test_update_uses_put' => sub {
        my $client = MockTest::client();
        # RegistryCampaigns.update calls _http->put(...) — distinct from
        # the generic CrudResource which uses PATCH.
        my $body = $client->registry->campaigns->update(
            'camp-2', description => 'Updated',
        );
        is(ref $body, 'HASH', 'expected hashref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'PUT', 'PUT recorded (not PATCH)');
        is($last->{path}, "$REG_BASE/campaigns/camp-2", 'path matches');
        is(ref $last->{body}, 'HASH', 'body is hashref');
        is($last->{body}{description}, 'Updated', 'description forwarded');
    };

    subtest 'test_list_numbers_uses_numbers_subpath' => sub {
        my $client = MockTest::client();
        my $body = $client->registry->campaigns->list_numbers('camp-3');
        is(ref $body, 'HASH', 'expected hashref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'GET', 'GET recorded');
        is($last->{path}, "$REG_BASE/campaigns/camp-3/numbers",
            'path matches');
        isnt($last->{matched_route}, undef, 'matched_route set');
    };

    subtest 'test_create_order_posts_to_orders_subpath' => sub {
        my $client = MockTest::client();
        my $body = $client->registry->campaigns->create_order(
            'camp-4', numbers => ['pn-1', 'pn-2'],
        );
        is(ref $body, 'HASH', 'expected hashref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'POST', 'POST recorded');
        is($last->{path}, "$REG_BASE/campaigns/camp-4/orders",
            'path matches');
        is(ref $last->{body}, 'HASH', 'body is hashref');
        is_deeply($last->{body}{numbers}, ['pn-1', 'pn-2'], 'numbers forwarded');
    };
};

# ---- Orders --------------------------------------------------------------

subtest 'TestRegistryOrders' => sub {
    subtest 'test_get_uses_id_in_path' => sub {
        my $client = MockTest::client();
        my $body = $client->registry->orders->get('order-1');
        is(ref $body, 'HASH', 'expected hashref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'GET', 'GET recorded');
        is($last->{path}, "$REG_BASE/orders/order-1", 'path matches');
        isnt($last->{matched_route}, undef, 'matched_route set');
    };
};

# ---- Numbers (10DLC assigned phone numbers) -----------------------------

subtest 'TestRegistryNumbers' => sub {
    subtest 'test_delete_uses_id_in_path' => sub {
        my $client = MockTest::client();
        my $body = $client->registry->numbers->delete('num-1');
        # SDK turns 204/empty into {} so we still get a dict back.
        is(ref $body, 'HASH', 'delete returns hashref');

        my $last = MockTest::journal_last();
        is($last->{method}, 'DELETE', 'DELETE recorded');
        is($last->{path}, "$REG_BASE/numbers/num-1", 'path matches');
        isnt($last->{matched_route}, undef, 'matched_route set');
    };
};

done_testing();
