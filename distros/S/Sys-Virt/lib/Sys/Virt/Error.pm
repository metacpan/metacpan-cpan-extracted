# -*- perl -*-
#
# Copyright (C) 2006 Red Hat
# Copyright (C) 2006-2007 Daniel P. Berrange
#
# This program is free software; You can redistribute it and/or modify
# it under either:
#
# a) the GNU General Public License as published by the Free
#   Software Foundation; either version 2, or (at your option) any
#   later version,
#
# or
#
# b) the "Artistic License"
#
# The file "LICENSE" distributed along with this file provides full
# details of the terms and conditions of the two licenses.

=pod

=head1 NAME

Sys::Virt::Error - error object for libvirt APIs

=head1 DESCRIPTION

The C<Sys::Virt::Error> class provides an encoding of the
libvirt errors. Instances of this object can be thrown by
pretty much any of the Sys::Virt APIs.

=head1 METHODS

=over 4

=cut

package Sys::Virt::Error;

use strict;
use warnings;
use overload ('""' => 'stringify');

=item $err->stringify

Convert the object into string format suitable for printing on a
console to inform a user of the error.

=cut

sub stringify {
    my $self = shift;

    return "libvirt error code: " . $self->{code} . ", message: " . $self->{message} . ($self->{message} =~ /\n$/ ? "" : "\n");
}

=item my $code = $err->level

Return the raw error level represented by this error. One of the
ERROR LEVEL CONSTANTS

=cut

sub level {
    my $self = shift;
    return $self->{code}
}

=item my $code = $err->code

Return the raw error code represented by this error. One of the
ERROR CODE CONSTANTS

=cut

sub code {
    my $self = shift;
    return $self->{code}
}

=item my $from = $err->domain

Return the error domain raising this error. One of the ERROR
DOMAIN CONSTANTS

=cut

sub domain {
    my $self = shift;
    return $self->{domain}
}

=item my $msg = $err->message

Return an informative message describing the error condition.

=cut

sub message {
    my $self = shift;
    return $self->{message}
}


1;

=back

=head1 CONSTANTS

=head2 ERROR LEVEL CONSTANTS

=over 4

=item Sys::Virt::Error::LEVEL_NONE

Undefined error level

=item Sys::Virt::Error::LEVEL_WARNING

Warning error level

=item Sys::Virt::Error::LEVEL_ERROR

Fatal error level

=back

=head2 ERROR DOMAIN CONSTANTS

The error domain indicates which internal part of libvirt the error
report was raised from.

=over 4

=item Sys::Virt::Error::FROM_CONF

Configuration file handling

=item Sys::Virt::Error::FROM_DOM

Error while operating on a domain

=item Sys::Virt::Error::FROM_DOMAIN

Domain configuration handling

=item Sys::Virt::Error::FROM_LXC

LXC virtualization driver

=item Sys::Virt::Error::FROM_NET

Error while operating on a network

=item Sys::Virt::Error::FROM_NETWORK

Network configuration handling

=item Sys::Virt::Error::FROM_NODEDEV

Node device configuration handling

=item Sys::Virt::Error::FROM_NONE

No specific error domain.

=item Sys::Virt::Error::FROM_OPENVZ

OpenVZ virtualization driver

=item Sys::Virt::Error::FROM_PROXY

Xen proxy virtualization driver

=item Sys::Virt::Error::FROM_QEMU

QEMU virtualization driver

=item Sys::Virt::Error::FROM_REMOTE

Remote client virtualization driver

=item Sys::Virt::Error::FROM_RPC

XML-RPC handling code

=item Sys::Virt::Error::FROM_SECURITY

Security services driver

=item Sys::Virt::Error::FROM_SEXPR

SEXPR parsing code

=item Sys::Virt::Error::FROM_STATS_LINUX

Device statistics code

=item Sys::Virt::Error::FROM_STORAGE

Storage configuration handling

=item Sys::Virt::Error::FROM_TEST

Test virtualization driver

=item Sys::Virt::Error::FROM_UML

UML virtualization driver

=item Sys::Virt::Error::FROM_XEN

Xen hypervisor driver

=item Sys::Virt::Error::FROM_XEND

XenD daemon driver

=item Sys::Virt::Error::FROM_XENSTORE

XenStore driver

=item Sys::Virt::Error::FROM_XENXM

Xen XM configuration file driver

=item Sys::Virt::Error::FROM_XEN_INOTIFY

Xen Inotify events driver

=item Sys::Virt::Error::FROM_XML

Low level XML parser

=item Sys::Virt::Error::FROM_ESX

The VMWare ESX driver

=item Sys::Virt::Error::FROM_INTERFACE

The host network interface driver

