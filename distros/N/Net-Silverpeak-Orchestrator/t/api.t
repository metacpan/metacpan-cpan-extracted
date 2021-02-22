use Test2::V0;
use Test2::Tools::Compare qw( array hash );
use Net::Silverpeak::Orchestrator;

subtest 'user/password authentication' => sub {
    SKIP: {
    skip "environment variables not set"
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

    like($orchestrator->get_version, qr/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/,
        'get_version ok');

    is($orchestrator->list_templategroups,
        array {
            etc();
        },
        'list_templategroups ok');

    like(
        dies { $orchestrator->get_templategroup('not-existing') },
        qr/Failed to get Templates for group/,
        'get_templategroup for not existing template group throws exception'
    );

    is(my $templategroup = $orchestrator->get_templategroup('LocalSecurity'),
        hash {
            etc();
        },
        'get_templategroup for existing template group ok');

    my ($security_template) = grep { $_->{name} eq 'securityMaps' }
        $templategroup->{selectedTemplates}->@*;

    ok($security_template, 'securityMaps template found in template group');

    ok(exists $security_template->{value}->{data}->{map1}->{'0_0'}->{prio}
        && ref $security_template->{value}->{data}->{map1}->{'0_0'}->{prio}
            eq 'HASH',
        'securityMaps return data structure as expected');

    my $rules = $security_template->{value}->{data}->{map1}->{'0_0'}->{prio};
    $rules->{1010}->{misc}->{rule} =
        $rules->{1010}->{misc}->{rule} eq 'enable'
        ? 'disable'
        : 'enable';

    ok(
        lives {
            $orchestrator->update_templategroup('LocalSecurity', {
                name => 'LocalSecurity',
                templates => [
                    {
                        name      => 'securityMaps',
                        valObject => $security_template->{value},
                    }
                ]
            });
        }, 'update_templategroup successful') or note($@);

    is(my $appliances = $orchestrator->list_appliances,
        array {
            etc();
        },
        'list_appliances ok');

    ok(
        dies { $orchestrator->get_appliance('not-existing') },
        'get_appliance for not existing appliance throws exception'
    );

    is($orchestrator->get_appliance($appliances->[0]->{id}),
        hash {
            etc();
        },
        'get_appliance for existing appliance ok');

    is($orchestrator->list_template_applianceassociations,
        hash {
            etc();
        },
        'list_template_applianceassociations ok');

    is($orchestrator->list_applianceids_by_templategroupname('LocalSecurity'),
        array {
            all_items match qr/^[0-9]+\.[A-Z]+$/;

            etc();
        },
        'list_appliances_by_templategroupname ok');

    ok($orchestrator->logout, 'logout of Silverpeak Orchestrator successful');
    };
};

subtest 'api key authentication' => sub {
    SKIP: {
    skip "environment variables not set"
        unless (exists $ENV{NET_SILVERPEAK_ORCHESTRATOR_HOSTNAME}
            && exists $ENV{NET_SILVERPEAK_ORCHESTRATOR_API_KEY}
            && exists $ENV{NET_SILVERPEAK_ORCHESTRATOR_POLICY});

    my $orchestrator = Net::Silverpeak::Orchestrator->new(
        server      => 'https://' . $ENV{NET_SILVERPEAK_ORCHESTRATOR_HOSTNAME},
        api_key     => $ENV{NET_SILVERPEAK_ORCHESTRATOR_API_KEY},
        clientattrs => { timeout => 30 },
    );

    like($orchestrator->get_version, qr/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/,
        'get_version ok');

    like(
        dies { $orchestrator->login },
        qr/user and password required/,
        'login throws exception'
    );

    like(
        dies { $orchestrator->logout },
        qr/user and password required/,
        'logout throws exception'
    );

    };
};

done_testing();
