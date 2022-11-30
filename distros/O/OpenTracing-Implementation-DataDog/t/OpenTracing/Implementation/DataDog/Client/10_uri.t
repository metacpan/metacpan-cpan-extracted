use Test::Most;
use Test::URI;

use aliased 'OpenTracing::Implementation::DataDog::Client';

# clean up env variables so they don't affect the test
undef $ENV{$_} foreach grep { /^DD_/ } keys %ENV;

my @cases = (
    {
        name        => 'Does create the correct URI from given parameters',
        make_client => sub {
            Client->new(
                http_user_agent => bless({}, 'MyStub::UserAgent'),
                scheme          => 'https',
                host            => 'test-host',
                port            => '1234',
                path            => 'my/traces',
            )
        },
        uri => {
            scheme => 'https',
            host   => 'test-host',
            port   => '1234',
            path   => '/my/traces',
        },
    },
    {
        name        => 'Uses the DD_HOST env variable for default host',
        make_client => sub {
            local $ENV{DD_HOST} = 'dd-host';
            Client->new(
                http_user_agent => bless({}, 'MyStub::UserAgent'),
                scheme          => 'https',
                port            => '1234',
                path            => 'my/traces',
            )
        },
        uri => {
            scheme => 'https',
            host   => 'dd-host',
            port   => '1234',
            path   => '/my/traces',
        },
    },
    {
        name        => 'Uses the DD_AGENT_HOST env variable for default host',
        make_client => sub {
            local $ENV{DD_AGENT_HOST} = 'dd-agent-host';
            Client->new(
                http_user_agent => bless({}, 'MyStub::UserAgent'),
                scheme          => 'https',
                port            => '1234',
                path            => 'my/traces',
            )
        },
        uri => {
            scheme => 'https',
            host   => 'dd-agent-host',
            port   => '1234',
            path   => '/my/traces',
        },
    },
    {
        name        => 'DD_HOST takes precedence over DD_AGENT_HOST',
        make_client => sub {
            local $ENV{DD_HOST}       = 'dd-host';
            local $ENV{DD_AGENT_HOST} = 'dd-agent-host';
            Client->new(
                http_user_agent => bless({}, 'MyStub::UserAgent'),
                scheme          => 'https',
                port            => '1234',
                path            => 'my/traces',
            )
        },
        uri => {
            scheme => 'https',
            host   => 'dd-host',
            port   => '1234',
            path   => '/my/traces',
        },
    },
);

for my $case (@cases) {
    subtest $case->{name} => sub {
        my $datadog_client;
        return unless lives_ok {
            $datadog_client = $case->{make_client}->()
        } "Created a 'datadog_client'";

        my $uri = $datadog_client->uri;

        uri_scheme_ok($uri, $case->{uri}{scheme});
        uri_host_ok($uri, $case->{uri}{host});
        uri_port_ok($uri, $case->{uri}{port});
        uri_path_ok($uri, $case->{uri}{path});
    };
}


done_testing;

package MyStub::UserAgent;

sub request { ... }
