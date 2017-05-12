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
        add_alias
        add_aaaa
        add_cname
        add_mx
        add_ns
        add_txt
        add_srv
        add_spf
        get_resource_records
        update_records
        update_soa
        tune_forwarding
        clear_forwarding
        tune_parking
        clear_parking
        remove_record
        clear
    );

    my $client = t::lib::NamespaceClient->zone;

    isa_ok $client, 'Regru::API::Zone';
    can_ok $client, @methods;
};

SKIP: {
    my $planned = 2;
    my $client = t::lib::NamespaceClient->zone;

    skip 'No connection to an API endpoint.', $planned   unless t::lib::Connection->check($client->endpoint);
    skip 'Exceeded allowed connection rate.', $planned   unless t::lib::NamespaceClient->rate_limits_avail;

    subtest 'Namespace methods (nop)' => sub {
        plan tests => 1;

        my $resp;

        # /zone/nop
        $resp = $client->nop(dname => 'test.ru');
        ok $resp->is_success,                                   'nop() success';
    };

    subtest 'Namespace methods (overall)' => sub {
        unless ($ENV{REGRU_API_OVERALL_TESTING}) {
            diag 'Some tests were skipped. Set the REGRU_API_OVERALL_TESTING to execute them.';
            plan skip_all => '.';
        }
        else {
            plan tests => 16;
        }

        my $resp;

        # /zone/add_alias
        $resp = $client->add_alias(
            domains   => [ { dname => 'test.ru' } ],
            subdomain => '@',
            ipaddr    => '111.111.111.111'
        );
        ok $resp->is_success,                                   'add_alias() success';

        # /zone/add_aaaa
        $resp = $client->add_aaaa(
            domains   => [ { dname => 'test.ru' } ],
            subdomain => '@',
            ipaddr    => '111.111.111.111'  # XXX: O'RLY?
        );
        ok $resp->is_success,                                   'add_aaaa() success';

        # /zone/add_cname
        $resp = $client->add_cname(
            domains         => [ { dname => 'test.ru' } ],
            subdomain       => '@',
            canonical_name  => 'mx10.test.ru',
        );
        ok $resp->is_success,                                   'add_cname() success';

        # /zone/add_mx
        $resp = $client->add_mx(
            domains         => [ { dname => 'test.ru' } ],
            subdomain       => '@',
            mail_server     => 'mail.test.ru',
        );
        ok $resp->is_success,                                   'add_mx() success';

        # /zone/add_ns
        $resp = $client->add_ns(
            domains         => [ { dname => 'test.ru' } ],
            subdomain       => '@',
            dns_server      => 'dns.test.ru',
            record_number   => 10,
        );
        ok $resp->is_success,                                   'add_ns() success';

        # /zone/add_srv
        $resp = $client->add_srv(
            domains         => [ { dname => 'test.ru' } ],
            subdomain       => '@',
            service         => 'sip',
            target          => 'testtarget.ru',
            port            => 5060,
        );
        ok $resp->is_success,                                   'add_srv() success';

        # /zone/add_spf
        $resp = $client->add_spf(
            domains         => [ { dname => 'test.ru' } ],
            subdomain       => '@',
            text            => 'v=spf1 ~all',
        );
        ok $resp->is_success,                                   'add_spf() success';

        # /zone/get_resource_records
        $resp = $client->get_resource_records(
            domains => [ { dname => 'test.ru' } ],
        );
        ok $resp->is_success,                                   'get_resource_records() success';

        # /zone/update_records
        my $actions = [
            {   action          => 'add_alias',
                subdomain       => 'www',
                ipaddr          => '11.22.33.44'
            },
            {   action          => 'add_cname',
                subdomain       => '@',
                canonical_name  => 'www.test.ru'
            },
        ];
        $resp = $client->update_records(
            dname       => 'test.ru',
            action_list => $actions,
        );
        ok $resp->is_success,                                   'update_records() success';

        # /zone/update_soa
        $resp = $client->update_soa(
            dname       => 'test.ru',
            ttl         => '1d',
            miminum_ttl => '4h',
        );
        ok $resp->is_success,                                   'update_soa() success';

        # /zone/tune_forwarding
        $resp = $client->tune_forwarding(dname => 'test.ru');
        ok $resp->is_success,                                   'tune_forwarding() success';

        # /zone/clear_forwarding
        $resp = $client->clear_forwarding(dname => 'test.ru');
        ok $resp->is_success,                                   'clear_forwarding() success';

        # /zone/tune_parking
        $resp = $client->tune_parking(dname => 'test.ru');
        ok $resp->is_success,                                   'tune_parking() success';

        # /zone/clear/parking
        $resp = $client->clear_parking(dname => 'test.ru');
        ok $resp->is_success,                                   'clear_parking() success';

        # /zone/remove_record
        $resp = $client->remove_record(
            dname       => 'test.ru',
            subdomain   => '@',
            content     => '111.111.111.111',
            record_type => 'A',
        );
        ok $resp->is_success,                                   'remove_record() success';

        # /zone/clear
        $resp = $client->clear(dname => 'test.ru');
        ok $resp->is_success,                                   'clear() success';
    };
}

1;
