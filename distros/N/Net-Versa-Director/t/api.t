use v5.36;
use Test2::V0;
use Test2::Tools::Compare qw( array all_items hash );
use Net::Versa::Director;

skip_all "environment variables not set"
    unless (exists $ENV{NET_VERSA_DIRECTOR_HOSTNAME}
        && exists $ENV{NET_VERSA_DIRECTOR_USERNAME}
        && exists $ENV{NET_VERSA_DIRECTOR_PASSWORD}
        && exists $ENV{NET_VERSA_DIRECTOR_CLIENT_ID}
        && exists $ENV{NET_VERSA_DIRECTOR_CLIENT_SECRET});

SKIP: {
    skip "no basic authentication tests requested"
        unless exists $ENV{NET_VERSA_DIRECTOR_BASIC_AUTH} && $ENV{NET_VERSA_DIRECTOR_BASIC_AUTH};

    like (
        dies {
            my $director = Net::Versa::Director->new(
                server      => 'https://' . $ENV{NET_VERSA_DIRECTOR_HOSTNAME} . ':9182',
                user        => 'net-versa-director-test-nonexisting',
                passwd      => 'invalid',
            );
            $director->get_director_info;
        },
        hash {
            field 'code'                => D();
            field 'description'         => D();
            field 'message'             => D();
            field 'http_status_code'    => D();
            field 'more_info'           => D();

            end();
        },
        'api call with incorrect credentials throws exception'
    );
}

is (
    dies {
        my $director = Net::Versa::Director->new(
            server      => 'https://' . $ENV{NET_VERSA_DIRECTOR_HOSTNAME} . ':9183',
            user        => $ENV{NET_VERSA_DIRECTOR_USERNAME},
            passwd      => $ENV{NET_VERSA_DIRECTOR_PASSWORD},
        );
        $director->login('non-existing-client-id', 'client-secret');
    },
    object {
        prop isa => 'Net::Versa::Director::Exception::OAuth';

        call error              => 'invalid_client';
        call error_description  => 'Client authentication failed (e.g., unknown client, no client authentication included, or unsupported authentication method).';

        call as_string          => 'Client authentication failed (e.g., unknown client, no client authentication included, or unsupported authentication method).';
    },
    'OAuth authentication with valid user/pass but invalid client id throws exception'
);

is (
    dies {
        my $director = Net::Versa::Director->new(
            server      => 'https://' . $ENV{NET_VERSA_DIRECTOR_HOSTNAME} . ':9183',
            user        => 'net-versa-director-test-nonexisting',
            passwd      => 'invalid',
        );
        $director->login($ENV{NET_VERSA_DIRECTOR_CLIENT_ID}, $ENV{NET_VERSA_DIRECTOR_CLIENT_SECRET});
    },
    object {
        prop isa => 'Net::Versa::Director::Exception::OAuth';

        call error              => 'invalid_grant';
        call error_description  => L();

        call as_string          => L();
    },
    'OAuth authentication with invalid user/pass but valid client id/secret throws exception'
);

my $director = Net::Versa::Director->new(
    server      => 'https://' . $ENV{NET_VERSA_DIRECTOR_HOSTNAME} . ':9183',
    user        => $ENV{NET_VERSA_DIRECTOR_USERNAME},
    passwd      => $ENV{NET_VERSA_DIRECTOR_PASSWORD},
);

is (
    dies {
        $director->get_director_info;
    },
    object {
        prop isa => 'Net::Versa::Director::Exception::Basic';

        call code               => 4001;
        call description        => "Invalid user name or password.";
        call http_status_code   => 401;
        call message            => "Unauthenticated";
        call more_info          => "http://nms.versa.com/errors/4001";

        call as_string          => "Invalid user name or password.";
    },
    'OAuth API call before login throws exception'
);

my $login_response;
ok(
    lives {
        $login_response = $director->login($ENV{NET_VERSA_DIRECTOR_CLIENT_ID}, $ENV{NET_VERSA_DIRECTOR_CLIENT_SECRET});
    },
    "OAuth login successful");

# ensure that the maximum number of access-tokens of the client isn't exceeded
END {
    if ($login_response) {
        diag("logging out");
        $director->logout;
    }
}

is($director->get_director_info, hash {
        etc();
    },
    'get_director_info returns hashref');

is($director->get_version, D(),
    'get_version returns string');

my $appliances = $director->list_appliances;

is($appliances, array  {
        all_items hash{ etc(); };
        etc();
    }, 'list_appliances returns arrayref of hashes');

is($director->list_assets, array  {
        all_items hash{ etc(); };
        etc();
    }, 'list_assets returns arrayref of hashes');

my $device_workflows = $director->list_device_workflows;

is($device_workflows, array  {
        all_items hash{ etc(); };
        etc();
    }, 'list_device_workflows returns arrayref of hashes');

is (
    dies {
        $director->get_device_workflow('non-existing');
    },
    object {
        prop isa                => 'Net::Versa::Director::Exception::VNMS';

        call error              => 'Not Found';
        call exception          => 'com.versa.vnms.common.exception.VOAEException';
        call http_status_code   => 404;
        call message            => ' device work flow non-existing does not exist ';
        call path               => '/vnms/sdwan/workflow/devices/device/non-existing';
        call timestamp          => L();

        call as_string          => " device work flow non-existing does not exist ";
    },
    "get_device_workflow for non-existing workflow throws exception"
);

is (
    dies {
        $director->_create('/api/operational/system/package-info', {});
    },
    object {
        prop isa                => 'Net::Versa::Director::Exception::Basic';

        call code               => 403;
        call description        => 'User does not have access';
        call http_status_code   => 403;
        call message            => 403;
        call more_info          => 'http://nms.versa.com/errors/403';

        call as_string          => "User does not have access";
    },
    "incorrect operation throws correct exception"
);

SKIP: {
    skip "Director has no device workflows"
        unless $device_workflows->@*;
    my $test_device_workflow = $device_workflows->[0];
    diag "using appliance '" . $test_device_workflow->{deviceName} . "' for following tests";

    is($director->get_device_workflow($test_device_workflow->{deviceName}), hash {
        etc();
    },
    'get_device_workflow returns hashref');
}

SKIP: {
    skip "Director has no appliances"
        unless $appliances->@*;
    my $appliance = $appliances->[0];
    diag "using appliance '" . $appliance->{name} . "' for following tests";

    is($director->list_device_interfaces($appliance->{name}), hash {
            field 'operations'  => hash { etc(); };
            field 'wwan'        => hash { etc(); };
            field 'vni'         => array  {
                all_items hash {
                    etc();
                };
                etc();
            };
            etc();
        }, 'list_device_interfaces returns hashref of arrayref of hashrefs');

    is($director->list_device_interfaces($appliance->{name})->{vni}, array {
            all_items hash {
                etc();
            };
            etc();
        }, 'list_device_interfaces->{vni} returns arrayref of hashrefs');

    is($director->list_device_networks($appliance->{name}), array  {
            all_items hash {
                etc();
            };
            etc();
        }, 'list_device_networks returns arrayref of hashrefs');

    ok(
        lives {
            is(my $config = $director->get_device_configuration($appliance->{name}), match qr/^devices \{/,
                "get_device_configuration returns current device configuration");
        },
        "get_device_configuration doesn't throw exception");
}

done_testing();
