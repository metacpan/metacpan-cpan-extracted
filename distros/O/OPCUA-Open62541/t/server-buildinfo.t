use strict;
use warnings;

use OPCUA::Open62541;
use OPCUA::Open62541::Test::Server;

use Test::More tests => 5;
use Test::Deep;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;

ok(my $server = OPCUA::Open62541::Server->new(), "server new");
ok(my $config = $server->getConfig(), "config get");
my %buildinfo = (
	BuildInfo_productName => "OPC UA server",
	BuildInfo_manufacturerName => "some company",
	BuildInfo_productUri => "https://opcfoundation.org/",
);
$config->setBuildInfo(\%buildinfo);

my $bi = $config->getBuildInfo();

cmp_deeply(
    $bi,
    {
	BuildInfo_buildDate => 0,
	BuildInfo_buildNumber => undef,
	BuildInfo_softwareVersion => undef,
	%buildinfo,
    },
    "buildinfo hash"
);

no_leaks_ok { $config->setBuildInfo(\%buildinfo) } "setBuildInfo leak";
