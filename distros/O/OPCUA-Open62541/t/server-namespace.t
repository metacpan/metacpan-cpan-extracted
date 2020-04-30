use strict;
use warnings;
use OPCUA::Open62541 ':all';

use OPCUA::Open62541::Test::Server;
use Test::More tests => OPCUA::Open62541::Test::Server::planning_nofork() + 7;
use Test::NoWarnings;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();

is($server->{server}->run_startup(), STATUSCODE_GOOD, "startup");
cmp_ok($server->{server}->run_iterate(0), '>', 0, "iterate");

my %namespaceNodeId = (
    NodeId_namespaceIndex	=> 0,
    NodeId_identifierType	=> NODEIDTYPE_NUMERIC,
    NodeId_identifier		=> NS0ID_SERVER_NAMESPACEARRAY,
);

my %namespace = (
    Variant_array => [
	'http://opcfoundation.org/UA/',
	'urn:open62541.server.application'
    ],
    Variant_type => 11,
);

my $out;
my $newns = 'foobar';
is($server->{server}->readValue(\%namespaceNodeId, \$out),
    STATUSCODE_GOOD, "get server namespace value");
is_deeply($out, \%namespace, "namespace");

is($server->{server}->addNamespace($newns), 2, "add namespace");

push(@{$namespace{Variant_array}}, $newns);

is($server->{server}->readValue(\%namespaceNodeId, \$out),
    STATUSCODE_GOOD, "get server namespace value");
is_deeply($out, \%namespace, "namespace");