=item Sys::Virt::Error::FROM_ONE

The Open Nebula driver. This constant is no longer
used and retained only for backwards compatibility

=item Sys::Virt::Error::FROM_PHYP

The IBM Power Hypervisor driver

=item Sys::Virt::Error::FROM_SECRET

The secret management driver

=item Sys::Virt::Error::FROM_VBOX

The VirtualBox driver

=item Sys::Virt::Error::FROM_AUDIT

The audit driver

=item Sys::Virt::Error::FROM_CPU

The CPU information driver

=item Sys::Virt::Error::FROM_DOMAIN_SNAPSHOT

The domain snapshot driver

=item Sys::Virt::Error::FROM_HOOK

The daemon hook driver

=item Sys::Virt::Error::FROM_NWFILTER

The network filter driver

=item Sys::Virt::Error::FROM_STREAMS

The data streams driver

=item Sys::Virt::Error::FROM_SYSINFO

The system information driver

=item Sys::Virt::Error::FROM_VMWARE

The VMWare driver

=item Sys::Virt::Error::FROM_XENAPI

The XenAPI driver

=item Sys::Virt::Error::FROM_EVENT

The event driver

=item Sys::Virt::Error::FROM_LIBXL

The libxl Xen driver

=item Sys::Virt::Error::FROM_LOCKING

The lock manager drivers

=item Sys::Virt::Error::FROM_HYPERV

The Hyper-V driver

=item Sys::Virt::Error::FROM_CAPABILITIES

The capabilities driver

=item Sys::Virt::Error::FROM_AUTH

The authentication handling code

=item Sys::Virt::Error::FROM_URI

The URI handling code

=item Sys::Virt::Error::FROM_DBUS

The DBus handling code

=item Sys::Virt::Error::FROM_DEVICE

The device handling code

=item Sys::Virt::Error::FROM_SSH

The libSSH2 socket client

=item Sys::Virt::Error::FROM_PARALLELS

The Parallels virtualization driver

=item Sys::Virt::Error::FROM_LOCKSPACE

The lockspace handling code

=item Sys::Virt::Error::FROM_INITCTL

The initctl client code

=item Sys::Virt::Error::FROM_CGROUP

The cgroups code

=item Sys::Virt::Error::FROM_IDENTITY

The identity management code

=item Sys::Virt::Error::FROM_ACCESS

The access control code

=item Sys::Virt::Error::FROM_SYSTEMD

The systemd init service

=item Sys::Virt::Error::FROM_BHYVE

The FreeBSD BHyve driver

=item Sys::Virt::Error::FROM_CRYPTO

The cryptographic helper APIs.

=item Sys::Virt::Error::FROM_FIREWALL

The firewall helper APIs.

=item Sys::Virt::Error::FROM_POLKIT

The polkit authentication / authorization APIs

=item Sys::Virt::Error::FROM_THREAD

The thread helper utils

=item Sys::Virt::Error::FROM_ADMIN

The administrative service

=item Sys::Virt::Error::FROM_LOGGING

The logging service

=item Sys::Virt::Error::FROM_XENXL

The Xen XL driver

=item Sys::Virt::Error::FROM_PERF

The performance events subsystem

=item Sys::Virt::Error::FROM_LIBSSH

The libSSH socket client

=back

=head2 ERROR CODE CONSTANTS

The error codes allow for specific problems to be identified and
handled separately from generic error handling.

=over 4

=item Sys::Virt::Error::ERR_AUTH_FAILED

Authentication falure when connecting to a driver

=item Sys::Virt::Error::ERR_CALL_FAILED

Operation not supported by driver (DEPRECATED & unused)

=item Sys::Virt::Error::ERR_CONF_SYNTAX

Configuration file syntax error

=item Sys::Virt::Error::ERR_DOM_EXIST

The domain already exists

=item Sys::Virt::Error::ERR_DRIVER_FULL

Too many hypervisor drivers have been registered

=item Sys::Virt::Error::ERR_GET_FAILED

HTTP GET command failed talking to XenD

=item Sys::Virt::Error::ERR_GNUTLS_ERROR

GNUTLS encryption error in RPC driver

=item Sys::Virt::Error::ERR_HTTP_ERROR

Unexpected HTTP error code from XenD

=item Sys::Virt::Error::ERR_INTERNAL_ERROR

Generic internal error

=item Sys::Virt::Error::ERR_INVALID_ARG

Invalid argument supplied to function

=item Sys::Virt::Error::ERR_INVALID_CONN

Invalid connection object

=item Sys::Virt::Error::ERR_INVALID_DOMAIN

Invalid domain object

=item Sys::Virt::Error::ERR_INVALID_MAC

Invalid MAC address string

