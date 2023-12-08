use 5.024;
use Test2::V0;
use Test2::Tools::Compare qw( array bag hash all_items all_values );
use Test2::Tools::Subtest qw( subtest_buffered );
use Test2::Plugin::DieOnFail;
use Net::Fortinet::FortiManager;

skip_all "environment variables not set"
    unless (exists $ENV{NET_FORTINET_FORTIMANAGER_HOSTNAME}
        && exists $ENV{NET_FORTINET_FORTIMANAGER_USERNAME}
        && exists $ENV{NET_FORTINET_FORTIMANAGER_PASSWORD}
        && exists $ENV{NET_FORTINET_FORTIMANAGER_POLICY});

like (
    dies {
        my $fortimanager = Net::Fortinet::FortiManager->new(
            server      => 'https://' . $ENV{NET_FORTINET_FORTIMANAGER_HOSTNAME},
            user        => 'net-fortinet-fortimanager-test-nonexisting',
            passwd      => 'invalid',
            clientattrs => {
                insecure => 1,
            },
        );
        $fortimanager->login;
    },
    qr/^jsonrpc error \(-11\): /,
    'login with incorrect credentials throws exception'
);

my $fortimanager = Net::Fortinet::FortiManager->new(
    server      => 'https://' . $ENV{NET_FORTINET_FORTIMANAGER_HOSTNAME},
    user        => $ENV{NET_FORTINET_FORTIMANAGER_USERNAME},
    passwd      => $ENV{NET_FORTINET_FORTIMANAGER_PASSWORD},
    clientattrs => {
        insecure => 1,
    },
);

ok(!$fortimanager->_has_last_transaction_id,
    'no transaction id after construction');

ok(!$fortimanager->adoms, 'no adoms after construction');

is($fortimanager->adom, 'root', "adom set to 'root' after construction");

ok($fortimanager->login, 'login to Fortinet FortiManager successful');

ok($fortimanager->_has_last_transaction_id,
    'transaction id set after login');

ok($fortimanager->_sessionid, 'sessionid set after successful login');

is($fortimanager->adoms, bag {
    all_items D();
}, 'adoms returns arrayref of ADOM names');

my %firewall_address;
my %firewall_address_group;
my %firewall_ipv6_address;
my %firewall_ipv6_address_group;
my %firewall_wildcard_fqdn;
my %firewall_service;
my %firewall_service_group;
my %policy_package;

END {
    say 'deleting created objects';
    for (keys %policy_package) {
        say "\t$_";
        $fortimanager->delete_policy_package($_);
    }
    for (keys %firewall_address_group) {
        say "\t$_";
        $fortimanager->delete_firewall_address_group($_);
    }
    for (keys %firewall_address) {
        say "\t$_";
        $fortimanager->delete_firewall_address($_);
    }
    for (keys %firewall_ipv6_address_group) {
        say "\t$_";
        $fortimanager->delete_firewall_ipv6_address_group($_);
    }
    for (keys %firewall_ipv6_address) {
        say "\t$_";
        $fortimanager->delete_firewall_ipv6_address($_);
    }
    for (keys %firewall_wildcard_fqdn) {
        say "\t$_";
        $fortimanager->delete_firewall_wildcard_fqdn($_);
    }
    for (keys %firewall_service_group) {
        say "\t$_";
        $fortimanager->delete_firewall_service_group($_);
    }
    for (keys %firewall_service) {
        say "\t$_";
        $fortimanager->delete_firewall_service($_);
    }

    say 'logging out';
    $fortimanager->logout
        if defined $fortimanager;
}

like (
    dies {
        $fortimanager->exec_method('get', '/does/not/exist');
    },
    qr/^http error \(503\): /,
    'calling exec_method with a nonexisting url throws correct exception'
);

is($fortimanager->exec_method('get',
    '/pm/config/adom/' . $fortimanager->adom . '/obj/firewall/address'),
    bag {
        all_items hash {
            etc();
        };
    }, 'exec_method without parameters response ok');

