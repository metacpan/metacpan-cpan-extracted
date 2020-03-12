use strict;
use warnings;
use OPCUA::Open62541;

use Test::More tests => 10;
use Test::Exception;
use Test::NoWarnings;

my $once = 0;
sub log {
    my ($context, $level, $category, $message) = @_;
    return if $once++;
    is($context, "client", "log context");
    is($level, "info", "log level");
    is($category, "client", "log category");
    is($message, "Connecting to endpoint opc.tcp://localhost:", "log message");
}

sub clear {
    my ($context) = @_;
    is($context, "client", "clear context");
}

ok(my $client = OPCUA::Open62541::Client->new(), "client");
ok(my $config = $client->getConfig(), "config");
ok(my $logger = $config->getLogger(), "logger");
lives_ok { $logger->setCallback(\&log, "client", \&clear) } "set log";

$client->connect("opc.tcp://localhost:");
