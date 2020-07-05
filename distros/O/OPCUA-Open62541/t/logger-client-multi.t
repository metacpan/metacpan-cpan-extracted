use strict;
use warnings;
use OPCUA::Open62541;

use OPCUA::Open62541::Test::Server;
use Test::More tests => OPCUA::Open62541::Test::Server::planning_nofork() + 103;
use Test::Exception;
use Test::NoWarnings;

my $server = OPCUA::Open62541::Test::Server->new();
$server->start();
ok(my $buildinfo = $server->{config}->getBuildInfo());
note explain $buildinfo;

my $log_context;
my $log_calls = 0;
sub log {
    my ($context, $level, $category, $message) = @_;
    $log_calls++;
    $log_context = $context;
}

my $clear_context;
my $clear_calls = 0;
sub clear {
    my ($context) = @_;
    $clear_calls++;
    $clear_context = $context;
}

# one client, one config, one logger, set callback twice
{
    ok(my $client = OPCUA::Open62541::Client->new(), "client");
    $client->getConfig()->setDefault();
    {
	ok(my $config = $client->getConfig(), "config");
	ok(my $logger = $config->getLogger(), "logger");
	$logger->logWarning(1, "no callback");
	is($log_calls, 0, "no log call");
	is($log_context, undef, "no context");
	$logger->setCallback(\&log, "first", \&clear);
	$logger->logWarning(1, "first callback");
	is($log_calls, 1, "first log call");
	is($log_context, "first", "first context");
	$logger->setCallback(\&log, "second", \&clear);
	$logger->logWarning(1, "second callback");
	is($log_calls, 2, "second log call");
	is($log_context, "second", "second context");
    }
    is($clear_calls, 0, "logger scope");

    is($log_calls, 2, "logger begin");
    $client->connect("opc.tcp://localhost:");
    isnt($log_calls, 2, "logger end");
}
if ($buildinfo->{BuildInfo_softwareVersion} =~ /^1\.0\./) {
    is($clear_calls, 0, "client scope");  # bug in open62541
    is($clear_context, undef, "clear context");  # bug in open62541
} else {
    is($clear_calls, 1, "client scope");
    is($clear_context, "second", "clear context");
}

$log_calls = $clear_calls = 0;
$log_context = $clear_context = undef;

# one client, one config, two logger, set callback twice
{
    ok(my $client = OPCUA::Open62541::Client->new(), "two logger: client");
    $client->getConfig()->setDefault();
    {
	ok(my $config = $client->getConfig(), "two logger: config");
	ok(my $logger1 = $config->getLogger(), "two logger: logger");
	$logger1->logWarning(1, "two logger: no callback");
	is($log_calls, 0, "two logger: no log call");
	is($log_context, undef, "two logger: no context");
	$logger1->setCallback(\&log, "first", \&clear);
	$logger1->logWarning(1, "two logger: first callback");
	is($log_calls, 1, "two logger: first log call");
	is($log_context, "first", "two logger: first context");
	ok(my $logger2 = $config->getLogger(), "two logger: logger");
	$logger2->logWarning(1, "two logger: first callback 2");
	is($log_calls, 2, "two logger: first log call 2");
	is($log_context, "first", "two logger: first context 2");
	$logger2->setCallback(\&log, "second", \&clear);
	$logger2->logWarning(1, "two logger: second callback");
	is($log_calls, 3, "two logger: second log call");
	is($log_context, "second", "two logger: second context");
    }
    is($clear_calls, 0, "two logger: logger scope");

    is($log_calls, 3, "two logger: logger begin");
    $client->connect("opc.tcp://localhost:");
    isnt($log_calls, 3, "two logger: logger end");
}
if ($buildinfo->{BuildInfo_softwareVersion} =~ /^1\.0\./) {
    is($clear_calls, 0, "two logger: client scope");  # bug in open62541
    is($clear_context, undef, "two logger: clear context");  # bug in open62541
} else {
    is($clear_calls, 1, "two logger: client scope");
    is($clear_context, "second", "two logger: clear context");
}

