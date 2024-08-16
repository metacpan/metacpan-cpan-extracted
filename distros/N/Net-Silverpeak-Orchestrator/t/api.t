use Test2::V0;
use Test2::Tools::Compare qw( array bag hash all_items all_values );
use Test2::Tools::Subtest qw( subtest_buffered );
use List::Util qw( first );
use Net::Silverpeak::Orchestrator;

skip_all "environment variables not set"
    unless (exists $ENV{NET_SILVERPEAK_ORCHESTRATOR_HOSTNAME}
        && exists $ENV{NET_SILVERPEAK_ORCHESTRATOR_USERNAME}
        && exists $ENV{NET_SILVERPEAK_ORCHESTRATOR_PASSWORD}
        && exists $ENV{NET_SILVERPEAK_ORCHESTRATOR_POLICY});

my $orchestrator = Net::Silverpeak::Orchestrator->new(
    server      => 'https://' . $ENV{NET_SILVERPEAK_ORCHESTRATOR_HOSTNAME},
    user        => $ENV{NET_SILVERPEAK_ORCHESTRATOR_USERNAME},
    passwd      => $ENV{NET_SILVERPEAK_ORCHESTRATOR_PASSWORD},
    clientattrs => { timeout => 30 },
);

ok($orchestrator->login, 'login to Silverpeak Orchestrator successful');

END {
    diag('logging out');
    $orchestrator->logout
        if defined $orchestrator;
}

my $version = $orchestrator->get_version;
like($version, qr/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/,
    'get_version ok');

is($orchestrator->_is_version_93, D(), '_is_version_93 ok');
diag 'running against a version ' . (
    $orchestrator->_is_version_93
    ? '>= 9.3'
    : '< 9.3')
    . " Orchestrator: $version";

like (
    dies {
        my $res = $orchestrator->get('/gms/rest/nonexisting');
        $orchestrator->_error_handler($res)
            unless $res->code == 200;
    },
    qr/^error \(404\): /,
    'nonexisting url throws correct exception'
);

is(my $templategroups = $orchestrator->list_templategroups,
    array {
        etc();
    },
    'list_templategroups ok');

isnt($templategroups,
    bag {
        item hash {
            field name => $ENV{NET_SILVERPEAK_ORCHESTRATOR_POLICY};
            etc();
        };

        etc();
    },
    "template group '" . $ENV{NET_SILVERPEAK_ORCHESTRATOR_POLICY} .
        "' doesn't exist"
);

like(
    dies { $orchestrator->get_templategroup('not-existing') },
    qr/Failed to get Templates for group/,
    'get_templategroup for not existing template group throws exception'
);

ok($orchestrator->create_templategroup(
    $ENV{NET_SILVERPEAK_ORCHESTRATOR_POLICY}),
    "template group '" . $ENV{NET_SILVERPEAK_ORCHESTRATOR_POLICY} .
        "' created");

END {
    diag("deleting template group 'Net-Silverpeak-Orchestrator-Test'");
    $orchestrator->delete_templategroup(
        $ENV{NET_SILVERPEAK_ORCHESTRATOR_POLICY})
        if defined $orchestrator;
}

ok($orchestrator->update_templates_of_templategroup(
    $ENV{NET_SILVERPEAK_ORCHESTRATOR_POLICY}, ['securityMaps']),
    "Security Policy added to template group '" .
    $ENV{NET_SILVERPEAK_ORCHESTRATOR_POLICY} . "'");

is(my $templategroup = $orchestrator->get_templategroup(
    $ENV{NET_SILVERPEAK_ORCHESTRATOR_POLICY}),
    hash {
        etc();
    },
    'get_templategroup for existing template group ok');

my ($security_template) = grep { $_->{name} eq 'securityMaps' }
    $templategroup->{selectedTemplates}->@*;

ok($security_template, 'securityMaps template found in template group');