is($fortimanager->exec_method('get',
    '/pm/config/adom/' . $fortimanager->adom . '/obj/firewall/address',
    {
        fields => [qw( name type )],
    }),
    bag {
        all_items hash {
            field 'name' => D();
            field 'type' => D();

            etc();
        };
    }, 'exec_method with parameters response ok');

is($fortimanager->exec_method_multi('get',
    [{
        fields  => [qw( name type )],
        url     => '/pm/config/adom/' . $fortimanager->adom .
                   '/obj/firewall/address',
    }, {
        fields  => [qw( name protocol )],
        url     => '/pm/config/adom/' . $fortimanager->adom .
                   '/obj/firewall/service/custom',
    }]),
    bag {
        all_items hash {
            field 'data' => bag {
                all_items hash {
                    field 'name' => D();

                    etc();
                };

                etc();
            };

            field 'status' => hash {
                etc();
            };

            field 'url' => D();

            end();
        };

        # test if results are returned in request order

        item hash {
            field 'url' => '/pm/config/adom/' . $fortimanager->adom .
                '/obj/firewall/address';

            etc();
        };

        item hash {
            field 'url' =>  '/pm/config/adom/' . $fortimanager->adom .
                '/obj/firewall/service/custom';

            etc();
        };

        end();
    }, 'exec_method_multi with parameters response ok');

like (
    dies {
        $fortimanager->exec_method_multi('get',
            [{
                url => '/pm/config/adom/' . $fortimanager->adom .
                    '/obj/firewall/address',
            }, {
                url => '/does/not/exist',
            }, {
                url => '/does/not/exist/either',
            }]),
    },
    qr#^jsonrpc errors: /does/not/exist: \(-11\) No permission for the resource, /does/not/exist/either: \(-11\) No permission for the resource#,
    'calling exec_method_multi with a nonexisting url throws correct exception'
);

is($fortimanager->get_sys_status, hash {
    field 'Hostname'    => D();
    field 'Version'     => D();

    etc();
}, 'sys_status response ok');

is($fortimanager->list_adoms, bag {
    all_items D();
}, 'list_adoms returns arrayref of ADOM names');

subtest_buffered 'IPv4 objects' => sub {
    is($fortimanager->list_firewall_addresses,
        bag {
            all_items hash {
                field 'name'    => D();
                field 'type'    => D();

                etc();
            };

            end();
        },
        'list_firewall_addresses ok');

    ok($fortimanager->create_firewall_address('host_test1', {
        subnet => '192.0.2.10/255.255.255.255',
    }), 'create_firewall_address for host ok');
    $firewall_address{host_test1} = 1;

    ok($fortimanager->create_firewall_address('net_test1', {
        subnet => '192.0.2.0/255.255.255.0',
    }), 'create_firewall_address for network ok');
    $firewall_address{net_test1} = 1;

    ok($fortimanager->create_firewall_address('range_test1', {
        'start-ip'  => '192.0.2.10',
        'end-ip'    => '192.0.2.20',
        type        => 'iprange',
    }), 'create_firewall_address for range ok');
    $firewall_address{range_test1} = 1;

    ok($fortimanager->create_firewall_address('fqdn_acme.example.net', {
        fqdn    => 'acme.example.net',
        type    => 'fqdn',
    }), 'create_firewall_address for FQDN ok');
    $firewall_address{'fqdn_acme.example.net'} = 1;

    is($fortimanager->get_firewall_address('fqdn_acme.example.net'),
        hash {
            field 'fqdn'    => 'acme.example.net';
            field 'type'    => 'fqdn';

            etc();
        }, 'get_firewall_address for FQDN ok');

    ok($fortimanager->update_firewall_address('range_test1', {
        'end-ip'    => '192.0.2.30',
    }), 'update_firewall_address for range ok');

    ok($fortimanager->delete_firewall_address('range_test1'),
        'delete_firewall_address ok');
    delete $firewall_address{range_test1};
};

