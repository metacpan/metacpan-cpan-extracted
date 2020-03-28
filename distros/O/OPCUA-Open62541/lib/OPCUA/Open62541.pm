package OPCUA::Open62541;

use 5.026001;
use strict;
use warnings;
require Exporter;
use parent 'Exporter';
use OPCUA::Open62541::Constant;

our $VERSION = '0.006';

our @EXPORT_OK = @OPCUA::Open62541::Constant::EXPORT_OK;
our %EXPORT_TAGS = %OPCUA::Open62541::Constant::EXPORT_TAGS;
$EXPORT_TAGS{all} = [@OPCUA::Open62541::Constant::EXPORT_OK];

require XSLoader;
XSLoader::load('OPCUA::Open62541', $VERSION);

1;

__END__

=pod

=head1 NAME

OPCUA::Open62541 - Perl XS wrapper for open62541 OPC UA library

=head1 SYNOPSIS

  use OPCUA::Open62541;

  my $server = OPCUA::Open62541::Server->new();

  my $client = OPCUA::Open62541::Client->new();

=head1 DESCRIPTION

The open62541 is a library implementing an OPC UA client and server.
This module provides access to the C functionality from Perl programs.

=head2 EXPORT

Refer to OPCUA::Open62541::Constant module about the exported values.

=head2 METHODS

Refer to the open62541 documentation for the semantic of classes
and methods.

=head3 Variant

=over 4

=item $variant = OPCUA::Open62541::Variant->new()

=item $variant->isEmpty()

=item $variant->isScalar()

=item $variant->hasScalarType($data_type)

=item $variant->hasArrayType($data_type)

=item $variant->setScalar($p, $data_type)

=back

=head3 VariableAttributes

This type is converted automatically from a hash.
The key that are recognized are:

=over 4

=item VariableAttributes_value

=back

=head3 Server

=over 4

=item $server = OPCUA::Open62541::Server->new()

=item $server = OPCUA::Open62541::Server->newWithConfig($server_config)

=item $server_config = $server->getConfig()

=item $status_code = $server->run($server, $running)

$running should be TRUE at statup.
When set to FALSE during method invocation, the server stops
magically.

=item $status_code = $server->run_startup($server)

=item $wait_ms = $server->run_iterate($server, $wait_internal)

=item $status_code = $server->run_shutdown($server)

=back

=head3 ServerConfig

=over 4

=item $status_code = $server_config->setDefault()

=item $status_code = $server_config->setMinimal($port, $certificate)

=item $server_config->setCustomHostname($custom_hostname)

=back

=head3 Client

=over 4

=item $client = OPCUA::Open62541::Client->new()

=item $client_config = $client->getConfig()

=item $status_code = $client->connect($url)

=item $status_code = $client->connect_async($endpointUrl, $callback, $userdata)

=item $status_code = $client->run_iterate($timeout)

=item $client_state = $client->getState()

=item $status_code = $client->disconnect()

=back

=head3 ClientConfig

=over 4

=item $status_code = $client_config->setDefault()

=back

=head3 Logger

The Logger can either be a standalone object or use the embedded
logger of a sever config.  In the latter case the life time is
entangled with the config.  It contains Perl callbacks to the log
and clear functions.  The log funtions are exported to Perl.

=over 4

=item $logger = OPCUA::Open62541::Logger->new()

=item $logger->setCallback($log, $context, $clear);

=over 8

=item $log = sub { my ($context, $level, $category, $message) = @_ }

=item $clear = sub { my ($context) = @_ }

=back

=item $logger->logTrace($category, $msg, ...);

=item $logger->logDebug($category, $msg, ...);

=item $logger->logInfo($category, $msg, ...);

=item $logger->logWarning($category, $msg, ...);

=item $logger->logError($category, $msg, ...);

=item $logger->logFatal($category, $msg, ...);

=back

=head1 SEE ALSO

OPC UA library, L<https://open62541.org/>

OPC Foundation, L<https://opcfoundation.org/>

OPCUA::Open62541::Constant

=head1 AUTHORS

Alexander Bluhm E<lt>bluhm@genua.deE<gt>,
Anton Borowka,
Arne Becker,
Marvin Knoblauch E<lt>mknob@genua.deE<gt>,

=head1 CAVEATS

This interface is far from complete.

UA_Int64 and UA_UInt64 are implemented as Perl IV respectively IV.
This only works for Perl that is compiled on a 64 bit platform.
32 bit platforms are currently not supported.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2020 Alexander Bluhm

Copyright (c) 2020 Anton Borowka

Copyright (c) 2020 Arne Becker

Copyright (c) 2020 Marvin Knoblauch

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Thanks to genua GmbH, https://www.genua.de/ for sponsoring this work.

=cut
