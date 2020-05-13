use strict;
use warnings;
use OPCUA::Open62541;

use Test::More tests => 14;
use Test::Exception;
use Test::NoWarnings;

my $log_calls = 0;
sub log {
    my ($context, $level, $category, $message) = @_;
    return if $log_calls++;
    is($log_calls, 1, "log once");
    is($context, "client", "log context");
    is($level, "info", "log level");
    is($category, "client", "log category");
    is($message, "Connecting to endpoint opc.tcp://localhost:", "log message");
}

my $clear_calls = 0;
sub clear {
    my ($context) = @_;
    $clear_calls++;
    is($clear_calls, 1, "clear once");
    is($context, "client", "clear context");

    fail "clear function is not called for client in open62541 1.0.1";
    # https://github.com/open62541/open62541/commit/
    #   280012ee016e2f42ab9b1386174a8c12e6b29821
}

{
    ok(my $client = OPCUA::Open62541::Client->new(), "client");
    {
	ok(my $config = $client->getConfig(), "config");
	ok(my $logger = $config->getLogger(), "logger");
	lives_ok { $logger->setCallback(\&log, "client", \&clear) } "set log";
    }
    is($clear_calls, 0, "logger scope");

    is($log_calls, 0, "logger begin");
    $client->connect("opc.tcp://localhost:");
    isnt($log_calls, 0, "logger begin");
}
is($clear_calls, 0, "client scope");  # XXX should be 1, bug in open62541 1.0.1
