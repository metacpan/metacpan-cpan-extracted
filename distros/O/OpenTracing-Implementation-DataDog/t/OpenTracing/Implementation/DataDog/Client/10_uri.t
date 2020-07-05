use Test::Most;
use Test::URI;

use aliased 'OpenTracing::Implementation::DataDog::Client';

subtest "Does create the correct URI from given parameters" => sub {
    
    
    my $datadog_client;
    lives_ok {
        $datadog_client = Client->new(
            http_user_agent => bless( {} ,'MyStub::UserAgent' ),
            scheme          => 'https',
            host            => 'test-host',
            port            => '1234',
            path            => 'my/traces',
        ) # we do need defaults here, to not break when ENV was set already
    } "Created a 'datadog_client'"
    
    or return;
    
    my $uri = $datadog_client->uri;
    
    uri_scheme_ok( $uri, 'https');
    uri_host_ok  ( $uri, 'test-host');
    uri_port_ok  ( $uri, '1234');
    uri_path_ok  ( $uri, '/my/traces');
    
};

done_testing;

package MyStub::UserAgent;

sub request { ... }