ok(exists $security_template->{value}->{data}->{map1}
    && ref $security_template->{value}->{data}->{map1}
        eq 'HASH',
    'securityMaps return data structure as expected');

$security_template->{value}->{data}->{map1}->{'0_0'}->{prio}->{1010} =
    {
        match=> {
            dst_ip => "10.0.0.10/32|10.0.0.11/32",
            dst_port => 53,
            protocol => "udp",
            src_ip => "10.0.0.0/24",
        },
        misc => {
            logging => "disable",
            rule => "enable",
            tag => 'rule_1',
        },
        set => {
            action => "allow",
        },
    };

ok(
    lives {
        $orchestrator->update_templategroup(
        $ENV{NET_SILVERPEAK_ORCHESTRATOR_POLICY}, {
            name => $ENV{NET_SILVERPEAK_ORCHESTRATOR_POLICY},
            templates => [
                {
                    name      => 'securityMaps',
                    valObject => $security_template->{value},
                }
            ]
        });
    }, 'update_templategroup successful') or note($@);

ok($orchestrator->has_segmentation_enabled,
    'Orchestrator has segmentation enabled');

is($orchestrator->get_vrf_by_id,
    hash {
        etc();
    },
    'get_vrf_by_id ok');

is($orchestrator->get_vrf_zones_map,
    hash {
        all_keys  match qr/^[0-9]+$/;
        all_vals hash {
            all_keys  match qr/^[0-9]+$/;
            all_vals hash {
                field id    => match qr/^[0-9]+$/;
                field name  => D();
                end();
            };
            etc();
        };
        etc();
    },
    'get_vrf_zones_map ok');

is(my $vrf_security_policy = $orchestrator->get_vrf_security_policies_by_ids(0, 0),
    hash {
        field data      => in_set(U(), hash {
            etc();
        });
        field settings  => hash {
            etc();
        };
        field options   => hash {
            etc();
        };
        end();
    },
    'get_vrf_security_policies_by_ids ok');
$vrf_security_policy->{data} = {}
    unless defined $vrf_security_policy->{data};
ok($orchestrator->update_vrf_security_policies_by_ids(0, 0, $vrf_security_policy),
    'update_vrf_security_policies_by_ids ok');

is(my $appliances = $orchestrator->list_appliances,
    array {
        etc();
    },
    'list_appliances ok');

ok(
    dies { $orchestrator->get_appliance('not-existing') },
    'get_appliance for not existing appliance throws exception'
);

ok(
    dies { $orchestrator->get_appliance_extrainfo('not-existing') },
    'get_appliance_extrainfo for not existing appliance throws exception'
);

is(my $appliance_groups = $orchestrator->list_groups,
    array {
        etc();
    },
    'list_groups ok');

ok(
    dies { $orchestrator->get_deployment('not-existing') },
    'get_deployment for not existing appliance throws exception'
);

is($orchestrator->get_interface_labels_by_type,
    hash {
        etc();
    },
    'get_interface_labels_by_type ok');

is($orchestrator->get_ha_groups_by_id,
    hash {
        etc();
    },
    'get_ha_groups_by_id ok');

is($orchestrator->list_template_applianceassociations,
    hash {
        etc();
    },
    'list_template_applianceassociations ok');

