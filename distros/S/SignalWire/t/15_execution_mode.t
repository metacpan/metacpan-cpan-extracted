#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use SignalWire::Core::LoggingConfig;
use SignalWire::Utils;

# Cross-language parity tests for SignalWire::Core::LoggingConfig::get_execution_mode
# and SignalWire::Utils::is_serverless_mode. Mirrors
# signalwire-python/tests/unit/utils/test_execution_mode.py.

my @ENV_KEYS = qw(
    GATEWAY_INTERFACE
    AWS_LAMBDA_FUNCTION_NAME
    LAMBDA_TASK_ROOT
    FUNCTION_TARGET
    K_SERVICE
    GOOGLE_CLOUD_PROJECT
    AZURE_FUNCTIONS_ENVIRONMENT
    FUNCTIONS_WORKER_RUNTIME
    AzureWebJobsStorage
);

# Snapshot every relevant env var so the test cleans up after itself.
my %SAVED = map { $_ => $ENV{$_} } @ENV_KEYS;

sub clear_env {
    delete $ENV{$_} for @ENV_KEYS;
}

sub restore_env {
    delete $ENV{$_} for @ENV_KEYS;
    for my $k (keys %SAVED) {
        $ENV{$k} = $SAVED{$k} if defined $SAVED{$k};
    }
}

# ----------------------------------------------------------------------
# get_execution_mode — every branch.
# ----------------------------------------------------------------------

subtest 'default is server' => sub {
    clear_env();
    is(SignalWire::Core::LoggingConfig::get_execution_mode(), 'server',
       'no env vars -> server');
};

subtest 'cgi via GATEWAY_INTERFACE' => sub {
    clear_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    is(SignalWire::Core::LoggingConfig::get_execution_mode(), 'cgi');
};

subtest 'lambda via AWS_LAMBDA_FUNCTION_NAME' => sub {
    clear_env();
    $ENV{AWS_LAMBDA_FUNCTION_NAME} = 'my-fn';
    is(SignalWire::Core::LoggingConfig::get_execution_mode(), 'lambda');
};

subtest 'lambda via LAMBDA_TASK_ROOT' => sub {
    clear_env();
    $ENV{LAMBDA_TASK_ROOT} = '/var/task';
    is(SignalWire::Core::LoggingConfig::get_execution_mode(), 'lambda');
};

subtest 'google_cloud_function via FUNCTION_TARGET' => sub {
    clear_env();
    $ENV{FUNCTION_TARGET} = 'my_handler';
    is(SignalWire::Core::LoggingConfig::get_execution_mode(),
       'google_cloud_function');
};

subtest 'google_cloud_function via K_SERVICE' => sub {
    clear_env();
    $ENV{K_SERVICE} = 'svc';
    is(SignalWire::Core::LoggingConfig::get_execution_mode(),
       'google_cloud_function');
};

subtest 'google_cloud_function via GOOGLE_CLOUD_PROJECT' => sub {
    clear_env();
    $ENV{GOOGLE_CLOUD_PROJECT} = 'proj';
    is(SignalWire::Core::LoggingConfig::get_execution_mode(),
       'google_cloud_function');
};

subtest 'azure_function via AZURE_FUNCTIONS_ENVIRONMENT' => sub {
    clear_env();
    $ENV{AZURE_FUNCTIONS_ENVIRONMENT} = 'Production';
    is(SignalWire::Core::LoggingConfig::get_execution_mode(),
       'azure_function');
};

subtest 'azure_function via FUNCTIONS_WORKER_RUNTIME' => sub {
    clear_env();
    $ENV{FUNCTIONS_WORKER_RUNTIME} = 'perl';
    is(SignalWire::Core::LoggingConfig::get_execution_mode(),
       'azure_function');
};

subtest 'azure_function via AzureWebJobsStorage' => sub {
    clear_env();
    $ENV{AzureWebJobsStorage} = 'DefaultEndpointsProtocol=https';
    is(SignalWire::Core::LoggingConfig::get_execution_mode(),
       'azure_function');
};

# CGI must beat Lambda — cross-language precedence contract.
subtest 'cgi beats lambda' => sub {
    clear_env();
    $ENV{GATEWAY_INTERFACE}        = 'CGI/1.1';
    $ENV{AWS_LAMBDA_FUNCTION_NAME} = 'my-fn';
    is(SignalWire::Core::LoggingConfig::get_execution_mode(), 'cgi');
};

subtest 'lambda beats google_cloud' => sub {
    clear_env();
    $ENV{AWS_LAMBDA_FUNCTION_NAME} = 'my-fn';
    $ENV{FUNCTION_TARGET}          = 'h';
    is(SignalWire::Core::LoggingConfig::get_execution_mode(), 'lambda');
};

subtest 'google_cloud beats azure' => sub {
    clear_env();
    $ENV{FUNCTION_TARGET}             = 'h';
    $ENV{AZURE_FUNCTIONS_ENVIRONMENT} = 'Production';
    is(SignalWire::Core::LoggingConfig::get_execution_mode(),
       'google_cloud_function');
};

# ----------------------------------------------------------------------
# is_serverless_mode.
# ----------------------------------------------------------------------

subtest 'server is not serverless' => sub {
    clear_env();
    ok(!SignalWire::Utils::is_serverless_mode(),
       'server mode -> not serverless');
};

subtest 'lambda is serverless' => sub {
    clear_env();
    $ENV{AWS_LAMBDA_FUNCTION_NAME} = 'my-fn';
    ok(SignalWire::Utils::is_serverless_mode(), 'lambda -> serverless');
};

# CGI is short-lived per request — counts as serverless.
subtest 'cgi is serverless' => sub {
    clear_env();
    $ENV{GATEWAY_INTERFACE} = 'CGI/1.1';
    ok(SignalWire::Utils::is_serverless_mode(), 'cgi -> serverless');
};

subtest 'azure is serverless' => sub {
    clear_env();
    $ENV{AZURE_FUNCTIONS_ENVIRONMENT} = 'Production';
    ok(SignalWire::Utils::is_serverless_mode(), 'azure -> serverless');
};

# Python parity: signalwire.core.logging_config.get_logger($name) is a
# module-level free function.
subtest 'get_logger free function returns structured logger' => sub {
    my $logger = SignalWire::Core::LoggingConfig::get_logger('test_logger');
    isa_ok($logger, 'SignalWire::Logging', 'returns SignalWire::Logging instance');
    is($logger->name, 'test_logger', 'logger has the requested name');
    can_ok($logger, qw(debug info warn error));
};

subtest 'get_logger same name returns same instance (memoized)' => sub {
    my $a = SignalWire::Core::LoggingConfig::get_logger('logger_x');
    my $b = SignalWire::Core::LoggingConfig::get_logger('logger_x');
    is($a, $b, 'same name returns same instance');
};

subtest 'get_logger different names return distinct loggers' => sub {
    my $a = SignalWire::Core::LoggingConfig::get_logger('logger_p');
    my $b = SignalWire::Core::LoggingConfig::get_logger('logger_q');
    isnt($a, $b, 'different names are distinct loggers');
    is($a->name, 'logger_p', 'p name');
    is($b->name, 'logger_q', 'q name');
};

restore_env();

done_testing();