subtest_buffered 'IPv4 address groups' => sub {
    is($fortimanager->list_firewall_address_groups,
        bag {
            all_items hash {
                field 'name'    => D();
                field 'type'    => D();
                field 'member'  => bag{
                    etc();
                };

                etc();
            };

            end();
        },
        'list_firewall_address_groups ok');

    ok($fortimanager->create_firewall_address_group('grp_test1', {
        member => [qw(
            host_test1
            net_test1
            fqdn_acme.example.net
        )],
    }), 'create_firewall_address_group ok');
    $firewall_address_group{grp_test1} = 1;

    is($fortimanager->get_firewall_address_group('grp_test1'),
        hash {
            field 'name'    => 'grp_test1';
            field 'type'    => 'default';
            field 'member'  => bag {
                item 'host_test1';
                item 'net_test1';
                item 'fqdn_acme.example.net';

                end();
            };

            etc();
        }, 'get_firewall_address_group ok');

    ok($fortimanager->update_firewall_address_group('grp_test1', {
        member => [qw(
            host_test1
            fqdn_acme.example.net
        )],
    }), 'update_firewall_address_group ok');

    ok($fortimanager->delete_firewall_address_group('grp_test1'),
        'delete_firewall_address_group ok');
    delete $firewall_address_group{grp_test1};
};

subtest_buffered 'IPv6 objects' => sub {
    is($fortimanager->list_firewall_ipv6_addresses,
        bag {
            all_items hash {
                field 'name'    => D();
                field 'type'    => D();

                etc();
            };

            end();
        },
        'list_firewall_ipv6_addresses ok');

    ok($fortimanager->create_firewall_ipv6_address('host_v6_test1', {
        ip6 => '2001:db8::a/128',
    }), 'create_firewall_ipv6_address for host ok');
    $firewall_ipv6_address{host_v6_test1} = 1;

    ok($fortimanager->create_firewall_ipv6_address('net_v6_test1', {
        ip6 => '2001:db8::0/64',
    }), 'create_firewall_ipv6_address for network ok');
    $firewall_ipv6_address{net_v6_test1} = 1;

    ok($fortimanager->create_firewall_ipv6_address('range_v6_test1', {
        'start-ip'  => '2001:db8::a',
        'end-ip'    => '2001:db8::14',
        type        => 'iprange',
    }), 'create_firewall_ipv6_address for range ok');
    $firewall_ipv6_address{range_v6_test1} = 1;

    ok($fortimanager->create_firewall_ipv6_address('fqdn_v6_acme.example.net', {
        fqdn    => 'acme.example.net',
        type    => 'fqdn',
    }), 'create_firewall_ipv6_address for FQDN ok');
    $firewall_ipv6_address{'fqdn_v6_acme.example.net'} = 1;

    is($fortimanager->get_firewall_ipv6_address('fqdn_v6_acme.example.net'),
        hash {
            field 'fqdn'    => 'acme.example.net';
            field 'type'    => 'fqdn';

            etc();
        }, 'get_firewall_ipv6_address for FQDN ok');

    ok($fortimanager->update_firewall_ipv6_address('range_v6_test1', {
        'end-ip'    => '2001:db8::1d',
    }), 'update_firewall_ipv6_address for range ok');

    ok($fortimanager->delete_firewall_ipv6_address('range_v6_test1'),
        'delete_firewall_ipv6_address ok');
    delete $firewall_ipv6_address{range_v6_test1};
};