=item Sys::Virt::Error::ERR_INVALID_NETWORK

Invalid network object

=item Sys::Virt::Error::ERR_INVALID_NODE_DEVICE

Invalid node device object

=item Sys::Virt::Error::ERR_INVALID_STORAGE_POOL

Invalid storage pool object

=item Sys::Virt::Error::ERR_INVALID_STORAGE_VOL

Invalid storage vol object

=item Sys::Virt::Error::ERR_NETWORK_EXIST

Network with this name/uuid already exists

=item Sys::Virt::Error::ERR_NO_CONNECT

Unable to connect to requested hypervisor driver

=item Sys::Virt::Error::ERR_NO_DEVICE

Missing device information

=item Sys::Virt::Error::ERR_NO_DOMAIN

No such domain with that name/uuid/id

=item Sys::Virt::Error::ERR_NO_KERNEL

Missing kernel information in domain configuration

=item Sys::Virt::Error::ERR_NO_MEMORY

Missing memory information in domain configuration

=item Sys::Virt::Error::ERR_NO_NAME

Missing name in object configuration

=item Sys::Virt::Error::ERR_NO_NETWORK

No such network with that name/uuid

=item Sys::Virt::Error::ERR_NO_NODE_DEVICE

No such node device with that name

=item Sys::Virt::Error::ERR_NO_OS

Missing OS information in domain configuration

=item Sys::Virt::Error::ERR_NO_ROOT

Missing root device information in domain configuration

=item Sys::Virt::Error::ERR_NO_SECURITY_MODEL

Missing security model information in domain configuratio

=item Sys::Virt::Error::ERR_NO_SOURCE

Missing source device information in domain configuration

=item Sys::Virt::Error::ERR_NO_STORAGE_POOL

No such storage pool with that name/uuid

=item Sys::Virt::Error::ERR_NO_STORAGE_VOL

No such storage volume with that name/path/key

=item Sys::Virt::Error::ERR_NO_SUPPORT

This operation is not supported by the active driver

=item Sys::Virt::Error::ERR_NO_TARGET

Missing target device information in domain configuration

=item Sys::Virt::Error::ERR_NO_XEN

Unable to connect to Xen hypervisor

=item Sys::Virt::Error::ERR_NO_XENSTORE

Unable to connect to XenStorage daemon

=item Sys::Virt::Error::ERR_OK

No error code. This should never be see

=item Sys::Virt::Error::ERR_OPEN_FAILED

Unable to open a configuration file

=item Sys::Virt::Error::ERR_OPERATIONED_DENIED

The operation is forbidden for the current connection

=item Sys::Virt::Error::ERR_OPERATION_FAILED

The operation failed to complete

=item Sys::Virt::Error::ERR_OS_TYPE

Missing/incorrect OS type in domain configuration

=item Sys::Virt::Error::ERR_PARSE_FAILED

Failed to parse configuration file

=item Sys::Virt::Error::ERR_POST_FAILED

HTTP POST failure talking to XenD

=item Sys::Virt::Error::ERR_READ_FAILED

Unable to read from configuration file

=item Sys::Virt::Error::ERR_RPC

Generic RPC error talking to XenD

=item Sys::Virt::Error::ERR_SEXPR_SERIAL

Failed to generic SEXPR for XenD

=item Sys::Virt::Error::ERR_SYSTEM_ERROR

Generic operating system error

=item Sys::Virt::Error::ERR_UNKNOWN_HOST

Unknown hostname

=item Sys::Virt::Error::ERR_WRITE_FAILED

Failed to write to configuration file

=item Sys::Virt::Error::ERR_XEN_CALL

Failure while talking to Xen hypervisor

=item Sys::Virt::Error::ERR_XML_DETAIL

Detailed XML parsing error

=item Sys::Virt::Error::ERR_XML_ERROR

Generic XML parsing error

=item Sys::Virt::Error::WAR_NO_NETWORK

Warning that no network driver is activated

=item Sys::Virt::Error::WAR_NO_NODE

Warning that no node device driver is activated

=item Sys::Virt::Error::WAR_NO_STORAGE

Warning that no storage driver is activated

=item Sys::Virt::Error::ERR_INVALID_INTERFACE

Invalid network interface object

=item Sys::Virt::Error::ERR_NO_INTERFACE

No interface with the matching name / mac address

=item Sys::Virt::Error::ERR_OPERATION_INVALID

The requested operation is not valid for the current object state

=item Sys::Virt::Error::WAR_NO_INTERFACE

The network interface driver is not available

=item Sys::Virt::Error::ERR_MULTIPLE_INTERFACES

There are multiple interfaces with the requested MAC address

=item Sys::Virt::Error::ERR_BUILD_FIREWALL

