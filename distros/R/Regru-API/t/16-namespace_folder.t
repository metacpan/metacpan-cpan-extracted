use strict;
use warnings;
use Test::More tests => 3;
use t::lib::NamespaceClient;
use t::lib::Connection;

subtest 'Generic behaviour' => sub {
    plan tests => 2;

    my @methods = qw(
        nop
        create
        remove
        rename
        get_services
        add_services
        remove_services
        replace_services
        move_services
    );

    my $client = t::lib::NamespaceClient->folder;

    isa_ok $client, 'Regru::API::Folder';
    can_ok $client, @methods;
};

SKIP: {
    my $planned = 2;
    my $client = t::lib::NamespaceClient->folder;

    skip 'No connection to an API endpoint.', $planned   unless t::lib::Connection->check($client->endpoint);
    skip 'Exceeded allowed connection rate.', $planned   unless t::lib::NamespaceClient->rate_limits_avail;

    subtest 'Namespace methods (nop)' => sub {
        plan tests => 1;

        my $resp;

        # /folder/nop
        $resp = $client->nop(folder_name => 'qqq');
        ok $resp->is_success,                                   'nop() success';
    };

    subtest 'Namespace methods (overall)' => sub {
        unless ($ENV{REGRU_API_OVERALL_TESTING}) {
            diag 'Some tests were skipped. Set the REGRU_API_OVERALL_TESTING to execute them.';
            plan skip_all => '.';
        }
        else {
            plan tests => 8;
        }

        my $resp;

        # /folder/{create,remove,rename,get_services}
        foreach my $method (qw/create remove rename get_services/) {
            $resp = $client->$method(folder_name => 'qqq');
            ok $resp->is_success, "${method}() success";
        }

        # /folder/{get_services,remove_services,replace_services,move_services}
        foreach my $method (qw/get_services remove_services replace_services move_services/) {
            $resp = $client->$method(
                folder_name => 'qqq',
                services    => [ { dame => 'qqq.ru' } ]
            );
            ok $resp->is_success, "${method}() success";
        }
    };
}

1;
