use strict;
use warnings;
use OPCUA::Open62541;

use OPCUA::Open62541::Test::Server;
use Test::More tests => OPCUA::Open62541::Test::Server::planning_nofork() + 17;
use Test::Exception;
use Test::NoWarnings;

my $buildinfo;
{
    my $server = OPCUA::Open62541::Test::Server->new();
    $server->start();
    ok($buildinfo = $server->{config}->getBuildInfo(), "buildinfo");
}
note explain $buildinfo;

my $log_calls = 0;
sub log {
    my ($context, $level, $category, $message) = @_;
    return if $log_calls++;
    is($log_calls, 1, "log once");
    is($context, "client", "log context");
    if ($buildinfo->{BuildInfo_softwareVersion} =~ /^1\.[1-3]\./) {
	is($level, "warn", "log level");
	is($category, "network", "log category");
	is($message, "Server url is invalid: opc.tcp://localhost:",
	    "log message");
    } else {
	is($level, "warn", "log level");
	is($category, "client", "log category");
	is($message, "skip verifying ApplicationURI for the SecurityPolicy ".
	    "http://opcfoundation.org/UA/SecurityPolicy#None",
	    "log message");
    }
}

my $clear_calls = 0;
sub clear {
    my ($context) = @_;
    $clear_calls++;
    is($clear_calls, 1, "clear once");
    is($context, "client", "clear context");
}

{
    ok(my $client = OPCUA::Open62541::Client->new(), "client");
    {
	ok(my $config = $client->getConfig(), "config");
	lives_ok { $config->setDefault() } "default";
	ok(my $logger = $config->getLogger(), "logger");
	lives_ok { $logger->setCallback(\&log, "client", \&clear) } "set log";
    }
    is($clear_calls, 0, "logger scope");

    is($log_calls, 0, "logger begin");
    $client->connect("opc.tcp://localhost:");
    isnt($log_calls, 0, "logger end");
}
is($clear_calls, 1, "client scope");