$log_calls = $clear_calls = 0;
$log_context = $clear_context = undef;

# one client, two config, two logger, set callback twice
{
    ok(my $client = OPCUA::Open62541::Client->new(), "two config: client");
    $client->getConfig()->setDefault();
    {
	ok(my $config1 = $client->getConfig(), "two config: config 1");
	ok(my $logger1 = $config1->getLogger(), "two config: logger 1");
	$logger1->logWarning(1, "two config: no callback");
	is($log_calls, 0, "two config: no log call");
	is($log_context, undef, "two config: no context");
	$logger1->setCallback(\&log, "first", \&clear);
	$logger1->logWarning(1, "two config: first callback");
	is($log_calls, 1, "two config: first log call");
	is($log_context, "first", "two config: first context");
	ok(my $config2 = $client->getConfig(), "two config: config 2");
	ok(my $logger2 = $config2->getLogger(), "two config: logger 2");
	$logger2->logWarning(1, "two config: first callback 2");
	is($log_calls, 2, "two config: first log call 2");
	is($log_context, "first", "two config: first context 2");
	$logger2->setCallback(\&log, "second", \&clear);
	$logger2->logWarning(1, "two config: second callback");
	is($log_calls, 3, "two config: second log call");
	is($log_context, "second", "two config: second context");
    }
    is($clear_calls, 0, "two config: logger scope");

    is($log_calls, 3, "two config: logger begin");
    $client->connect("opc.tcp://localhost:");
    isnt($log_calls, 3, "two config: logger end");
}
if ($buildinfo->{BuildInfo_softwareVersion} =~ /^1\.0\./) {
    is($clear_calls, 0, "two config: client scope");  # bug in open62541
    is($clear_context, undef, "two config: clear context");  # bug in open62541
} else {
    is($clear_calls, 1, "two config: client scope");
    is($clear_context, "second", "two config: clear context");
}

$log_calls = $clear_calls = 0;
$log_context = $clear_context = undef;

# one client, two config in scope, two logger in scope, set callback twice
{
    ok(my $client = OPCUA::Open62541::Client->new(), "two scope: client");
    $client->getConfig()->setDefault();
    {
	ok(my $config1 = $client->getConfig(), "two scope: config 1");
	ok(my $logger1 = $config1->getLogger(), "two scope: logger 1");
	$logger1->logWarning(1, "two scope: no callback");
	is($log_calls, 0, "two scope: no log call");
	is($log_context, undef, "two scope: no context");
	$logger1->setCallback(\&log, "first", \&clear);
	$logger1->logWarning(1, "two scope: first callback");
	is($log_calls, 1, "two scope: first log call");
	is($log_context, "first", "two scope: first context");
    }
    {
	ok(my $config2 = $client->getConfig(), "two scope: config 2");
	ok(my $logger2 = $config2->getLogger(), "two scope: logger 2");
	$logger2->logWarning(1, "two scope: first callback 2");
	is($log_calls, 2, "two scope: first log call 2");
	is($log_context, "first", "two scope: first context 2");
	$logger2->setCallback(\&log, "second", \&clear);
	$logger2->logWarning(1, "two scope: second callback");
	is($log_calls, 3, "two scope: second log call");
	is($log_context, "second", "two scope: second context");
    }
    is($clear_calls, 0, "two scope: logger scope");

    is($log_calls, 3, "two scope: logger begin");
    $client->connect("opc.tcp://localhost:");
    isnt($log_calls, 3, "two scope: logger end");
}
if ($buildinfo->{BuildInfo_softwareVersion} =~ /^1\.0\./) {
    is($clear_calls, 0, "two scope: client scope");  # bug in open62541
    is($clear_context, undef, "two scope: clear context");  # bug
} else {
    is($clear_calls, 1, "two scope: client scope");
    is($clear_context, "second", "two scope: clear context");
}

$log_calls = $clear_calls = 0;
$log_context = $clear_context = undef;

