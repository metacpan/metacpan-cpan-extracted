use Test2::V0;
use Test2::Tools::Compare qw( array hash F );
use Net::Checkpoint::Management::v1;
use JSON qw();

SKIP: {
    skip_all "environment variables not set"
        unless (exists $ENV{NET_CHECKPOINT_MANAGEMENT_V1_HOSTNAME}
            && exists $ENV{NET_CHECKPOINT_MANAGEMENT_V1_USERNAME}
            && exists $ENV{NET_CHECKPOINT_MANAGEMENT_V1_PASSWORD}
            && exists $ENV{NET_CHECKPOINT_MANAGEMENT_V1_POLICY});
};

like(
    dies {
        my $cpmgmt_unreach = Net::Checkpoint::Management::v1->new(
            server      => 'https://localhost',
            user        => 'username',
            passwd      => 'password',
            clientattrs => { timeout => 1 },
        );
        $cpmgmt_unreach->login;
    },
    qr/Could not connect to/,
    'connection failure throws exception'
);

my $cpmgmt = Net::Checkpoint::Management::v1->new(
    server      => 'https://' . $ENV{NET_CHECKPOINT_MANAGEMENT_V1_HOSTNAME},
    user        => $ENV{NET_CHECKPOINT_MANAGEMENT_V1_USERNAME},
    passwd      => $ENV{NET_CHECKPOINT_MANAGEMENT_V1_PASSWORD},
    clientattrs => { timeout => 30 },
);

ok($cpmgmt->login, 'login to Checkpoint Manager successful');

diag("using api version " . $cpmgmt->api_version);

is( $cpmgmt->api_versions, array {
    all_items match qr/^\d(\.\d)?(\.\d)?$/;
    etc();
}, 'api_versions successful');

ok(my $session = $cpmgmt->get_session(), 'fetching session information ok');

is($session->{description}, '', 'session has no description');

ok($cpmgmt->update_session({}, {
    description => 'test session',
}));

ok($session = $cpmgmt->get_session(), 'fetching session information ok');

is($session->{description}, 'test session', 'session has set description');

ok(my $policy = $cpmgmt->create_package({
    name => $ENV{NET_CHECKPOINT_MANAGEMENT_V1_POLICY},
}), 'policy package created');
is( scalar $policy->{'access-layers'}->@*, 1, 'policy package has one access-layer');
my $acl_uid = $policy->{'access-layers'}->[0]->{uid};

ok(my $accessrules = $cpmgmt->list_accessrules({ uid => $acl_uid }),
    'list accessrules successful');
is($accessrules, hash {
    field uid   => D();
    field name  => D();
    field total => 1;
    field 'objects-dictionary' => array {
        etc();
    };
    field rulebase => array {
        etc();
    };
    end();
}, 'access policy has only the default cleanup rule');

ok(my $hosts = $cpmgmt->list_hosts(),
    'list hosts successful');

ok(my $acme_host_dns1 = $cpmgmt->create_host({
    name            => 'acme_host-dns1',
    'ipv4-address'  => '10.0.0.10',
}), "create host 'acme_host-dns1' successful");
ok(my $acme_host_dns2 = $cpmgmt->create_host({
    name            => 'acme_host-dns2',
    'ipv4-address'  => '10.0.0.11',
}), "create host 'acme_host-dns2' successful");

ok(my $networks = $cpmgmt->list_networks(),
    'list networks successful');

ok(my $acme_net_clients = $cpmgmt->create_network({
    name    => 'acme_net-clients',
    subnet4 => '10.0.0.0',
    'mask-length4'  => 24,
    'ignore-warnings' => 1,
}), "create network 'acme_net-clients' successful");

ok(my $dns_domains = $cpmgmt->list_dns_domains(),
    'list DNS domains successful');

ok(my $dns_domain = $cpmgmt->create_dns_domain({
    name                => '.www.example.org',
    'is-sub-domain'     => 0,
    'ignore-warnings'   => 1,
}), "create DNS domain 'www.example.org' successful");

ok(my $address_ranges = $cpmgmt->list_address_ranges(),
    'list address ranges successful');

ok(my $acme_range_test = $cpmgmt->create_address_range({
    name                    => 'acme_range-test',
    'ipv4-address-first'    => '192.0.2.10',
    'ipv4-address-last'     => '192.0.2.20',
    'ignore-warnings'       => 1,
}), "create address range 'acme_range-test' successful");

ok(my $groups = $cpmgmt->list_groups(),
    'list groups successful');

ok(my $acme_group_test = $cpmgmt->create_group({
    name                    => 'acme_grp-test',
    members                 => [
        'acme_host-dns1',
        'acme_net-clients',
        '.www.example.org',
        'acme_range-test',
    ],
    'ignore-warnings'       => 1,
}), "create group 'acme_grp-test' successful");

ok(my $tcp_services = $cpmgmt->list_services_tcp(),
    'list TCP services successful');

ok(my $tcp_service_53 = $cpmgmt->create_service_tcp({
    name    => 'tcp_53',
    port    => 53,
    'ignore-warnings' => 1,
}), "create TCP service 'tcp_53' successful");

