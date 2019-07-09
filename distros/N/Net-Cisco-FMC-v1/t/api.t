use Test2::V0;
use Test2::Tools::Compare qw( array hash D );
use Net::Cisco::FMC::v1;
use JSON qw();

SKIP: {
    skip "environment variables not set"
        unless exists $ENV{NET_CISCO_FMC_V1_HOSTNAME}
            && exists $ENV{NET_CISCO_FMC_V1_USERNAME}
            && exists $ENV{NET_CISCO_FMC_V1_PASSWORD}
            && exists $ENV{NET_CISCO_FMC_V1_POLICY};
};

my $fmc = Net::Cisco::FMC::v1->new(
    server      => 'https://' . $ENV{NET_CISCO_FMC_V1_HOSTNAME},
    user        => $ENV{NET_CISCO_FMC_V1_USERNAME},
    passwd      => $ENV{NET_CISCO_FMC_V1_PASSWORD},
    clientattrs => { timeout => 30 },
);

ok($fmc->login, 'login to FMC successful');

ok(my $policy = $fmc->create_accesspolicy({
    name => $ENV{NET_CISCO_FMC_V1_POLICY},
    defaultAction => {
        action => 'BLOCK',
        logBegin => 1,
        sendEventsToFMC => 1,
    },
}), 'access policy created');

END { $fmc->delete_accesspolicy($policy->{id}); }

ok(my $accessrules = $fmc->list_accessrules($policy->{id}),
    'list accessrules successful');
is($accessrules->{items}, [], 'access policy has no rules');

ok(my $ipv4_literal_rule = $fmc->create_accessrule(
    $policy->{id},
    {
        name                => 'simple IPv4 literals rule',
        action              => 'ALLOW',
        enabled             => JSON->boolean(1),
        sourceNetworks      => {
            literals => [
                {
                    type => 'Network',
                    value => '10.0.0.0/24',
                },
            ],
        },
        destinationNetworks => {
            literals => [
                {
                    type => 'Host',
                    value => '10.0.0.10',
                },
                {
                    type => 'Host',
                    value => '10.0.0.11',
                },
            ],
        },
        destinationPorts    => {
            literals => [
                {
                    type     => 'PortLiteral',
                    protocol => '6',
                    port     => '53',
                },
                {
                    type     => 'PortLiteral',
                    protocol => '17',
                    port     => '53',
                },
            ],
        },
    },
), 'simple IPv4 literals rule created');
ok($accessrules = $fmc->list_accessrules($policy->{id}),
    'list accessrules successful');
is($accessrules,
    hash {
        field items => array {
            item hash {
                field id => D();
                field links => hash{
                    etc();
                };
                field name => 'simple IPv4 literals rule';
                field type => 'AccessRule';
                end();
            };
            end();
        };
        end();
    }, 'access policy has one rule');

ok(my $ipv6_literal_rule = $fmc->create_accessrule(
    $policy->{id},
    {
        name                => 'simple IPv6 literals rule',
        action              => 'ALLOW',
        enabled             => JSON->boolean(1),
        sourceNetworks      => {
            literals => [
                {
                    type => 'Network',
                    value => '2001:0db8::/56',
                },
            ],
        },
        destinationNetworks => {
            literals => [
                {
                    type => 'Host',
                    value => '2001:0db8::a',
                },
                {
                    type => 'Host',
                    value => '2001:0db8::b',
                },
            ],
        },
        destinationPorts    => {
            literals => [
                {
                    type     => 'PortLiteral',
                    protocol => '6',
                    port     => '53',
                },
                {
                    type     => 'PortLiteral',
                    protocol => '17',
                    port     => '53',
                },
            ],
        },
    },
), 'simple IPv6 literals rule created');
ok($accessrules = $fmc->list_accessrules($policy->{id}),
    'list accessrules successful');
is($accessrules,
    hash {
        field items => array {
            item hash {
                field id => D();
                field links => hash{
                    etc();
                };
                field name => 'simple IPv4 literals rule';
                field type => 'AccessRule';
                end();
            };
            item hash {
                field id => D();
                field links => hash{
                    etc();
                };
                field name => 'simple IPv6 literals rule';
                field type => 'AccessRule';
                end();
            };
            end();
        };
        end();
    }, 'access policy has two rules');

ok($ipv4_literal_rule = $fmc->update_accessrule(
    $policy->{id},
    $ipv4_literal_rule,
    {
        urls => {
            urlCategoriesWithReputation => [
              {
                category => {
                    type => 'URLCategory',
                    name => 'Uncategorized',
                },
                type => 'UrlCategoryAndReputation',
              },
            ],
        },
    },
), 'URL categories added to simple IPv4 literals rule');

ok($ipv4_literal_rule = $fmc->update_accessrule(
    $policy->{id},
    $ipv4_literal_rule,
    {
        enabled => JSON->boolean(0),
    },
), 'simple IPv4 literals rule disabled');

ok($fmc->delete_accessrule(
    $policy->{id},
    $ipv4_literal_rule->{id}
), 'simple IPv4 literals rule deleted');

done_testing;
