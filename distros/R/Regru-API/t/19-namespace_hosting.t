use strict;
use warnings;
use Test::More tests => 2;
use t::lib::NamespaceClient;
use t::lib::Connection;

SKIP: {
    my $planned = 2;
    my $client = t::lib::NamespaceClient->hosting;

    skip 'No connection to an API endpoint.', $planned   unless t::lib::Connection->check($client->endpoint);
    skip 'Exceeded allowed connection rate.', $planned   unless t::lib::NamespaceClient->rate_limits_avail;


    subtest 'Namespace methods (nop)' => sub {
        plan tests => 1;

        my $resp;

        # /hosting/nop
        $resp = $client->nop();
        ok $resp->is_success, 'nop() success';
    };


    subtest 'Namespace methods (overall)' => sub {
        unless ($ENV{REGRU_API_OVERALL_TESTING}) {
            diag 'Some tests were skipped. Set the REGRU_API_OVERALL_TESTING to execute them.';
            plan skip_all => '.';
        }
        else {
            plan tests => 3;
        }

        my $resp;

        # /hosting/get_jelastic_refill_url
        $resp = $client->get_jelastic_refill_url;
        ok $resp->is_success,                                   'get_jelastic_refill_url() success';

        # /hosting/set_jelastic_refill_url
        $resp = $client->set_jelastic_refill_url(
            url      => 'http://reg.ru/refill?service_id=<service_id>',
        );
        ok $resp->is_success,                                   'set_jelastic_refill_url() success';

        # /hosting/get_parallelswpb_constructor_url
        $resp = $client->get_parallelswpb_constructor_url(
            service_id => 2312676,
        );
        ok $resp->is_success,                                   'get_parallelswpb_constructor_url() success';
    };

}

1;
