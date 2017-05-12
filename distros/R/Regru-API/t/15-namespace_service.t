use strict;
use warnings;
use Test::More tests => 3;
use t::lib::NamespaceClient;
use t::lib::Connection;

subtest 'Generic behaviour' => sub {
    plan tests => 2;

    my @methods = qw(
        nop
        get_prices
        get_servtype_details
        create
        delete
        get_info
        get_list
        get_folders
        get_details
        get_dedicated_server_list
        update
        renew
        get_bills
        set_autorenew_flag
        suspend
        resume
        get_depreciated_period
        upgrade
        partcontrol_grant
        partcontrol_revoke
        resend_mail
    );

    my $client = t::lib::NamespaceClient->service;

    isa_ok $client, 'Regru::API::Service';
    can_ok $client, @methods;
};

SKIP: {
    my $planned = 2;
    my $client = t::lib::NamespaceClient->service;

    skip 'No connection to an API endpoint.', $planned   unless t::lib::Connection->check($client->endpoint);
    skip 'Exceeded allowed connection rate.', $planned   unless t::lib::NamespaceClient->rate_limits_avail;

    subtest 'Namespace methods (nop)' => sub {
        plan tests => 1;

        my $resp;

        # /service/nop
        $resp = $client->nop(dname => 'test.ru');
        ok $resp->is_success,                                   'nop() success';
    };

    subtest 'Namespace methods (overall)' => sub {
        unless ($ENV{REGRU_API_OVERALL_TESTING}) {
            diag 'Some tests were skipped. Set the REGRU_API_OVERALL_TESTING to execute them.';
            plan skip_all => '.';
        }
        else {
            plan tests => 18;
        }

        my $resp;

        # /service/get_prices
        $resp = $client->get_prices;
        ok $resp->is_success,                                   'get_prices() success';

        # /service/get_servtype_details
        $resp = $client->get_servtype_details(servtype => 'srv_hosting_ispmgr');
        ok $resp->is_success,                                   'get_servtype_details() success';

        # /service/create
        $resp = $client->create(
            dname    => 'test.ru',
            servtype => 'srv_hosting_ispmgr',
            period   => 1,
            plan     => 'Host-2-1209',
        );
        ok $resp->is_success,                                   'create() success';

        # /service/delete
        $resp = $client->delete(
            dname    => 'test.ru',
            servtype => 'srv_hosting_ispmgr',
        );
        ok $resp->is_success,                                   'delete() success';

        # /service/{get_info,get_list,get_folders,get_details,get_bills}
        foreach my $method (qw/get_info get_list get_folders get_details get_bills/) {
            $resp = $client->$method(dname => 'test.ru');
            ok $resp->is_success, "${method}() success";
        }

        # /service/update
        $resp = $client->update(
            dname      => 'test.ru',
            servtype   => 'srv_webfwd',
            fwd_action => 'addfwd',
            fwdfrom    => '/',
            fwdto      => 'http://reg.ru',
            fwd_type   => 'redirect',
        );
        ok $resp->is_success,                                   'update() success';

        # /service/{renew,suspend,resume,get_depreciated_period}
        foreach my $method (qw/renew suspend resume get_depreciated_period/) {
            $resp = $client->$method(service_id => '12345', period => 2);
            ok $resp->is_success, "${method}() success";
        }

        # /service/set_autorenew_flag
        $resp = $client->set_autorenew_flag(flag_value => 1, service_id => 12345);
        ok $resp->is_success,                                   'set_autorenew_flag() success';

        # /service/partcontrol_grant
        $resp = $client->partcontrol_grant(
            newlogin   => 'test',
            service_id => 1,
        );
        ok $resp->is_success,                                   'partcontrol_grant() success';

        # /service/partcontrol_revoke
        $resp = $client->partcontrol_revoke(
            service_id => 1,
        );
        ok $resp->is_success,                                   'partcontrol_revoke() success';

        # /service/resend_mail
        $resp = $client->resend_mail(
            dname       => 'test.ru',
            servtype    => 'srv_hosting_ispmgr',
            service_id  => 1,
        );
        ok $resp->is_success,                                   'resend_mail() success';
    };
}

1;
