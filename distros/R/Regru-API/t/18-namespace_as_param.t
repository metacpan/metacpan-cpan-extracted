use strict;
use warnings;
use Test::More tests => 1;
use t::lib::NamespaceClient;
use t::lib::Connection;

SKIP: {
    my $planned = 1;
    my $client = t::lib::NamespaceClient->root;

    skip 'No connection to an API endpoint.', $planned   unless t::lib::Connection->check($client->endpoint);
    skip 'Exceeded allowed connection rate.', $planned   unless t::lib::NamespaceClient->rate_limits_avail;

    subtest 'Grab namespace from parameters' => sub {
        plan tests => 10;

        my $resp;

        # nop() API call shortcut
        my $nop = sub { $client->api_request('nop', @_) };

        # /nop (default)
        $resp = $nop->();
        ok $resp->is_success,                                   'nop() default success';

        # /nop (with namespace)
        $resp = $nop->(namespace => '');
        ok $resp->is_success,                                   'nop() with namespace success';

        # /user/nop
        $resp = $nop->(namespace => 'user');
        ok $resp->is_success,                                   'user/nop() success';

        # /domain/nop
        $resp = $nop->(namespace => 'domain');
        ok $resp->is_success,                                   'domain/nop() success';

        # /zone/nop
        $resp = $nop->(namespace => 'zone', dname => 'test.ru');
        ok $resp->is_success,                                   'zone/nop() success';

        # /bill/nop
        $resp = $nop->(namespace => 'bill', bill_id => 1234);
        ok $resp->is_success,                                   'bill/nop() success';

        # /folder/nop
        $resp = $nop->(namespace => 'folder', folder_name => 'qqq');
        ok $resp->is_success,                                   'folder/nop() success';

        # /service/nop
        $resp = $nop->(namespace => 'service', dname => 'test.ru');
        ok $resp->is_success,                                   'service/nop() success';

        # /hosting/nop
        $resp = $nop->(namespace => 'hosting');
        ok $resp->is_success,                                   'hosting/nop() success';

        # /shop/nop
        $resp = $nop->(namespace => 'shop');
        ok $resp->is_success,                                   'shop/nop() success';
    };
}

1;