subtest_buffered 'IPv6 address groups' => sub {
    is($fortimanager->list_firewall_ipv6_address_groups,
        bag {
            all_items hash {
                field 'name' => D();
                field 'member' => bag{
                    etc();
                };

                etc();
            };

            end();
        },
        'list_firewall_ipv6_address_groups ok');

    ok($fortimanager->create_firewall_ipv6_address_group('grp_v6_test1', {
        member => [qw(
            host_v6_test1
            net_v6_test1
            fqdn_v6_acme.example.net
        )],
    }), 'create_firewall_ipv6_address_group ok');
    $firewall_ipv6_address_group{grp_v6_test1} = 1;

    is(my $rv = $fortimanager->get_firewall_ipv6_address_group('grp_v6_test1'),
        hash {
            field 'name'    => 'grp_v6_test1';
            field 'member'  => bag {
                item 'host_v6_test1';
                item 'net_v6_test1';
                item 'fqdn_v6_acme.example.net';

                end();
            };

            etc();
        }, 'get_firewall_ipv6_address_group ok');

    ok($fortimanager->update_firewall_ipv6_address_group('grp_v6_test1', {
        member => [qw(
            host_v6_test1
            fqdn_v6_acme.example.net
        )],
    }), 'update_firewall_ipv6_address_group ok');

    ok($fortimanager->delete_firewall_ipv6_address_group('grp_v6_test1'),
        'delete_firewall_ipv6_address_group ok');
    delete $firewall_ipv6_address_group{grp_v6_test1};
};


subtest_buffered 'wildcard FQDN objects' => sub {
    is($fortimanager->list_firewall_wildcard_fqdns,
        bag {
            all_items hash {
                field 'name'            => D();
                field 'wildcard-fqdn'   => D();

                etc();
            };

            end();
        },
        'list_firewall_wildcard_fqdns ok');

    ok($fortimanager->create_firewall_wildcard_fqdn('wildcard.example.org', {
        'wildcard-fqdn' => '*.example.org',
    }), 'create_firewall_wildcard_fqdn ok');
    $firewall_wildcard_fqdn{'wildcard.example.org'} = 1;

    ok($fortimanager->update_firewall_wildcard_fqdn('wildcard.example.org', {
        'wildcard-fqdn' => '*.example.com',
    }), 'update_firewall_wildcard_fqdn ok');

    ok($fortimanager->delete_firewall_wildcard_fqdn('wildcard.example.org'),
        'delete_firewall_wildcard_fqdn ok');
    delete $firewall_wildcard_fqdn{'wildcard.example.org'};
};

subtest_buffered 'service objects' => sub {
    is($fortimanager->list_firewall_services,
        bag {
            all_items hash {
                field 'name'        => D();
                field 'protocol'    => D();

                etc();
            };

            end();
        },
        'list_firewall_services ok');

    ok($fortimanager->create_firewall_service('test_tcp_1234', {
        protocol        => 'TCP/UDP/SCTP',
        'tcp-portrange' => '1234'
    }), 'create_firewall_service for TCP service ok');
    $firewall_service{test_tcp_1234} = 1;

    ok($fortimanager->create_firewall_service('test_udp_1234', {
        protocol        => 'TCP/UDP/SCTP',
        'udp-portrange' => '1234'
    }), 'create_firewall_service for UDP service ok');
    $firewall_service{test_udp_1234} = 1;

    ok($fortimanager->create_firewall_service('test_icmp_echo', {
        protocol        => 'ICMP',
        icmptype        => '8'
    }), 'create_firewall_service for ICMP service ok');
    $firewall_service{test_icmp_echo} = 1;

    is($fortimanager->get_firewall_service('test_tcp_1234'),
        hash {
            field 'protocol'        => 'TCP/UDP/SCTP';
            field 'tcp-portrange'   => array {
                item '1234';

                end();
            };

            etc();
        }, 'get_firewall_service for TCP service ok');

    ok($fortimanager->update_firewall_service('test_tcp_1234', {
        'tcp-portrange' => '12345'
    }), 'update_firewall_service for TCP service ok');

    ok($fortimanager->delete_firewall_service('test_tcp_1234'),
        'delete_firewall_service ok');
    delete $firewall_service{test_tcp_1234};
};

