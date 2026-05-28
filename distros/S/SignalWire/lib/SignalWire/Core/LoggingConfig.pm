package SignalWire::Core::LoggingConfig;
use strict;
use warnings;
use Exporter qw(import);
use SignalWire::Logging;

our @EXPORT_OK = qw(get_execution_mode get_logger);

# Python parity: signalwire.core.logging_config.get_logger(name) is a
# module-level factory that returns a structured logger bound to the
# given name. Perl's SignalWire::Logging->get_logger($name) is the
# class-method form; this free-function form mirrors Python's import
# shape so cross-port code reads the same.
sub get_logger {
    my ($name) = @_;
    return SignalWire::Logging->get_logger($name);
}

# Cross-language SDK contract for serverless / deployment-mode detection.
#
# Mirrors signalwire.core.logging_config.get_execution_mode in the Python
# reference. Order of precedence (FIRST match wins):
#
#   1. GATEWAY_INTERFACE                                       -> 'cgi'
#   2. AWS_LAMBDA_FUNCTION_NAME or LAMBDA_TASK_ROOT            -> 'lambda'
#   3. FUNCTION_TARGET, K_SERVICE, or GOOGLE_CLOUD_PROJECT     -> 'google_cloud_function'
#   4. AZURE_FUNCTIONS_ENVIRONMENT, FUNCTIONS_WORKER_RUNTIME,
#      or AzureWebJobsStorage                                  -> 'azure_function'
#   5. otherwise                                               -> 'server'
#
# Returns one of: 'cgi', 'lambda', 'google_cloud_function',
# 'azure_function', or 'server'.
sub get_execution_mode {
    return 'cgi'                    if _is_set('GATEWAY_INTERFACE');
    return 'lambda'                 if _is_set('AWS_LAMBDA_FUNCTION_NAME')
                                    || _is_set('LAMBDA_TASK_ROOT');
    return 'google_cloud_function'  if _is_set('FUNCTION_TARGET')
                                    || _is_set('K_SERVICE')
                                    || _is_set('GOOGLE_CLOUD_PROJECT');
    return 'azure_function'         if _is_set('AZURE_FUNCTIONS_ENVIRONMENT')
                                    || _is_set('FUNCTIONS_WORKER_RUNTIME')
                                    || _is_set('AzureWebJobsStorage');
    return 'server';
}

sub _is_set {
    my ($name) = @_;
    return defined $ENV{$name} && length $ENV{$name};
}

1;