SKIP: {
    skip "Orchestrator has no appliances"
        unless $appliances->@*;
    my $test_appliance = first { $_->{state} == 1 } $appliances->@*;
    skip "No reachable appliance found"
        unless defined $test_appliance;

    diag "using appliance $test_appliance->{hostName} for tests";

    is($orchestrator->get_appliance($test_appliance->{id}),
        hash {
            etc();
        },
        'get_appliance for existing appliance ok');

    is($orchestrator->get_appliance_extrainfo($test_appliance->{id}),
        hash {
            etc();
        },
        'get_appliance_extrainfo for existing appliance ok');

    is(my $deployment = $orchestrator->get_deployment($test_appliance->{id}),
        hash {
            etc();
        },
        'get_deployment for existing appliance ok');

    my $test_interface = first { first {  } $_->{applianceIPs}->@* } $deployment->{modeIfs}->@*;

    is($orchestrator->get_interface_state($test_appliance->{id}),
        hash {
            etc();
        },
        'get_interface_state ok');

    is($orchestrator->get_appliance_ipsla_configs($test_appliance->{id}),
        hash {
            etc();
        },
        'get_appliance_ipsla_configs ok');

    is($orchestrator->get_appliance_ipsla_states($test_appliance->{id}),
        hash {
            etc();
        },
        'get_appliance_ipsla_states ok');

    is($orchestrator->get_appliance_bgp_system_config($test_appliance->{id}),
        hash {
            etc();
        },
        'get_appliance_bgp_system_config ok');

    is($orchestrator->get_appliance_bgp_system_config_allvrfs($test_appliance->{id}),
        hash {
            etc();
        },
        'get_appliance_bgp_system_config_allvrfs ok');

    is($orchestrator->get_appliance_bgp_neighbors($test_appliance->{id}),
        hash {
            etc();
        },
        'get_appliance_bgp_neighbors ok');

    is($orchestrator->list_applianceids_by_templategroupname(
        $ENV{NET_SILVERPEAK_ORCHESTRATOR_POLICY}),
        array {
            all_items match qr/^[0-9]+\.[A-Z]+$/;

            etc();
        },
        'list_appliances_by_templategroupname ok');
}

subtest_buffered 'address groups' => sub {
    is($orchestrator->list_addressgroup_names,
        bag {
            all_items match qr/^[a-zA-Z0-9_\-\.]+$/;

            end();
        },
        'list_addressgroup_names ok');

    is($orchestrator->list_addressgroups,
        bag {
            all_items hash {
                field name => match qr/^[a-zA-Z0-9_\-\.]+$/;
                field type => 'AG';
                field rules => bag {
                    all_items hash {
                        field includedIPs => array {
                            etc();
                        };
                        field excludedIPs => array {
                            etc();
                        };
                        field includedGroups => array {
                            etc();
                        };
                        field comment => E();

                        end();
                    };

                    end();
                };

                end();
            };

            end();
        },
        'list_addressgroups ok');

    ok($orchestrator->create_or_update_addressgroup('Testgroup1', {
            rules => [
                {
                    includedIPs => [qw(
                        10.2.0.0/24
                        10.3.0.1-15
                        10.0.0.2
                        10.0.0.1
                        10.3.0.30-40
                        10.1.0.0/24
                    )],
                },
            ],
        }),
        'create_or_update_addressgroup ok');

    is($orchestrator->get_addressgroup('Testgroup1'),
        hash {
            field name => 'Testgroup1';
            field type => 'AG';
            field rules => array {
                item hash {
                    field includedIPs => array {
                        item '10.2.0.0/24';
                        item '10.3.0.1-15';
                        item '10.0.0.2';
                        item '10.0.0.1';
                        item '10.3.0.30-40';
                        item '10.1.0.0/24';
                        end();
                    };
                    field excludedIPs => array {
                        end();
                    };
                    field includedGroups => array {
                        end();
                    };
                    field comment => U();

                    end();
                };

                end();
            };

            end();
        },
        'get_addressgroup ok');

    ok($orchestrator->update_addressgroup('Testgroup1', {
            rules => [
                {
                    includedIPs => [qw(
                        10.3.0.1-15
                        10.0.0.1
                        10.1.0.0/24
                    )],
                },
            ],
        }),
        'update_addressgroup ok');

    is($orchestrator->get_addressgroup('Testgroup1'),
        hash {
            field name => 'Testgroup1';
            field type => 'AG';
            field rules => array {
                item hash {
                    field includedIPs => array {
                        item '10.3.0.1-15';
                        item '10.0.0.1';
                        item '10.1.0.0/24';
                        end();
                    };
                    field excludedIPs => array {
                        end();
                    };
                    field includedGroups => array {
                        end();
                    };
                    field comment => U();

                    end();
                };

                end();
            };

            end();
        },
        'data after update_addressgroup ok');

    ok(
        dies { $orchestrator->update_addressgroup('not-existing', {
                rules => [
                    {
                        includedIPs => [qw( 0.0.0.1 )],
                    },
                ],
            }) },
        'update_addressgroup for not existing addressgroup throws exception'
    );

    ok($orchestrator->delete_addressgroup('Testgroup1'),
        'delete_addressgroup ok');
};

