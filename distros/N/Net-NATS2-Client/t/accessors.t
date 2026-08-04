use strict;
use warnings;

use Test::More;
use JSON qw(to_json);

use Net::NATS2::Client;
use Net::NATS2::ConnectInfo;
use Net::NATS2::Connection;
use Net::NATS2::Message;
use Net::NATS2::ServerInfo;
use Net::NATS2::Subscription;
use Net::NATS2::URI;

{
    package Local::BaseTest;
    use Net::NATS2::Base;

    has plain => 'default';
    has lazy  => sub { $_[0]->plain . '-lazy' };
}

my $base = Local::BaseTest->new;
is($base->plain, 'default', 'base accessor applies scalar default');
is($base->lazy, 'default-lazy', 'base accessor applies lazy default');
is($base->plain('updated'), $base, 'base setter supports method chaining');
is($base->plain, 'updated', 'base setter updates value');

my $client = Net::NATS2::Client->new(uri => 'nats://localhost:4222');
is($client->uri, 'nats://localhost:4222', 'client accessor reads constructor value');
$client->current_sid(3);
is($client->current_sid, 3, 'client accessor stores value');
is($client->next_sid, 4, 'client returns the incremented subscription ID');

my $connection = bless {socket_args => {}}, 'Net::NATS2::Connection';
$connection->buffer('buffered');
is($connection->buffer, 'buffered', 'connection accessor stores value');

my $connect_info = Net::NATS2::ConnectInfo->new(lang => 'perl');
is($connect_info->lang,         'perl', 'connect info accessor reads constructor value');
is($connect_info->verbose,      0,      'connect info initializes verbose');
is($connect_info->headers,      0,      'connect info initializes headers support');
is($connect_info->tls_required, 0,      'connect info initializes TLS support');
$connect_info->tls_required(1);
my $connect_json = to_json($connect_info, {convert_blessed => 1});
like($connect_json, qr/"tls_required":true/, 'connect info serializes TLS support with the current protocol field');
unlike($connect_json, qr/"ssl_required"/, 'connect info omits the legacy SSL protocol field');

my @nonces;
my $nkey_client = Net::NATS2::Client->new(
    nkey        => 'UDXU4RCSJNZOIQHZNWXHXORDPRTGNJAHAHFRGZNEEJCPQTT2M7NLCNF4',
    nkey_sig_cb => sub { push @nonces, $_[0]; return "\xff\0" },
);
my $nkey_info = $nkey_client->_connect_info(
    Net::NATS2::ServerInfo->new(nonce => 'server-nonce'),
    Net::NATS2::URI->new('nats://localhost:4222'),
);
is_deeply(\@nonces, ['server-nonce'], 'NKey callback receives the server nonce');
is($nkey_info->nkey, $nkey_client->nkey, 'CONNECT includes the NKey public key');
is($nkey_info->sig, '_wA', 'CONNECT encodes the NKey signature as base64url');

my $message = Net::NATS2::Message->new(data => 'hello');
$message->data('goodbye');
is($message->data, 'goodbye', 'message accessor updates value');

my $server_info = Net::NATS2::ServerInfo->new(port => 4222);
is($server_info->port, 4222, 'server info accessor reads constructor value');

my $subscription = Net::NATS2::Subscription->new(subject => 'test');
is($subscription->message_count, 0, 'subscription initializes message count');
ok(!$subscription->defined_max, 'subscription max is initially undefined');
$subscription->max_msgs(1);
ok($subscription->defined_max, 'subscription defined predicate follows accessor');

my $uri = Net::NATS2::URI->new('nats://user:pass@example.test:4222');
isa_ok($uri, 'Net::NATS2::URI', 'nats URI uses the project URI adapter');
is($uri->host,     'example.test', 'URI adapter parses host');
is($uri->port,     4222,           'URI adapter parses port');
is($uri->user,     'user',         'URI adapter parses user');
is($uri->password, 'pass',         'URI adapter parses password');

done_testing;