ok(my $udp_services = $cpmgmt->list_services_udp(),
    'list UDP services successful');

ok(my $udp_services_10atatime = $cpmgmt->list_services_udp({ limit => 10 }),
    'list UDP services 10 per API call successful');

is($udp_services, $udp_services_10atatime, 'both list responses are identical');

ok(my $udp_service_53 = $cpmgmt->create_service_udp({
    name    => 'udp_53',
    port    => 53,
    'ignore-warnings' => 1,
}), "create UDP service 'udp_53' successful");

ok(my $icmp_services = $cpmgmt->list_services_icmp(),
    'list ICMP services successful');

ok(my $icmp_service_echo_request = $cpmgmt->create_service_icmp({
    name        => 'icmp_echo-request',
    'icmp-type' => 8,
}), "create ICMP service 'icmp_echo-request' successful");

ok(my $icmpv6_services = $cpmgmt->list_services_icmpv6(),
    'list ICMPv6 services successful');

ok(my $icmpv6_service_echo_request = $cpmgmt->create_service_icmpv6({
    name        => 'icmpv6_echo-request',
    'icmp-type' => 128,
}), "create ICMPv6 service 'icmpv6_echo-request' successful");

ok(my $other_services = $cpmgmt->list_services_other(),
    'list other services successful');

ok(my $other_service_ipsec = $cpmgmt->create_service_other({
    name            => 'ipsec',
    'ip-protocol'   => 50,
}), "create other service 'ipsec' successful");

ok(my $other_service_gre_by_protocol = $cpmgmt->find_service_other({
    'ip-protocol'   => 47,
}), "find other service IP protocol 47 successful");
is($other_service_gre_by_protocol, hash {
    field 'ip-protocol' => 47;
    field name          => 'gre';
    etc();
}, 'find other service IP protocol 47 returns correct object');

ok(dies {
    $cpmgmt->find_service_other({ 'ip-protocol' => 0 })
}, "find other service IP protocol 0 fails");

ok(my $service_groups = $cpmgmt->list_service_groups(),
    'list service groups successful');

ok(my $acme_service_group_test = $cpmgmt->create_service_group({
    name                    => 'acme_svcgrp-test',
    members                 => [
        'tcp_53',
        'udp_53',
        'icmp_echo-request',
        'gre',
    ],
    'ignore-warnings'       => 1,
}), "create service group 'acme_svcgrp-test' successful");

ok(my $ipv4_object_rule = $cpmgmt->create_accessrule({
    layer       => $acl_uid,
    position    => 'top', # to not create it after the cleanup rule
    name        => 'simple IPv4 literals rule',
    action      => 'Accept',
    enabled     => JSON->boolean(1),
    source      => [
        $acme_net_clients->{uid},
    ],
    destination => [
        $acme_host_dns1->{uid},
        $acme_host_dns2->{uid},
    ],
    service     => [
        $tcp_service_53->{uid},
        $udp_service_53->{uid},
        $icmp_service_echo_request->{uid},
    ],
}), 'add accessrule successful');

my $access_rule;
ok(lives {
    $access_rule = $cpmgmt->find_accessrule({
        name => 'simple IPv4 literals rule',
    }, {
        uid => $acl_uid,
    });
}, "find access rule by name successful") or note($@);
is($access_rule->{uid}, $ipv4_object_rule->{uid},
    'find access rule by name returns correct rule');

is($access_rule->{enabled}, T(), "access rule is enabled");
ok($access_rule = $cpmgmt->update_accessrule({
        uid     => $access_rule->{uid},
        name    => $access_rule->{name},
        layer   => $acl_uid,
    }, {
        enabled => JSON->boolean(0),
    }), "disable access rule successful");
is($access_rule->{enabled}, F(), "access rule is disabled");

is($cpmgmt->where_used($acme_net_clients, { indirect => \1 }),
    {
        'used-directly'     => hash {
            field 'total'   => 2;

            field 'objects' => array {
                item hash {
                    field 'type' => 'group';
                    field 'name' => 'acme_grp-test';

                    etc();
                };
            };

            field 'access-control-rules' => array {
                item hash {
                    field 'package'  => hash {
                        field 'name' => $ENV{NET_CHECKPOINT_MANAGEMENT_V1_POLICY};

                        etc();
                    };

                    field 'rule'    => hash {
                        field 'name' => 'simple IPv4 literals rule';

                        etc();
                    };

                    etc();
                };

                end();
            };

            etc();
        },
        'used-indirectly'   => hash {
            field 'total'   => 0;

            etc();
        },
    },
    'where_used for network object directly in rule ok');

ok($cpmgmt->delete_accessrule({
        uid     => $access_rule->{uid},
        layer   => $acl_uid,
    }), "delete access rule successful");

# ok(my $taskid = $cpmgmt->publish, 'publish successful');

END {
    if (defined $cpmgmt) {
        diag "discarding changes and logging out";
        $cpmgmt->discard;
        $cpmgmt->logout;
    }
}

done_testing;
