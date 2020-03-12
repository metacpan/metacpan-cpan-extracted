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
    is($context, "server", "log context");
    is($level, "warn", "log level");
    is($category, "server", "log category");
    is($message, "There has to be at least one endpoint.", "log message");
}

sub clear {
    my ($context) = @_;
    is($context, "server", "clear context");
}

ok(my $server = OPCUA::Open62541::Server->new(), "server");
ok(my $config = $server->getConfig(), "config");
ok(my $logger = $config->getLogger(), "logger");
lives_ok { $logger->setCallback(\&log, "server", \&clear) } "set log";

$server->run_startup();
$server->run_iterate(0);
$server->run_shutdown();