# one client, one config, two logger in scope, set callback twice
{
    ok(my $client = OPCUA::Open62541::Client->new(),
	"two logger scope: client");
    $client->getConfig()->setDefault();
    ok(my $config = $client->getConfig(), "two logger scope: config 1");
    {
	ok(my $logger1 = $config->getLogger(), "two logger scope: logger 1");
	$logger1->logWarning(1, "two logger scope: no callback");
	is($log_calls, 0, "two logger scope: no log call");
	is($log_context, undef, "two logger scope: no context");
	$logger1->setCallback(\&log, "first", \&clear);
	$logger1->logWarning(1, "two logger scope: first callback");
	is($log_calls, 1, "two logger scope: first log call");
	is($log_context, "first", "two logger scope: first context");
    }
    {
	ok(my $logger2 = $config->getLogger(), "two logger scope: logger 2");
	$logger2->logWarning(1, "two logger scope: first callback 2");
	is($log_calls, 2, "two logger scope: first log call 2");
	is($log_context, "first", "two logger scope: first context 2");
	$logger2->setCallback(\&log, "second", \&clear);
	$logger2->logWarning(1, "two logger scope: second callback");
	is($log_calls, 3, "two logger scope: second log call");
	is($log_context, "second", "two logger scope: second context");
    }
    is($clear_calls, 0, "two logger scope: logger scope");

    is($log_calls, 3, "two logger scope: logger begin");
    $client->connect("opc.tcp://localhost:");
    isnt($log_calls, 3, "two logger scope: logger end");
}
if ($buildinfo->{BuildInfo_softwareVersion} =~ /^1\.0\./) {
    is($clear_calls, 0, "two logger scope: client scope");  # bug in open62541
    is($clear_context, undef, "two logger scope: clear context");  # bug
} else {
    is($clear_calls, 1, "two logger scope: client scope");
    is($clear_context, "second", "two logger scope: clear context");
}

$log_calls = $clear_calls = 0;
$log_context = $clear_context = undef;

# one client, two config in scope, two logger, set callback twice
{
    ok(my $client = OPCUA::Open62541::Client->new(),
	"two config scope: client");
    $client->getConfig()->setDefault();
    my $logger1;
    {
	ok(my $config1 = $client->getConfig(), "two config scope: config 1");
	ok($logger1 = $config1->getLogger(), "two config scope: logger 1");
    }
    $logger1->logWarning(1, "two config scope: no callback");
    is($log_calls, 0, "two config scope: no log call");
    is($log_context, undef, "two config scope: no context");
    $logger1->setCallback(\&log, "first", \&clear);
    $logger1->logWarning(1, "two config scope: first callback");
    is($log_calls, 1, "two config scope: first log call");
    is($log_context, "first", "two config scope: first context");
    my $logger2;
    {
	ok(my $config2 = $client->getConfig(), "two config scope: config 2");
	ok($logger2 = $config2->getLogger(), "two config scope: logger 2");
    }
    $logger2->logWarning(1, "two config scope: first callback 2");
    is($log_calls, 2, "two config scope: first log call 2");
    is($log_context, "first", "two config scope: first context 2");
    $logger2->setCallback(\&log, "second", \&clear);
    $logger2->logWarning(1, "two config scope: second callback");
    is($log_calls, 3, "two config scope: second log call");
    is($log_context, "second", "two config scope: second context");
    is($clear_calls, 0, "two config scope: logger scope");

    is($log_calls, 3, "two config scope: logger begin");
    $client->connect("opc.tcp://localhost:");
    isnt($log_calls, 3, "two config scope: logger end");
}
if ($buildinfo->{BuildInfo_softwareVersion} =~ /^1\.0\./) {
    is($clear_calls, 0, "two config scope: client scope");  # bug in open62541
    is($clear_context, undef, "two config scope: clear context");  # bug
} else {
    is($clear_calls, 1, "two config scope: client scope");
    is($clear_context, "second", "two config scope: clear context");
}
