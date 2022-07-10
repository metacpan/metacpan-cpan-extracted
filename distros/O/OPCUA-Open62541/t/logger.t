use strict;
use warnings;
use OPCUA::Open62541;

use Test::More tests => 47;
use Test::Exception;
use Test::LeakTrace;
use Test::NoWarnings;
use Test::Warn;

ok(my $server = OPCUA::Open62541::Server->new(), "server new");
ok(my $config = $server->getConfig(), "config get");
ok(my $logger = $config->getLogger(), "logger get");
is(ref($logger), "OPCUA::Open62541::Logger", "logger class");
no_leaks_ok { $config->getLogger() } "logger get leak";

lives_ok { $logger->setCallback(undef, undef, undef) } "setCallback";
no_leaks_ok { $logger->setCallback(undef, undef, undef) } "setCallback leak";

throws_ok { $logger->setCallback("foo", undef, undef) }
    (qr/Log 'foo' is not a CODE reference/, "setCallback noref log");
no_leaks_ok { eval { $logger->setCallback("foo", undef, undef) } }
    "setCallback noref log leak";

throws_ok { $logger->setCallback(undef, undef, "bar") }
    (qr/Clear 'bar' is not a CODE reference/, "setCallback noref clear");
no_leaks_ok { eval { $logger->setCallback(undef, undef, "bar") } }
    "setCallback noref clear leak";

my $log_calls = 0;
sub log {
    my ($context, $level, $category, $message) = @_;
    if ($log_calls++ == 0) {
	is($log_calls, 1, "log once");
	is($context, "context", "log context string");
    }
    cmp_ok($category, '==', 1, "category warning") if $level == 3;
    cmp_ok($category, '==', 2, "category error") if $level == 4;
    cmp_ok($category, '==', 3, "category fatal") if $level == 5;
    is($message, "message", "message warning") if $level == 3;
    is($message, "number 7", "message error") if $level == 4;
    is($message, "number 7 string 'foo'", "message fatal") if $level == 5;
    is($message, "msg args %s", "message info") if $level == 2;
}

lives_ok { $logger->setCallback(\&log, "context", undef) }
    "setCallback log context";
no_leaks_ok {
    $logger->setCallback(\&log, "context", undef);
} "setCallback log context leak";

lives_ok { $logger->logWarning(1, "message") } "logWarning message";
lives_ok { $logger->logError(2, "number %d", 7) } "logError number";
lives_ok { $logger->logFatal(3, "number %d string '%s'", 7, "foo") }
    "logFatal number string";
lives_ok { $logger->logInfo(0, "msg %s", "args %s") } "logInfo format";

sub nolog {
    my ($context, $level, $category, $message) = @_;
}

no_leaks_ok {
    $logger->setCallback(\&nolog, undef, undef);
    $logger->logWarning(0, "message");
    $logger->logError(0, "number %d", 7);
    $logger->logFatal(0, "number %d string '%s'", 7, "foo");
} "no log leak";

warning_like { $logger->logError("category", "message") }
    (qr/Argument "category" isn't numeric in subroutine /, "warn category");
warning_like { $logger->logWarning(1, "too many", "foo") }
    (qr/Redundant argument in subroutine /, "warn too many args");
warning_like { $logger->logFatal(1, "too %s few %s", "foo") }
    (qr/Missing argument in subroutine /, "warn too few args");
warning_like { $logger->logInfo(1, "wrong %d type %s", "foo", 7) }
    (qr/Argument "foo" isn't numeric in subroutine /, "warn wrong type args");

sub log_level_name {
    my ($context, $level, $category, $message) = @_;

    is($level, "trace", "$message trace") if $level == 0;
    is($level, "debug", "$message debug") if $level == 1;
    is($level, "info",  "$message info")  if $level == 2;
    is($level, "warn",  "$message warn")  if $level == 3;
    is($level, "error", "$message error") if $level == 4;
    is($level, "fatal", "$message fatal") if $level == 5;
    is($level, 6,       "$message bad")   if $level == 6;
}

$logger->setCallback(\&log_level_name, undef, undef);

# not all tests are execurted, depends on UA_LOGLEVEL define
$logger->logTrace(  0, "level name");
$logger->logDebug(  0, "level name");
$logger->logInfo(   0, "level name");
$logger->logWarning(0, "level name");
$logger->logError(  0, "level name");
$logger->logFatal(  0, "level name");

sub log_category_name {
    my ($context, $level, $category, $message) = @_;

    is($category, "network",        "$message network")   if $category == 0;
    is($category, "channel",        "$message channel")   if $category == 1;
    is($category, "session",        "$message session")   if $category == 2;
    is($category, "server",         "$message server")    if $category == 3;
    is($category, "client",         "$message client")    if $category == 4;
    is($category, "userland",       "$message userland")  if $category == 5;
    is($category, "securitypolicy", "$message security")  if $category == 6;
    is($category, "eventloop",      "$message eventloop") if $category == 7;
    is($category, 8,                "$message bad")       if $category == 8;
}

$logger->setCallback(\&log_category_name, undef, undef);

foreach my $category (0..8) {
    $logger->logInfo($category, "category name");
}

my $clear_calls = 0;
sub clear {
    my ($context) = @_;
    $clear_calls++;
    is($clear_calls, 1, "clear once");
    is($context, undef, "clear context string");
}

$logger->setCallback(undef, undef, \&clear);
