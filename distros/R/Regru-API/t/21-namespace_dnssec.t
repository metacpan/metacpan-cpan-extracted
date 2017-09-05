use strict;
use warnings;
use Test::More tests => 3;
use t::lib::NamespaceClient;
use t::lib::Connection;

my $api_avail;

subtest 'Generic behaviour' => sub {
    plan tests => 2;

    my @methods = qw(
        nop
        get_status
        enable
        disable
        renew_ksk
        renew_zsk
        get_records
        add_keys
    );

    my $client = t::lib::NamespaceClient->dnssec;

    isa_ok $client, 'Regru::API::DNSSEC';
    can_ok $client, @methods;
};

SKIP: {
    my $planned = 2;
    my $client = t::lib::NamespaceClient->dnssec;

    skip 'No connection to an API endpoint.', $planned   unless t::lib::Connection->check($client->endpoint);
    skip 'Exceeded allowed connection rate.', $planned   unless t::lib::NamespaceClient->rate_limits_avail;

    subtest 'Namespace methods (nop)' => sub {
        plan tests => 1;

        my $resp;

        # /dnssec/nop
        $resp = $client->nop(dname => 'test.ru');
        ok $resp->is_success,                                   'nop() success';
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

        # /dnssec/get_status
        $resp = $client->get_status(
            domains   => [ { dname => 'test.ru' } ],
        );
        ok $resp->is_success,                                   'get_status() success';

        # /dnssec/enable
        $resp = $client->enable(
            domains   => [ { dname => 'test.ru' } ],
        );
        ok $resp->is_success,                                   'enable() success';

        # /dnssec/disable
        $resp = $client->disable(
            domains         => [ { dname => 'test.ru' } ],
        );
        ok $resp->is_success,                                   'disable() success';

        # /dnssec/renew_ksk
        $resp = $client->renew_ksk(
            domains         => [ { dname => 'test.ru' } ],
        );
        ok $resp->is_success,                                   'renew_ksk() success';

        # /dnssec/renew_zsk
        $resp = $client->renew_zsk(
            domains         => [ { dname => 'test.ru' } ],
        );
        ok $resp->is_success,                                   'renew_zsk() success';

        # /dnssec/get_records
        $resp = $client->get_records(
            domains         => [ { dname => 'test.ru' } ],
        );
        ok $resp->is_success,                                   'get_records() success';

        # /dnssec/add_keys
        $resp = $client->add_keys(
            domains         => [ { dname => 'test.ru', records => [ "test.ru. 3600 IN DS 2371 13 2 4508a7798c38867c94091bbf91edaf9e6dbf56da0606c748d3d1d1b2382c1602" ] } ],
        );
        ok $resp->is_success,                                   'add_keys() success';
    };
}

1;
