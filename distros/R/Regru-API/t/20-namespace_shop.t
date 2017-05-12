use strict;
use warnings;
use Test::More tests => 2;
use t::lib::NamespaceClient;
use t::lib::Connection;

SKIP: {
    my $planned = 2;
    my $client = t::lib::NamespaceClient->shop;

    skip 'No connection to an API endpoint.', $planned   unless t::lib::Connection->check($client->endpoint);
    skip 'Exceeded allowed connection rate.', $planned   unless t::lib::NamespaceClient->rate_limits_avail;


    subtest 'Namespace methods (nop)' => sub {
        plan tests => 1;

        my $resp;

        # /shop/nop
        $resp = $client->nop();
        ok $resp->is_success, 'nop() success';
    };


    subtest 'Namespace methods (overall)' => sub {
        unless ($ENV{REGRU_API_OVERALL_TESTING}) {
            diag 'Some tests were skipped. Set the REGRU_API_OVERALL_TESTING to execute them.';
            plan skip_all => '.';
        }
        else {
            plan tests => 7;
        }

        my $resp;

        # /shop/get_info
        $resp = $client->get_info;
        ok $resp->is_success,                                   'get_info() success';

        # /shop/get_category_list
        $resp = $client->get_category_list;
        ok $resp->is_success,                                   'get_category_list() success';

        # /shop/get_lot_list
        $resp = $client->get_lot_list(
            show_my_lots => 1,
            itemsonpage  => 10,
        );
        ok $resp->is_success,                                   'get_lot_list() success';

        # /shop/get_suggested_tags
        $resp = $client->get_suggested_tags(
            limit => 13,
        );
        ok $resp->is_success,                                   'get_suggested_tags() success';

        # /shop/add_lot
        $resp = $client->add_lot(
            description => 'great deal!',
            category_ids => [qw( 4 10 )],
            rent => 0,
            keywords => [qw( foo bar baz )],
            price => 200,
            lots => [
                { price => 201, rent_price => 0, dname => 'foo.com' },
                { price => 203, rent_price => 0, dname => 'bar.net' },
            ],
            sold_with => '',
            deny_bids_lower_rejected => 1,
            lot_price_type => 'fixed',
        );
        ok $resp->is_success,                                   'add_lot() success';

        # /shop/update_lot
        $resp = $client->update_lot(
            dname => 'foo.com',
            description => 'great deal!',
            category_ids => [qw( 4 10 )],
            rent => 0,
            keywords => [qw( foo bar baz )],
            price => 200,
            sold_with => 'tm',
            deny_bids_lower_rejected => 1,
            lot_price_type => 'offer',
        );
        ok $resp->is_success,                                   'update_lot() success';

        # /shop/delete_lot
        $resp = $client->delete_lot(
            dname => 'foo.com',
        );
        ok $resp->is_success,                                   'delete_lot() success';
    };

}

1;
