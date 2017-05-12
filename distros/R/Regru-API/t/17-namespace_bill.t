use strict;
use warnings;
use Test::More tests => 3;
use t::lib::NamespaceClient;
use t::lib::Connection;

subtest 'Generic behaviour' => sub {
    plan tests => 2;

    my @methods = qw(
        nop
        get_not_payed
        get_for_period
        change_pay_type
        delete
    );

    my $client = t::lib::NamespaceClient->bill;

    isa_ok $client, 'Regru::API::Bill';
    can_ok $client, @methods;
};

SKIP: {
    my $planned = 2;
    my $client = t::lib::NamespaceClient->bill;

    skip 'No connection to an API endpoint.', $planned   unless t::lib::Connection->check($client->endpoint);
    skip 'Exceeded allowed connection rate.', $planned   unless t::lib::NamespaceClient->rate_limits_avail;

    subtest 'Namespace methods (nop)' => sub {
        plan tests => 1;

        my $resp;

        # /bill/nop
        $resp = $client->nop(bill_id => 1234);
        ok $resp->is_success,                                   'nop() success';
    };

    subtest 'Namespace methods (overall)' => sub {
        unless ($ENV{REGRU_API_OVERALL_TESTING}) {
            diag 'Some tests were skipped. Set the REGRU_API_OVERALL_TESTING to execute them.';
            plan skip_all => '.';
        }
        else {
            plan tests => 4;
        }

        my $resp;

        # /bill/get_not_payed
        $resp = $client->get_not_payed;
        ok $resp->is_success,                                   'get_not_payed() success';

        # /bill/get_for_period
        $resp = $client->get_for_period(
            limit      => 5,
            start_date => '1917-10-26',
            end_date   => '1917-10-07',
        );
        ok $resp->is_success,                                   'get_for_period() success';

        # /bill/change_pay_type
        $resp = $client->change_pay_type(
            bill_id  => 1234,
            pay_type => 'prepay',
            currency => 'RUR',
        );
        ok $resp->is_success,                                   'change_pay_type() success';

        # /bill/delete
        $resp = $client->delete(bill_id => 1234);
        ok $resp->is_success,                                   'delete() success';
    };
}

1;