subtest_buffered 'service groups' => sub {
    is($orchestrator->list_servicegroup_names,
        bag {
            all_items match qr/^[a-zA-Z0-9_\-\.]+$/;

            end();
        },
        'list_servicegroup_names ok');

    is($orchestrator->list_servicegroups,
        bag {
            all_items hash {
                field name => match qr/^[a-zA-Z0-9_\-\.]+$/;
                field type => 'SG';
                field rules => bag {
                    all_items hash {
                        field protocol => D();

                        field includedPorts => array {
                            etc();
                        };
                        field excludedPorts => array {
                            etc();
                        };
                        field includedGroups => array {
                            etc();
                        };
                        field excludedGroups => array {
                            etc();
                        };
                        field icmpTypes => array {
                            etc();
                        };
                        field comment => E();

                        end();
                    };

                    end();
                };

                end();
            };

            end();
        },
        'list_servicegroups ok');

    ok($orchestrator->create_or_update_servicegroup('Testgroup1', {
            rules => [
                {
                    protocol => 'TCP',
                    includedPorts => [qw(
                        53
                        88
                        135
                        137-139
                        389
                        445
                        464
                        636
                        3268
                        3269
                        9389
                        49152-65535
                    )],
                },
                {
                    protocol => 'UDP',
                    includedPorts => [qw(
                        53
                        88
                        123
                        137-139
                        389
                        464
                    )],
                },
            ],
        }),
        'create_or_update_servicegroup ok');

    is($orchestrator->get_servicegroup('Testgroup1'),
        hash {
            field name => 'Testgroup1';
            field type => 'SG';
            field rules => array {
                item hash {
                    field protocol => 'TCP';
                    field includedPorts => array {
                        item '53';
                        item '88';
                        item '135';
                        item '137-139';
                        item '389';
                        item '445';
                        item '464';
                        item '636';
                        item '3268';
                        item '3269';
                        item '9389';
                        item '49152-65535';

                        end();
                    };
                    field excludedPorts => array {
                        end();
                    };
                    field includedGroups => array {
                        end();
                    };
                    field excludedGroups => array {
                        end();
                    };
                    field icmpTypes => array {
                        end();
                    };
                    field comment => U();

                    end();
                };

                item hash {
                    field protocol => 'UDP';
                    field includedPorts => array {
                        item '53';
                        item '88';
                        item '123';
                        item '137-139';
                        item '389';
                        item '464';

                        end();
                    };
                    field excludedPorts => array {
                        end();
                    };
                    field includedGroups => array {
                        end();
                    };
                    field excludedGroups => array {
                        end();
                    };
                    field icmpTypes => array {
                        end();
                    };
                    field comment => U();

                    end();
                };

                end();
            };

            end();
        },
        'get_servicegroup ok');

    ok($orchestrator->update_servicegroup('Testgroup1', {
        rules => [
            {
                protocol => 'TCP',
                includedPorts => [qw(
                    88
                    135
                    137-139
                    389
                    445
                    464
                    636
                    3268
                    3269
                    9389
                    49152-65535
                )],
            },
            {
                protocol => 'UDP',
                includedPorts => [qw(
                    88
                    123
                    137-139
                    389
                    464
                )],
            },
        ],
        }),
        'update_servicegroup ok');

    is($orchestrator->get_servicegroup('Testgroup1'),
        hash {
            field name => 'Testgroup1';
            field type => 'SG';
            field rules => array {
                item hash {
                    field protocol => 'TCP';
                    field includedPorts => array {
                        item '88';
                        item '135';
                        item '137-139';
                        item '389';
                        item '445';
                        item '464';
                        item '636';
                        item '3268';
                        item '3269';
                        item '9389';
                        item '49152-65535';

                        end();
                    };
                    field excludedPorts => array {
                        end();
                    };
                    field includedGroups => array {
                        end();
                    };
                    field excludedGroups => array {
                        end();
                    };
                    field icmpTypes => array {
                        end();
                    };
                    field comment => U();

                    end();
                };

                item hash {
                    field protocol => 'UDP';
                    field includedPorts => array {
                        item '88';
                        item '123';
                        item '137-139';
                        item '389';
                        item '464';

                        end();
                    };
                    field excludedPorts => array {
                        end();
                    };
                    field includedGroups => array {
                        end();
                    };
                    field excludedGroups => array {
                        end();
                    };
                    field icmpTypes => array {
                        end();
                    };
                    field comment => U();

                    end();
                };

                end();
            };

            end();
        },
        'data after update_servicegroup ok');

    ok(
        dies { $orchestrator->update_servicegroup('not-existing', {
                rules => [
                    {
                        includedPorts => [qw( 123 )],
                    },
                ],
            }) },
        'update_servicegroup for not existing servicegroup throws exception'
    );

    ok($orchestrator->delete_servicegroup('Testgroup1'),
        'delete_servicegroup ok');
};

