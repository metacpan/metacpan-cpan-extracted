package SignalWire::Utils;
use strict;
use warnings;
use Exporter qw(import);

use SignalWire::Core::LoggingConfig ();

our @EXPORT_OK = qw(is_serverless_mode);

# Cross-language SDK contract: SignalWire::Utils::is_serverless_mode
# mirrors signalwire.utils.is_serverless_mode in the Python reference.
# Returns 1 (true) when running inside any short-lived / event-driven
# environment (i.e. anything other than 'server'); 0 otherwise.
sub is_serverless_mode {
    return SignalWire::Core::LoggingConfig::get_execution_mode() ne 'server'
        ? 1
        : 0;
}

1;
