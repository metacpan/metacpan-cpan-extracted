use strict;
use warnings;

use OPCUA::Open62541 qw(:all);
use OPCUA::Open62541::Test::Client;
use OPCUA::Open62541::Test::Server;

use Test::More tests =>
    OPCUA::Open62541::Test::Server::planning() +
    OPCUA::Open62541::Test::Client::planning() + 23;
use Test::Deep;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;

my $server = OPCUA::Open62541::Test::Server->new();

$server->start();
$server->run();

my $client = OPCUA::Open62541::Test::Client->new(port => $server->port());
$client->start();

my $servers;
my $serverurl_valid      = 'opc.tcp://127.0.0.1:' . $server->port . '/';
my $serverurl_invalid    = 'opc.tcp://127.0.0.2:' . $server->port . '/';
my $serverurl            = '';
my $applicationuri_valid = 'urn:open62541.server.application';
my $applicationuris      = undef;
my $localeid_valid       = 'en';
my $localeids            = undef;

my $expected = [{
    ApplicationDescription_gatewayServerUri => undef,
    ApplicationDescription_applicationType => 0,
    ApplicationDescription_discoveryProfileUri => undef,
    ApplicationDescription_discoveryUrls => [$serverurl_valid],
    ApplicationDescription_applicationName => {
	LocalizedText_locale => 'en',
	LocalizedText_text => 'open62541-based OPC UA Application'
    },
    ApplicationDescription_productUri => 'http://open62541.org',
    ApplicationDescription_applicationUri => $applicationuri_valid
}];

note 'test parameter croaks';

throws_ok { $client->{client}->findServers($serverurl, undef, undef, undef) }
    (qr/Output parameter registeredServers is not a scalar reference/,
    'registeredServers parameter undef');

throws_ok { $client->{client}->findServers($serverurl, undef, undef, 5) }
    (qr/Output parameter registeredServers is not a scalar reference/,
    'registeredServers parameter scalar');

throws_ok { $client->{client}->findServers($serverurl, undef, undef, []) }
    (qr/Output parameter registeredServers is not a scalar reference/,
    'registeredServers parameter array ref');

throws_ok { $client->{client}->findServers($serverurl, undef, undef, \5) }
    (qr/Output parameter registeredServers is not a scalar reference/,
    'registeredServers parameter read only ref');

no_leaks_ok { eval { $client->{client}->findServers($serverurl, undef, undef, undef) } }
    'leaks registeredServers parameter undef';

no_leaks_ok { eval { $client->{client}->findServers($serverurl, undef, undef, \5) } }
    'leaks registeredServers parameter read only ref';

throws_ok { $client->{client}->findServers($serverurl, {}, undef, \$servers) }
    (qr/Not an ARRAY reference with String list/,
    'serveruri parameter no arrayref');

no_leaks_ok { eval { $client->{client}->findServers($serverurl, {}, undef, \$servers) } }
    'leaks serveruri parameter no arrayref';

note 'test valid';

$serverurl = $serverurl_valid;

is $client->{client}->findServers($serverurl, undef, undef, \$servers), 'Good',
   'status findservers valid';
cmp_deeply $servers, $expected, 'data findservers valid';
no_leaks_ok {
    my $servers;
    $client->{client}->findServers($serverurl, undef, undef, \$servers)
} 'leaks findservers valid';

note 'test invalid';

$serverurl = $serverurl_invalid;

is $client->{client}->findServers($serverurl, undef, undef, \$servers), 'BadDisconnect',
   'status findservers invalid';
cmp_deeply $servers, [], 'data findservers invalid';
no_leaks_ok {
    my $servers;
    $client->{client}->findServers($serverurl, undef, undef, \$servers)
} 'leaks findservers invalid';

note 'test limit serveruri match';

$serverurl = $serverurl_valid;
$applicationuris = [$applicationuri_valid];

is $client->{client}->findServers($serverurl, $applicationuris, undef, \$servers), 'Good',
   'status findservers serveruri match';
cmp_deeply $servers, $expected, 'data findservers serveruri match';
no_leaks_ok {
    my $servers;
    $client->{client}->findServers($serverurl, $applicationuris, undef, \$servers)
} 'leaks findservers serveruri match';

note 'test limit serveruri no match';

$serverurl = $serverurl_valid;
$applicationuris = ['foobar'];

is $client->{client}->findServers($serverurl, $applicationuris, undef, \$servers), 'Good',
   'status findservers serveruri no match';
cmp_deeply $servers, [], 'data findservers serveruri no match';
no_leaks_ok {
    my $servers;
    $client->{client}->findServers($serverurl, $applicationuris, undef, \$servers)
} 'leaks findservers serveruri no match';

note 'test limit localeid match';

$serverurl = $serverurl_valid;
$localeids = [$localeid_valid];

is $client->{client}->findServers($serverurl, undef, $localeids, \$servers), 'Good',
   'status findservers localeid match';
cmp_deeply $servers, $expected, 'data findservers localeid match';
no_leaks_ok {
    my $servers;
    $client->{client}->findServers($serverurl, undef, $localeids, \$servers)
} 'leaks findservers localeid match';

note 'test limit localeid no match';

# since the locale is only a request from the client, open62541 still chooses a
# suitable server if no locale matched. so the returned server list is not empty

$serverurl = $serverurl_valid;
$localeids = ['foobar'];

is $client->{client}->findServers($serverurl, undef, $localeids, \$servers), 'Good',
   'status findservers localeid no match';
cmp_deeply $servers, $expected, 'data findservers localeid no match';
no_leaks_ok {
    my $servers;
    $client->{client}->findServers($serverurl, undef, $localeids, \$servers)
} 'leaks findservers localeid no match';

$client->stop();
$server->stop();
