use strict;
use warnings;
use OPCUA::Open62541;

use Test::More tests => 3;
use Test::LeakTrace;
use Test::NoWarnings;

sub nolog {
    my ($context, $level, $category, $message) = @_;
}

sub noclear {
    my ($context) = @_;
}

no_leaks_ok {
    my $logger;
    {
	my $config;
	{
	    my $server = OPCUA::Open62541::Server->new();
	    $config = $server->getConfig();
	}
	$logger = $config->getLogger();
    }
    $logger->setCallback(\&nolog, "storage", \&noclear);
    $logger->logFatal(1, "fatal");
} "logger storage leak";

no_leaks_ok {
    my $server = OPCUA::Open62541::Server->new();
    my $config = $server->getConfig();
    my $logger = $config->getLogger();
    $logger->setCallback(\&nolog, "malloc", \&noclear);
    $logger->logFatal(1, "fatal");
} "logger malloc leak";