The firwall could not be constructed

=item Sys::Virt::Error::WAR_NO_NWFILTER

The network filter driver could not be activated

=item Sys::Virt::Error::ERR_NO_NWFILTER

There is no network filter driver available

=item Sys::Virt::Error::ERR_INVALID_NWFILTER

The network filter object was invalid

=item Sys::Virt::Error::WAR_NO_SECRET

There secret management driver is not available

=item Sys::Virt::Error::ERR_NO_SECRET

No secret with the matching uuid / usage ID

=item Sys::Virt::Error::ERR_INVALID_SECRET

Invalid secret object

=item Sys::Virt::Error::ERR_CONFIG_UNSUPPORTED

The requested XML configuration is not supported by the hypervisor

=item Sys::Virt::Error::ERR_OPERATION_TIMEOUT

The operation could not be completed in a satisfactory time

=item Sys::Virt::Error::ERR_MIGRATE_PERSIST_FAILED

Unable to persistent the domain configuration after migration
successfully completed

=item Sys::Virt::Error::ERR_HOOK_SCRIPT_FAILED

Execution of a daemon hook script failed

=item Sys::Virt::Error::ERR_INVALID_DOMAIN_SNAPSHOT

The domain snapshot object pointer was invalid

=item Sys::Virt::Error::ERR_NO_DOMAIN_SNAPSHOT

No matching domain snapshot was found

=item Sys::Virt::Error::ERR_INVALID_STREAM

The stream object pointer was invalid

=item Sys::Virt::Error::ERR_ARGUMENT_UNSUPPORTED

The argument value was not supported by the driver

=item Sys::Virt::Error::ERR_STORAGE_POOL_BUILT

The storage pool has already been built

=item Sys::Virt::Error::ERR_STORAGE_PROBE_FAILED

Probing the storage pool failed

=item Sys::Virt::Error::ERR_SNAPSHOT_REVERT_RISKY

Reverting the snapshot could cause data loss

=item Sys::Virt::Error::ERR_OPERATION_ABORTED

The asynchronous operation was aborted at admin request

=item Sys::Virt::Error::ERR_AUTH_CANCELLED

The user cancelled the authentication process

=item Sys::Virt::Error::ERR_NO_DOMAIN_METADATA

The requested metadata does not exist

=item Sys::Virt::Error::ERR_MIGRATE_UNSAFE

The migration operation would be unsafe to perform

=item Sys::Virt::Error::ERR_OVERFLOW

The calculation would overflow

=item Sys::Virt::Error::ERR_BLOCK_COPY_ACTIVE

Action prevented by block copy job

=item Sys::Virt::Error::ERR_AGENT_UNRESPONSIVE

The guest agent is not responding

=item Sys::Virt::Error::ERR_OPERATION_UNSUPPORTED

The operation is not supported on this host

=item Sys::Virt::Error::ERR_SSH

The SSH operation failed

=item Sys::Virt::Error::ERR_RESOURCE_BUSY

The resource requested is already in use

=item Sys::Virt::Error::ERR_ACCESS_DENIED

Not authorized to perform the operation

=item Sys::Virt::Error::ERR_DBUS_SERVICE

An error from a DBus service API

=item Sys::Virt::Error::ERR_STORAGE_VOL_EXIST

The storage volume already exists

=item Sys::Virt::Error::ERR_CPU_INCOMPATIBLE

The CPUs are not compatible

=item Sys::Virt::Error::ERR_INVALID_SCHEMA

The XML document does not comply with the XML schema

=item Sys::Virt::Error::ERR_MIGRATE_FINISH_OK

Migration finished but expected to return NULL domain.

=item Sys::Virt::Error::ERR_AUTH_UNAVAILABLE

Authentication services were not available

=item Sys::Virt::Error::ERR_NO_SERVER

Libvirt server was not found

=item Sys::Virt::Error::ERR_NO_CLIENT

Libvirt client was not found

=item Sys::Virt::Error::ERR_AGENT_UNSYNCED

Libvirt guest agent replies with wrong id to guest-sync command

=item Sys::Virt::Error::ERR_LIBSSH

The libSSH operation failed

=back

=head1 AUTHORS

Daniel P. Berrange <berrange@redhat.com>


=head1 COPYRIGHT

Copyright (C) 2006 Red Hat
Copyright (C) 2006-2007 Daniel P. Berrange

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of either the GNU General Public License as published
by the Free Software Foundation (either version 2 of the License, or at
your option any later version), or, the Artistic License, as specified
in the Perl README file.

=head1 SEE ALSO

L<Sys::Virt::Domain>, L<Sys::Virt>, C<http://libvirt.org>

=cut