subtest_buffered 'service groups' => sub {
    is($fortimanager->list_firewall_service_groups,
        bag {
            all_items hash {
                field 'name'    => D();
                field 'member'  => bag {
                    etc();
                };

                etc();
            };

            end();
        },
        'list_firewall_service_groups ok');

    ok($fortimanager->create_firewall_service_group('grp_test1', {
        member => [qw(
            test_udp_1234
            test_icmp_echo
        )],
    }), 'create_firewall_service_group ok');
    $firewall_service_group{grp_test1} = 1;

    is($fortimanager->get_firewall_service_group('grp_test1'),
        hash {
            field 'name'    => 'grp_test1';
            field 'member'  => bag {
                item 'test_udp_1234';
                item 'test_icmp_echo';

                end();
            };

            etc();
        }, 'get_firewall_service_group ok');

    ok($fortimanager->update_firewall_service_group('grp_test1', {
        member => [qw(
            test_udp_1234
        )],
    }), 'update_firewall_service_group ok');

    ok($fortimanager->delete_firewall_service_group('grp_test1'),
        'delete_firewall_service_group ok');
    delete $firewall_service_group{grp_test1};
};

subtest_buffered 'policy packages' => sub {
    ok($fortimanager->create_policy_package(
        $ENV{NET_FORTINET_FORTIMANAGER_POLICY}, {
        'package settings'  => {
            'central-nat'               => 'enable',
            'fwpolicy-implicit-log'     => 'enable',
            'fwpolicy6-implicit-log'    => 'enable',
            'ngfw-mode'                 => 'profile-based',
        },
        type                => 'pkg',
    }), 'create_policy_package ok');
    $policy_package{$ENV{NET_FORTINET_FORTIMANAGER_POLICY}} = 1;

    is($fortimanager->get_policy_package(
        $ENV{NET_FORTINET_FORTIMANAGER_POLICY}),
        hash {
            field 'name'    => $ENV{NET_FORTINET_FORTIMANAGER_POLICY};
            field 'type'    => 'pkg';
            field 'package settings' => hash {
                field 'central-nat'  => 'enable';
                field 'ngfw-mode'    => 'profile-based';

                etc();
            };

            etc();
        }, 'get_policy_package ok');

    is($fortimanager->list_policy_packages,
        bag {
            all_items hash {
                field 'name'    => D();
                field 'type'    => D();

                etc();
            };

            end();
        },
        'list_policy_packages ok');

    is(my $ipv4_policy = $fortimanager->create_firewall_policy(
        $ENV{NET_FORTINET_FORTIMANAGER_POLICY}, {
            action          => 'accept',
            'global-label'  => 'Section 1',
            name            => 'policy1_v4',
            dstaddr         => 'fqdn_acme.example.net',
            dstintf         => 'any',
            srcaddr         => 'net_test1',
            srcintf         => 'any',
            service         => 'test_udp_1234',
            status          => 'enable',
            logtraffic      => 'all',
            schedule        => 'always',
    }), hash {
        field 'policyid' => D();

        end();
    }, 'create_firewall_policy for IPv4 policy ok');

    is(my $ipv6_policy = $fortimanager->create_firewall_policy(
        $ENV{NET_FORTINET_FORTIMANAGER_POLICY}, {
            action          => 'accept',
            'global-label'  => 'Section 1',
            name            => 'policy1_v6',
            dstaddr6        => 'fqdn_v6_acme.example.net',
            dstintf         => 'any',
            srcaddr6        => 'net_v6_test1',
            srcintf         => 'any',
            service         => 'test_udp_1234',
            status          => 'enable',
            logtraffic      => 'all',
            schedule        => 'always',
    }), hash {
        field 'policyid' => D();

        end();
    }, 'create_firewall_policy for IPv6 policy ok');

    is($fortimanager->get_firewall_policy(
            $ENV{NET_FORTINET_FORTIMANAGER_POLICY},
            $ipv4_policy->{policyid},
        ),
        hash {
            field 'policyid'        => $ipv4_policy->{policyid};
            field 'global-label'    => 'Section 1';
            field 'status'          => 'enable';
            field 'action'          => 'accept';
            field 'logtraffic'      => 'all';
            field 'schedule'        => bag {
                item 'always';

                end();
            };
            field 'name'            => 'policy1_v4';
            field 'dstaddr'         => bag {
                item 'fqdn_acme.example.net';

                end();
            };
            field 'dstaddr6'        => bag {
                etc();
            };
            field 'dstintf'         => bag {
                item 'any';

                end();
            };
            field 'srcaddr'         => bag {
                item 'net_test1';

                end();
            };
            field 'srcaddr6'        => bag {
                etc();
            };
            field 'srcintf'         => bag {
                item 'any';

                end();
            };
            field 'service'         => bag {
                item 'test_udp_1234';

                end();
            };

            etc();
        }, 'get_firewall_policy ok');

    is($fortimanager->list_firewall_policies(
        $ENV{NET_FORTINET_FORTIMANAGER_POLICY}),
        bag {
            all_items hash {
                field 'policyid'        => D();
                field 'global-label'    => D();
                field 'status'          => D();
                field 'action'          => D();
                field 'logtraffic'      => D();
                field 'schedule'        => bag {
                    etc();
                };
                field 'name'            => D();
                field 'dstaddr'         => bag {
                    etc();
                };
                field 'dstaddr6'        => bag {
                    etc();
                };
                field 'dstintf'         => bag {
                    etc();
                };
                field 'srcaddr'         => bag {
                    etc();
                };
                field 'srcaddr6'        => bag {
                    etc();
                };
                field 'srcintf'         => bag {
                    etc();
                };
                field 'service'        => bag {
                    etc();
                };

                etc();
            };

            end();
        },
        'list_firewall_policies ok');

    is($fortimanager->update_firewall_policy(
        $ENV{NET_FORTINET_FORTIMANAGER_POLICY}, $ipv4_policy->{policyid}, {
            action          => 'deny',
    }), hash {
        field 'policyid' => D();

        end();
    }, 'update_firewall_policy ok');

    ok($fortimanager->delete_firewall_policy(
        $ENV{NET_FORTINET_FORTIMANAGER_POLICY}, $ipv6_policy->{policyid}),
        'delete_firewall_policy ok');

    ok($fortimanager->update_policy_package(
        $ENV{NET_FORTINET_FORTIMANAGER_POLICY}, {
        'package settings'  => {
            'ngfw-mode'     => 'policy-based',
        },
    }), 'update_policy_package ok');


    is(my $ipv4_sec_policy = $fortimanager->create_firewall_security_policy(
        $ENV{NET_FORTINET_FORTIMANAGER_POLICY}, {
            action          => 'accept',
            'global-label'  => 'Section 1',
            name            => 'security-policy1_v4',
            dstaddr         => 'fqdn_acme.example.net',
            dstintf         => 'any',
            srcaddr         => 'net_test1',
            srcintf         => 'any',
            service         => 'test_udp_1234',
            status          => 'enable',
            logtraffic      => 'all',
            schedule        => 'always',
    }), hash {
        field 'policyid' => D();

        end();
    }, 'create_firewall_security_policy for IPv4 policy ok');

    is(my $ipv6_sec_policy = $fortimanager->create_firewall_security_policy(
        $ENV{NET_FORTINET_FORTIMANAGER_POLICY}, {
            action          => 'accept',
            'global-label'  => 'Section 1',
            name            => 'security-policy1_v6',
            dstaddr6        => 'fqdn_v6_acme.example.net',
            dstintf         => 'any',
            srcaddr6        => 'net_v6_test1',
            srcintf         => 'any',
            service         => 'test_udp_1234',
            status          => 'enable',
            logtraffic      => 'all',
            schedule        => 'always',
    }), hash {
        field 'policyid' => D();

        end();
    }, 'create_firewall_security_policy for IPv6 policy ok');

    is($fortimanager->get_firewall_security_policy(
            $ENV{NET_FORTINET_FORTIMANAGER_POLICY},
            $ipv4_sec_policy->{policyid},
        ),
        hash {
            field 'policyid'        => $ipv4_sec_policy->{policyid};
            field 'global-label'    => 'Section 1';
            field 'status'          => 'enable';
            field 'action'          => 'accept';
            field 'logtraffic'      => 'all';
            field 'schedule'        => bag {
                item 'always';

                end();
            };
            field 'name'            => 'security-policy1_v4';
            field 'dstaddr'         => bag {
                item 'fqdn_acme.example.net';

                end();
            };
            field 'dstaddr6'        => bag {
                etc();
            };
            field 'dstintf'         => bag {
                item 'any';

                end();
            };
            field 'srcaddr'         => bag {
                item 'net_test1';

                end();
            };
            field 'srcaddr6'        => bag {
                etc();
            };
            field 'srcintf'         => bag {
                item 'any';

                end();
            };
            field 'service'         => bag {
                item 'test_udp_1234';

                end();
            };

            etc();
        }, 'get_firewall_security_policy ok');

    is($fortimanager->list_firewall_security_policies(
        $ENV{NET_FORTINET_FORTIMANAGER_POLICY}),
        bag {
            all_items hash {
                field 'policyid'        => D();
                field 'global-label'    => D();
                field 'status'          => D();
                field 'action'          => D();
                field 'logtraffic'      => D();
                field 'name'            => D();
                field 'dstaddr'         => bag {
                    etc();
                };
                field 'dstaddr6'        => bag {
                    etc();
                };
                field 'srcaddr'         => bag {
                    etc();
                };
                field 'srcaddr6'        => bag {
                    etc();
                };
                field 'service'        => bag {
                    etc();
                };

                etc();
            };

            end();
        },
        'list_firewall_security_policies ok');

    is($fortimanager->update_firewall_security_policy(
        $ENV{NET_FORTINET_FORTIMANAGER_POLICY}, $ipv4_sec_policy->{policyid}, {
            action          => 'deny',
    }), hash {
        field 'policyid' => D();

        end();
    }, 'update_firewall_security_policy ok');

    ok($fortimanager->delete_firewall_security_policy(
        $ENV{NET_FORTINET_FORTIMANAGER_POLICY}, $ipv6_sec_policy->{policyid}),
        'delete_firewall_security_policy ok');

    my $task_check = hash {
        field 'adom'        => D();
        field 'id'          => D();
        field 'end_tm'      => D();
        field 'line'        => bag {
            all_items hash {
                field 'detail'  => D();
                field 'end_tm'  => D();
                field 'err'     => D();
                field 'history' => bag {
                    all_items hash {
                        field 'detail'  => D();
                        field 'name'    => D();
                        field 'percent' => D();
                        field 'vdom'    => E();
                    };

                    etc();
                };
                field 'ip'          => E();
                field 'name'        => D();
                field 'oid'         => D();
                field 'percent'     => D();
                field 'start_tm'    => D();
                field 'state'       => D();
                field 'vdom'        => E();

                etc();
            };

            etc();
        };
        field 'num_done'    => D();
        field 'num_err'     => D();
        field 'num_lines'   => D();
        field 'num_warn'    => D();
        field 'percent'     => D();
        field 'pid'         => D();
        field 'src'         => D();
        field 'start_tm'    => D();
        field 'state'       => D();
        field 'title'       => D();
        field 'tot_percent' => D();
        field 'user'        => D();

        etc();
    };

    is(my $tasks = $fortimanager->list_tasks(),
        bag {
            all_items $task_check;

            end();
        },
        'list_tasks ok');

    SKIP: {
        skip "get_task tests because none available"
            unless $tasks->@* > 0;

        is($fortimanager->get_task($tasks->[0]->{id}),
            $task_check,
            'get_task ok');
    }

    ok($fortimanager->delete_policy_package(
        $ENV{NET_FORTINET_FORTIMANAGER_POLICY}),
        'delete_policy_package ok');
    delete $policy_package{$ENV{NET_FORTINET_FORTIMANAGER_POLICY}};
};

done_testing();