subtest_buffered 'applications' => sub {
    is($orchestrator->list_domain_applications,
        bag {
            all_items hash {
                field domain => match qr/^[a-zA-Z0-9\-\.]+$/;
                field name => match qr/^[a-zA-Z0-9_\-\.]+$/;
                field description => E();
                field priority => validator(sub{ $_ >= 0 && $_ <= 100 });
                field disabled => check_isa('JSON::PP::Boolean');

                end();
            };

            end();
        },
        'list_domain_applications ok');

    ok($orchestrator->create_or_update_domain_application('acme.example.net', {
            name        => 'acme_example_net',
            priority    => 100,
        }),
        'create using create_or_update_domain_application ok');

    ok($orchestrator->create_or_update_domain_application('acme.example.net', {
            name        => 'acme.example.net',
            priority    => 90,
        }),
        'update using create_or_update_domain_application ok');

    ok($orchestrator->delete_domain_application('acme.example.net'),
        'delete_domain_application ok');
};

subtest_buffered 'application groups' => sub {
    is($orchestrator->list_application_groups,
        hash {
            all_values hash {
                field apps => bag {
                    all_items match qr/^[a-zA-Z0-9_\-\.]+$/;

                    end();
                };

                etc();
            };

            etc();
        },
        'list_application_groups ok');

    $orchestrator->create_or_update_domain_application('api.example.net', {
            name        => 'api.example.net',
            priority    => 100,
        });

    ok($orchestrator->create_or_update_application_group('cloud_services', {
            apps => [
                'api.example.net',
            ],
        }),
        'create using create_or_update_application_group ok');

    $orchestrator->create_or_update_domain_application('api.example2.net', {
            name        => 'api.example2.net',
            priority    => 100,
        });

    ok($orchestrator->create_or_update_application_group('cloud_services', {
            apps => [
                'api.example.net',
                'api.example2.net',
            ],
        }),
        'update using create_or_update_application_group ok');

    is($orchestrator->list_application_groups,
        hash {
            field 'cloud_services' => hash {
                field apps => bag {
                    item 'api.example.net';
                    item 'api.example2.net';

                    end();
                };

                etc();
            };

            etc();
        },
        'updated application group correct');

    ok($orchestrator->delete_application_group('cloud_services'),
        'delete_application_group ok');

    is($orchestrator->list_application_groups,
        hash {
            field 'cloud_services' => DNE();

            etc();
        },
        'deleted application group not in listing');
};

done_testing();
