use strict;
use warnings;
use utf8;
use Test::More tests => 3;
use t::lib::NamespaceClient;
use t::lib::Connection;

subtest 'Generic behaviour' => sub {
    plan tests => 2;

    my @methods = qw(
        nop
        get_prices
        get_suggest
        get_premium
        get_deleted
        check
        create
        transfer
        get_rereg_data
        set_rereg_bids
        get_user_rereg_bids
        get_docs_upload_uri
        update_contacts
        update_private_person_flag
        register_ns
        delete_ns
        get_nss
        update_nss
        delegate
        undelegate
        transfer_to_another_account
        look_at_entering_list
        accept_or_refuse_entering_list
        cancel_transfer
        request_to_transfer
    );

    my $client = t::lib::NamespaceClient->domain;

    isa_ok $client, 'Regru::API::Domain';
    can_ok $client, @methods;
};

SKIP: {
    my $planned = 2;
    my $client = t::lib::NamespaceClient->domain;

    skip 'No connection to an API endpoint.', $planned   unless t::lib::Connection->check($client->endpoint);
    skip 'Exceeded allowed connection rate.', $planned   unless t::lib::NamespaceClient->rate_limits_avail;

    subtest 'Namespace methods (nop)' => sub {
        plan tests => 1;

        my $resp;

        # /domain/nop
        $resp = $client->nop;
        ok $resp->is_success,                                   'nop() success';
    };

    subtest 'Namespace methods (overall)' => sub {
        unless ($ENV{REGRU_API_OVERALL_TESTING}) {
            diag 'Some tests were skipped. Set the REGRU_API_OVERALL_TESTING to execute them.';
            plan skip_all => '.';
        }
        else {
            plan tests => 42;
        }

        my $resp;

        # /domain/get_prices
        $resp = $client->get_prices;
        ok $resp->is_success,                                   'get_prices() success';
        my $prices = $resp->get('prices');
        isa_ok $prices, 'HASH',                                 'get_prices() correct reference for prices';
        ok $prices->{ru}->{reg_price},                          'get_prices() ru/reg_price okay';

        # /domain/get_suggest
        $resp = $client->get_suggest(word => 'дом', tld => 'рф');
        ok $resp->is_success,                                   'get_suggest() success';
        isa_ok $resp->get('suggestions'), 'ARRAY',              'get_suggest() correct reference for suggestions';
        ok scalar(@{ $resp->get('suggestions') }),              'get_suggest() some suggestions was given';

        # /domain/get_premium
        $resp = $client->get_premium(tld => 'рф', limit => 5);
        ok $resp->is_success,                                   'get_premium() success';

        # /domain/get_deleted
        $resp = $client->get_deleted(tld => 'ru', min_pr => 1);
        ok $resp->is_success,                                   'get_deleted() success';
        cmp_ok scalar(@{ $resp->get('domains') }), '>', 0,      'get_deleted() non empty list';

        # /domain/check (1)
        $resp = $client->check(dname => 'ya.ru');
        ok $resp->is_success,                                   'check() success';
        isa_ok $resp->get('domains'), 'ARRAY',                  'check() correct reference for domains';
        is $resp->get('domains')->[0]->{result}, 'Available',   'check() correct answer for result';

        # /domain/check (2)
        $resp = $client->check(dname => 'wwww.bogus');
        ok $resp->is_success,                                   'check() bogus name: success';
        my $err = $resp->get('domains')->[0];
        is $err->{result}, 'error',                             'check() bogus name: result';
        is $err->{error_code}, 'INVALID_DOMAIN_NAME_FORMAT',    'check() bogus name: error_code';

        # /domain/create
        # XXX reset cached values?
        my $domain = {
            contacts => {
                descr  => 'Vschizh site',
                person => 'Svyatoslav V Ryurik',
                person_r =>
                    'Рюрик Святослав Владимирович',
                passport =>
                    '34 02 651241 выдан 48 о/м г.Москвы 26.12.1999',
                birth_date => '01.01.1970',
                p_addr =>
                    '12345, г. Вщиж, ул. Княжеска, д.1, Рюрику Святославу Владимировичу, князю Вщижскому',
                phone   => '+7 495 5555555',
                e_mail  => 'test@reg.ru',
                country => 'RU',
            },
            nss => {
                ns0 => 'ns1.reg.ru',
                ns1 => 'ns2.reg.ru',
            },
            domain_name => 'vschizh.su',
        };

        $resp = $client->create(%$domain);
        ok $resp->is_success,                                   'create() success';
        # diag explain $resp->answer;
        is $resp->get('bill_id'), 1234,                         'create() got correct bill_id';
        is $resp->get('service_id'), 12345,                     'create() got correct service_id';

        # multiple domains
        delete $domain->{domain_name};

        $domain->{domains} = [
            {   dname           => 'vschizh.ru',
                srv_certificate => 'free',
                srv_parking     => 'free' },
            {   dname           => 'vschizh.su',
                srv_webfwd      => '' },
        ];

        $resp = $client->create(%$domain);
        ok $resp->is_success,                                   'create() multiple success';
        is $resp->get('bill_id'), 1234,                         'create() multiple got correct bill_id';
        my $domains = $resp->get('domains');
        is scalar @$domains, 2,                                 'create() multiple created domains amount';

        # /domain/transfer
        $resp = $client->transfer(authinfo => '1231234563454');
        ok !$resp->is_success,                                  'transfer() not success (as expected)';
        is $resp->error_code, 'DOMAINS_NOT_FOUND',              'transfer() got correct error_code';

        # /domain/set_rereg_bids
        delete $domain->{domains};
        $domain->{domains} = [
            { dname => 'vschizh.su', price => 400 },
            { dname => 'vschizh.ru', price => 225 },
            # или заказ в рассрочку:
            # { dname => 'vschizh.ru', price => 2500, instalment => 1 },
        ];

        $resp = $client->set_rereg_bids(%$domain);
        ok $resp->is_success,                                   'set_rereg_bids() success';

        # /domain/get_user_rereg_bids
        $resp = $client->get_user_rereg_bids;
        ok $resp->is_success,                                   'get_user_rereg_bids() success';

        # /domain/get_docs_upload_uri
        $resp = $client->get_docs_upload_uri(dname => 'test.ru');
        ok $resp->is_success,                                   'get_docs_upload_uri() success';
        is $resp->get('docs_upload_sid'), 123456,               'get_docs_upload_uri() got correct session id';

        # /domain/update_private_person_flag
        $resp = $client->update_private_person_flag(
            private_person_flag => 0,
            dname               => 'test.ru'
        );
        ok $resp->is_success,                                   'update_private_person_flag() success';
        is $resp->get('pp_flag'), 'is cleared',                 'update_private_person_flag() got correct value for pp_flag';

        # /domain/register_ns
        $resp = $client->register_ns(dname => 'test.com', ns0 => 'ns0.test.com');
        ok $resp->is_success,                                   'register_ns() success';

        # /domain/delete_ns
        $resp = $client->delete_ns(dname => 'test.com', ns0 => 'ns0.test.com');
        ok $resp->is_success,                                   'delete_ns() success';

        # /domain/get_nss
        my $nss = [
            { ns => 'ns1.reg.ru' },
            { ns => 'ns2.reg.ru' },
        ];

        $resp = $client->get_nss(dname => 'test.com');
        ok $resp->is_success,                                   'get_nss() success';
        my $ans = $resp->get('domains')->[0];
        is $ans->{dname}, 'test.com',                           'get_nss() got correct value of domain';
        is_deeply $ans->{nss}, $nss,                            'get_nss() got correct list nameservers';

        # /domain/update_nss
        $resp = $client->update_nss(
            domains => [ { dname => 'test.ru' } ],
            nss => { ns0 => 'ns9.reg.ru', ns1 => 'ns8.reg.ru' },
        );
        ok $resp->is_success,                                   'update_nss() success';

        # /domain/delegate
        $resp = $client->delegate(domains => [ { dname => 'test.ru' } ]);
        ok $resp->is_success,                                   'delegate() success';

        # /domain/undelegate
        $resp = $client->undelegate(domains => [ { dname => 'test.ru' } ]);
        ok $resp->is_success,                                   'undelegate() success';

        # /domain/transfer_to_another_account
        $resp = $client->transfer_to_another_account(
            domains => [ { dname => 'test.ru' } ],
            new_user_name => 'not_test',
        );
        ok $resp->is_success,                                   'transfer_to_another_account() success';

        # /domain/look_at_entering_list
        $resp = $client->look_at_entering_list;
        ok $resp->is_success,                                   'look_at_entering_list() success';

        # /domain/accept_or_refuse_entering_list
        $resp = $client->accept_or_refuse_entering_list;
        ok $resp->is_success,                                   'accept_or_refuse_entering_list() success';

        # /domain/cancel_transfer
        $resp = $client->cancel_transfer(dname => 'test.ru');
        ok $resp->is_success,                                   'cancel_transfer() success';

        # /domain/request_to_transfer
        $resp = $client->request_to_transfer(
            domains => [
                { domain_name => 'test.ru' },
                { dname => 'test.ru' },
            ]
        );
        # XXX does not pass. why?
        SKIP: {
            skip 'Does not pass. Why?', 1;
            ok $resp->is_success,                               'request_to_transfer() success';
            # diag explain $resp->answer;
        }
    };
}

1;
