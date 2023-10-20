use v5.36;
use Test2::V0;
use Test2::Tools::Compare qw( array all_items hash );
use Test2::Plugin::DieOnFail;
use Net::Versa::Director;

skip_all "environment variables not set"
    unless (exists $ENV{NET_VERSA_DIRECTOR_HOSTNAME}
        && exists $ENV{NET_VERSA_DIRECTOR_USERNAME}
        && exists $ENV{NET_VERSA_DIRECTOR_PASSWORD});

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

my $director = Net::Versa::Director->new(
    server      => 'https://' . $ENV{NET_VERSA_DIRECTOR_HOSTNAME} . ':9182',
    user        => $ENV{NET_VERSA_DIRECTOR_USERNAME},
    passwd      => $ENV{NET_VERSA_DIRECTOR_PASSWORD},
    clientattrs => {
        verify_SSL => 0,
    },
);

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

like (
    dies {
        $director->get_device_workflow('non-existing');
    },
    hash {
        field 'error'               => D();
        field 'exception'           => D();
        field 'http_status_code'    => D();
        field 'message'             => D();
        field 'path'                => D();
        field 'timestamp'           => D();

        end();
    },
    "get_device_workflow for non-existing workflow throws exception"
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

    is($director->list_device_interfaces($appliance->{name}), array  {
            all_items hash {
                etc();
            };
            etc();
        }, 'list_device_interfaces returns arrayref of hashrefs');

    is($director->list_device_networks($appliance->{name}), array  {
            all_items hash {
                etc();
            };
            etc();
        }, 'list_device_networks returns arrayref of hashrefs');
}

done_testing();
