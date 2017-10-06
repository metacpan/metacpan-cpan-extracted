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

Sys::Virt - Represent and manage a libvirt hypervisor connection

=head1 SYNOPSIS

  my $vmm = Sys::Virt->new(uri => $uri);

  my @domains = $vmm->list_domains();

  foreach my $dom (@domains) {
    print "Domain ", $dom->get_id, " ", $dom->get_name, "\n";
  }

=head1 DESCRIPTION

The Sys::Virt module provides a Perl XS binding to the libvirt
virtual machine management APIs. This allows machines running
within arbitrary virtualization containers to be managed with
a consistent API.

=head1 ERROR HANDLING

Any operations in the Sys::Virt API which have failure scenarios
will result in an instance of the L<Sys::Virt::Error> module being
thrown. To catch these errors, simply wrap the method in an eval
block:

  eval { my $vmm = Sys::Virt->new(uri => $uri); };
  if ($@) {
    print STDERR "Unable to open connection to $addr" . $@->message . "\n";
  }

For details of the information contained in the error objects,
consult the L<Sys::Virt::Error> manual page.

=head1 METHODS

=over 4

=cut

package Sys::Virt;

use strict;
use warnings;

use Sys::Virt::Error;
use Sys::Virt::Domain;
use Sys::Virt::Network;
use Sys::Virt::StoragePool;
use Sys::Virt::StorageVol;
use Sys::Virt::NodeDevice;
use Sys::Virt::Interface;
use Sys::Virt::Secret;
use Sys::Virt::NWFilter;
use Sys::Virt::DomainSnapshot;
use Sys::Virt::Stream;

our $VERSION = '3.8.0';
require XSLoader;
XSLoader::load('Sys::Virt', $VERSION);

=item my $vmm = Sys::Virt->new(uri => $uri, readonly => $ro, flags => $flags);

Attach to the virtualization host identified by C<uri>. The
C<uri> parameter may be omitted, in which case the default connection made
will be to the local Xen hypervisor. Some example URIs include:

=over 4

=item xen:///

Xen on the local machine

=item test:///default

Dummy "in memory" driver for test suites

=item qemu:///system

System-wide driver for QEMU / KVM virtualization

=item qemu:///session

Per-user driver for QEMU virtualization

=item qemu+tls://somehost/system

System-wide QEMU driver on C<somehost> using TLS security

=item xen+tcp://somehost/

Xen driver on C<somehost> using TCP / SASL security

=back

For further details consult C<http://libvirt.org/uri.html>

If the optional C<readonly> parameter is supplied, then an unprivileged
connection to the VMM will be attempted. If it is not supplied, then it
defaults to making a fully privileged connection to the VMM. If the
calling application is not running as root, it may be necessary to
provide authentication callbacks.

If the optional C<auth> parameter is set to a non-zero value,
authentication will be enabled during connection, using the
default set of credential gathering callbacks. The default
callbacks prompt for credentials on the console, so are not
suitable for graphical applications. For such apps a custom
implementation should be supplied. The C<credlist> parameter
should be an array reference listing the set of credential
types that will be supported. The credential constants in
this module can be used as values in this list. The C<callback>
parameter should be a subroutine reference containing the
code necessary to gather the credentials. When invoked it
will be supplied with a single parameter, a array reference
of requested credentials. The elements of the array are
hash references, with keys C<type> giving the type of
credential, C<prompt> giving a user descriptive user
prompt, C<challenge> giving name of the credential
required. The answer should be collected from the user, and
returned by setting the C<result> key. This key may already
be set with a default result if applicable

As a simple example returning hardcoded credentials

    my $uri  = "qemu+tcp://192.168.122.1/system";
    my $username = "test";
    my $password = "123456";

    my $con = Sys::Virt->new(uri => $uri,
                             auth => 1,
                             credlist => [
                               Sys::Virt::CRED_AUTHNAME,
                               Sys::Virt::CRED_PASSPHRASE,
                             ],
                             callback =>
         sub {
               my $creds = shift;

               foreach my $cred (@{$creds}) {
                  if ($cred->{type} == Sys::Virt::CRED_AUTHNAME) {
                      $cred->{result} = $username;
                  }
                  if ($cred->{type} == Sys::Virt::CRED_PASSPHRASE) {
                      $cred->{result} = $password;
                  }
               }
               return 0;
         });


For backwards compatibility with earlier releases, the C<address>
parameter is accepted as a synonym for the C<uri> parameter. The
use of C<uri> is recommended for all newly written code.

=cut

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my %params = @_;

    my $uri = exists $params{address} ? $params{address} : exists $params{uri} ? $params{uri} : undef;
    my $flags = exists $params{flags} ? $params{flags} : 0;
    if ($params{readonly}) {
	$flags |= &Sys::Virt::CONNECT_RO;
    }
    my $auth = exists $params{auth} ? $params{auth} : 0;

    my $authcb = exists $params{callback} ? $params{callback} : undef;
    my $credlist = exists $params{credlist} ? $params{credlist} : undef;

    my $self;

    if ($auth) {
	$self = Sys::Virt::_open_auth($uri, $credlist, $authcb, $flags);
    } else {
	$self = Sys::Virt::_open($uri, $flags);
    }

    bless $self, $class;

    return $self;
}


=item my $st = $vmm->new_stream($flags)

Create a new stream, with the given flags

=cut

sub new_stream {
    my $self = shift;
    my $flags = shift || 0;

    return Sys::Virt::Stream->_new(connection => $self, flags => $flags);
}


=item my $dom = $vmm->create_domain($xml, $flags);

Create a new domain based on the XML description passed into the C<$xml>
parameter. The returned object is an instance of the L<Sys::Virt::Domain>
class. This method is not available with unprivileged connections to
the VMM. The C<$flags> parameter accepts one of the DOMAIN CREATION
constants documented in L<Sys::Virt::Domain>, and defaults to 0 if omitted.

=cut

sub create_domain {
    my $self = shift;
    my $xml = shift;
    my $flags = shift || 0;

    return Sys::Virt::Domain->_new(connection => $self, xml => $xml, flags => $flags);
}

=item my $dom = $vmm->create_domain_with_files($xml, $fds, $flags);

Create a new domain based on the XML description passed into the C<$xml>
parameter. The returned object is an instance of the L<Sys::Virt::Domain>
class. This method is not available with unprivileged connections to
the VMM. The C<$fds> parameter is an array of UNIX file descriptors
which will be passed to the init process of the container. This is
only supported with container based virtualization. The C<$flags>
parameter accepts one of the DOMAIN CREATION constants documented
in L<Sys::Virt::Domain>, and defaults to 0 if omitted.

=cut

sub create_domain_with_files {
    my $self = shift;
    my $xml = shift;
    my $fds = shift;
    my $flags = shift || 0;

    return Sys::Virt::Domain->_new(connection => $self, xml => $xml,
				   fds => $fds, flags => $flags);
}

=item my $dom = $vmm->define_domain($xml, $flags=0);

Defines, but does not start, a new domain based on the XML description
passed into the C<$xml> parameter. The returned object is an instance
of the L<Sys::Virt::Domain> class. This method is not available with
unprivileged connections to the VMM. The defined domain can be later started
by calling the C<create> method on the returned C<Sys::Virt::Domain>
object.

=cut

sub define_domain {
    my $self = shift;
    my $xml = shift;
    my $flags = shift || 0;

    return Sys::Virt::Domain->_new(connection => $self, xml => $xml, nocreate => 1, flags => $flags);
}

=item my $dom = $vmm->create_network($xml);

Create a new network based on the XML description passed into the C<$xml>
parameter. The returned object is an instance of the L<Sys::Virt::Network>
class. This method is not available with unprivileged connections to
the VMM.

=cut

sub create_network {
    my $self = shift;
    my $xml = shift;

    return Sys::Virt::Network->_new(connection => $self, xml => $xml);
}

=item my $dom = $vmm->define_network($xml);

Defines, but does not start, a new network based on the XML description
passed into the C<$xml> parameter. The returned object is an instance
of the L<Sys::Virt::Network> class. This method is not available with
unprivileged connections to the VMM. The defined network can be later started
by calling the C<create> method on the returned C<Sys::Virt::Network>
object.

=cut

sub define_network {
    my $self = shift;
    my $xml = shift;

    return Sys::Virt::Network->_new(connection => $self, xml => $xml, nocreate => 1);
}

=item my $dom = $vmm->create_storage_pool($xml);

Create a new storage pool based on the XML description passed into the C<$xml>
parameter. The returned object is an instance of the L<Sys::Virt::StoragePool>
class. This method is not available with unprivileged connections to
the VMM.

=cut

sub create_storage_pool {
    my $self = shift;
    my $xml = shift;

    return Sys::Virt::StoragePool->_new(connection => $self, xml => $xml);
}

=item my $dom = $vmm->define_storage_pool($xml);

Defines, but does not start, a new storage pol based on the XML description
passed into the C<$xml> parameter. The returned object is an instance
of the L<Sys::Virt::StoragePool> class. This method is not available with
unprivileged connections to the VMM. The defined pool can be later started
by calling the C<create> method on the returned C<Sys::Virt::StoragePool>
object.

=cut

sub define_storage_pool {
    my $self = shift;
    my $xml = shift;

    return Sys::Virt::StoragePool->_new(connection => $self, xml => $xml, nocreate => 1);
}

=item my $dom = $vmm->create_interface($xml);

Create a new interface based on the XML description passed into the C<$xml>
parameter. The returned object is an instance of the L<Sys::Virt::Interface>
class. This method is not available with unprivileged connections to
the VMM.

=cut

sub create_interface {
    my $self = shift;
    my $xml = shift;

    return Sys::Virt::Interface->_new(connection => $self, xml => $xml);
}

=item my $dom = $vmm->define_interface($xml);

Defines, but does not start, a new interface based on the XML description
passed into the C<$xml> parameter. The returned object is an instance
of the L<Sys::Virt::Interface> class. This method is not available with
unprivileged connections to the VMM. The defined interface can be later started
by calling the C<create> method on the returned C<Sys::Virt::Interface>
object.

=cut

sub define_interface {
    my $self = shift;
    my $xml = shift;

    return Sys::Virt::Interface->_new(connection => $self, xml => $xml, nocreate => 1);
}

=item my $dom = $vmm->create_node_device($xml);

Create a new virtual node device based on the XML description passed into the
C<$xml> parameter. The returned object is an instance of the L<Sys::Virt::NodeDevice>
class. This method is not available with unprivileged connections to
the VMM.

=cut

sub create_node_device {
    my $self = shift;
    my $xml = shift;

    return Sys::Virt::NodeDevice->_new(connection => $self, xml => $xml);
}


=item my @doms = $vmm->list_domains()

Return a list of all running domains currently known to the VMM. The elements
in the returned list are instances of the L<Sys::Virt::Domain> class. This
method requires O(n) RPC calls, so the C<list_all_domains> method is
recommended as a more efficient alternative.

=cut

sub list_domains {
    my $self = shift;

    my $nids = $self->num_of_domains();
    my @ids = $self->list_domain_ids($nids);
    my @domains;
    foreach my $id (@ids) {
	eval {
	    push @domains, Sys::Virt::Domain->_new(connection => $self, id => $id);
	};
	if ($@) {
	    # nada - domain went away before we could look it up
	};
    }
    return @domains;
}

=item my $nids = $vmm->num_of_domains()

Return the number of running domains known to the VMM. This can be
used as the C<maxids> parameter to C<list_domain_ids>.

=item my @domIDs = $vmm->list_domain_ids($maxids)

Return a list of all domain IDs currently known to the VMM. The IDs can
be used with the C<get_domain_by_id> method.

=item my @doms = $vmm->list_defined_domains()

Return a list of all domains defined, but not currently running, on the
VMM. The elements in the returned list are instances of the
L<Sys::Virt::Domain> class. This method requires O(n) RPC calls, so the
C<list_all_domains> method is recommended as a more efficient alternative.

=cut

sub list_defined_domains {
    my $self = shift;

    my $nnames = $self->num_of_defined_domains();
    my @names = $self->list_defined_domain_names($nnames);

    my @domains;
    foreach my $name (@names) {
	eval {
	    push @domains, Sys::Virt::Domain->_new(connection => $self, name => $name);
	};
	if ($@) {
	    # nada - domain went away before we could look it up
	};
    }
    return @domains;
}

=item my $nnames = $vmm->num_of_defined_domains()

Return the number of running domains known to the VMM. This can be
used as the C<maxnames> parameter to C<list_defined_domain_names>.

=item my @names = $vmm->list_defined_domain_names($maxnames)

Return a list of names of all domains defined, but not currently running, on
the VMM. The names can be used with the C<get_domain_by_name> method.

=item my @doms = $vmm->list_all_domains($flags)

Return a list of all domains currently known to the VMM, whether
running or shutoff. The elements in the returned list are instances
of the L<Sys::Virt::Domain> class. The C<$flags> parameter can be
used to filter the list of returned domains.

=item my @nets = $vmm->list_networks()

Return a list of all networks currently known to the VMM. The elements
in the returned list are instances of the L<Sys::Virt::Network> class.
This method requires O(n) RPC calls, so the C<list_all_networks> method
is recommended as a more efficient alternative.

=cut

sub list_networks {
    my $self = shift;

    my $nnames = $self->num_of_networks();
    my @names = $self->list_network_names($nnames);

    my @networks;
    foreach my $name (@names) {
	eval {
	    push @networks, Sys::Virt::Network->_new(connection => $self, name => $name);
	};
	if ($@) {
	    # nada - network went away before we could look it up
	};
    }
    return @networks;
}

=item my $nnames = $vmm->num_of_networks()

Return the number of running networks known to the VMM. This can be
used as the C<maxids> parameter to C<list_network_ids>.

=item my @netNames = $vmm->list_network_names($maxnames)

Return a list of all network names currently known to the VMM. The names can
be used with the C<get_network_by_name> method.

=item my @nets = $vmm->list_defined_networks()

Return a list of all networks defined, but not currently running, on the
VMM. The elements in the returned list are instances of the
L<Sys::Virt::Network> class. This method requires O(n) RPC calls, so the
C<list_all_networks> method is recommended as a more efficient alternative.

=cut

sub list_defined_networks {
    my $self = shift;

    my $nnames = $self->num_of_defined_networks();
    my @names = $self->list_defined_network_names($nnames);

    my @networks;
    foreach my $name (@names) {
	eval {
	    push @networks, Sys::Virt::Network->_new(connection => $self, name => $name);
	};
	if ($@) {
	    # nada - network went away before we could look it up
	};
    }
    return @networks;
}

=item my $nnamess = $vmm->num_of_defined_networks()

Return the number of running networks known to the host. This can be
used as the C<maxnames> parameter to C<list_defined_network_names>.

=item my @names = $vmm->list_defined_network_names($maxnames)

Return a list of names of all networks defined, but not currently running, on
the host. The names can be used with the C<get_network_by_name> method.

=item my @nets = $vmm->list_all_networks($flags)

Return a list of all networks currently known to the VMM, whether
running or shutoff. The elements in the returned list are instances
of the L<Sys::Virt::Network> class. The C<$flags> parameter can be
used to filter the list of returned networks.

=item my @pools = $vmm->list_storage_pools()

Return a list of all storage pools currently known to the host. The elements
in the returned list are instances of the L<Sys::Virt::StoragePool> class.
This method requires O(n) RPC calls, so the C<list_all_storage_pools> method
is recommended as a more efficient alternative.

=cut

sub list_storage_pools {
    my $self = shift;

    my $nnames = $self->num_of_storage_pools();
    my @names = $self->list_storage_pool_names($nnames);

    my @pools;
    foreach my $name (@names) {
	eval {
	    push @pools, Sys::Virt::StoragePool->_new(connection => $self, name => $name);
	};
	if ($@) {
	    # nada - storage pool went away before we could look it up
	};
    }
    return @pools;
}

=item my $nnames = $vmm->num_of_storage_pools()

Return the number of running storage pools known to the VMM. This can be
used as the C<maxids> parameter to C<list_storage_pool_names>.

=item my @poolNames = $vmm->list_storage_pool_names($maxnames)

Return a list of all storage pool names currently known to the VMM. The IDs can
be used with the C<get_network_by_id> method.

=item my @pools = $vmm->list_defined_storage_pools()

Return a list of all storage pools defined, but not currently running, on the
host. The elements in the returned list are instances of the
L<Sys::Virt::StoragePool> class. This method requires O(n) RPC calls, so the
C<list_all_storage_pools> method is recommended as a more efficient alternative.

=cut

sub list_defined_storage_pools {
    my $self = shift;

    my $nnames = $self->num_of_defined_storage_pools();
    my @names = $self->list_defined_storage_pool_names($nnames);

    my @pools;
    foreach my $name (@names) {
	eval {
	    push @pools, Sys::Virt::StoragePool->_new(connection => $self, name => $name);
	};
	if ($@) {
	    # nada - storage pool went away before we could look it up
	};
    }
    return @pools;
}

=item my $nnames = $vmm->num_of_defined_storage_pools()

Return the number of running networks known to the host. This can be
used as the C<maxnames> parameter to C<list_defined_storage_pool_names>.

=item my @names = $vmm->list_defined_storage_pool_names($maxnames)

Return a list of names of all storage pools defined, but not currently running, on
the host. The names can be used with the C<get_storage_pool_by_name> method.

=item my @pools = $vmm->list_all_storage_pools($flags)

Return a list of all storage pools currently known to the VMM, whether
running or shutoff. The elements in the returned list are instances
of the L<Sys::Virt::StoragePool> class. The C<$flags> parameter can be
used to filter the list of returned pools.

=item my @devs = $vmm->list_node_devices($capability)

Return a list of all devices currently known to the host OS. The elements
in the returned list are instances of the L<Sys::Virt::NodeDevice> class.
The optional C<capability> parameter allows the list to be restricted to
only devices with a particular capability type. This method requires O(n)
RPC calls, so the C<list_all_node_devices> method is recommended as a
more efficient alternative.

=cut

sub list_node_devices {
    my $self = shift;
    my $cap = shift;

    my $nnames = $self->num_of_node_devices($cap);
    my @names = $self->list_node_device_names($cap, $nnames);

    my @devs;
    foreach my $name (@names) {
	eval {
	    push @devs, Sys::Virt::NodeDevice->_new(connection => $self, name => $name);
	};
	if ($@) {
	    # nada - device went away before we could look it up
	};
    }
    return @devs;
}

=item my $nnames = $vmm->num_of_node_devices($capability[, $flags])

Return the number of host devices known to the VMM. This can be
used as the C<maxids> parameter to C<list_node_device_names>.
The C<capability> parameter allows the list to be restricted to
only devices with a particular capability type, and should be left
as C<undef> if the full list is required. The optional <flags>
parameter is currently unused and defaults to 0 if omitted.

=item my @netNames = $vmm->list_node_device_names($capability, $maxnames[, $flags])

Return a list of all host device names currently known to the VMM. The names can
be used with the C<get_node_device_by_name> method.
The C<capability> parameter allows the list to be restricted to
only devices with a particular capability type, and should be left
as C<undef> if the full list is required. The optional <flags>
parameter is currently unused and defaults to 0 if omitted.

=item my @devs = $vmm->list_all_node_devices($flags)

Return a list of all node devices currently known to the VMM. The
elements in the returned list are instances of the
L<Sys::Virt::NodeDevice> class. The C<$flags> parameter can be
used to filter the list of returned devices.

=item my @ifaces = $vmm->list_interfaces()

Return a list of all network interfaces currently known to the VMM. The elements
in the returned list are instances of the L<Sys::Virt::Interface> class.
This method requires O(n) RPC calls, so the C<list_all_interfaces> method is
recommended as a more efficient alternative.

=cut

sub list_interfaces {
    my $self = shift;

    my $nnames = $self->num_of_interfaces();
    my @names = $self->list_interface_names($nnames);

    my @interfaces;
    foreach my $name (@names) {
	eval {
	    push @interfaces, Sys::Virt::Interface->_new(connection => $self, name => $name);
	};
	if ($@) {
	    # nada - interface went away before we could look it up
	};
    }
    return @interfaces;
}

=item my $nnames = $vmm->num_of_interfaces()

Return the number of running interfaces known to the VMM. This can be
used as the C<maxnames> parameter to C<list_interface_names>.

=item my @names = $vmm->list_interface_names($maxnames)

Return a list of all interface names currently known to the VMM. The names can
be used with the C<get_interface_by_name> method.

=item my @ifaces = $vmm->list_defined_interfaces()

Return a list of all network interfaces currently known to the VMM. The elements
in the returned list are instances of the L<Sys::Virt::Interface> class.
This method requires O(n) RPC calls, so the C<list_all_interfaces> method is
recommended as a more efficient alternative.

=cut

sub list_defined_interfaces {
    my $self = shift;

    my $nnames = $self->num_of_defined_interfaces();
    my @names = $self->list_defined_interface_names($nnames);

    my @interfaces;
    foreach my $name (@names) {
	eval {
	    push @interfaces, Sys::Virt::Interface->_new(connection => $self, name => $name);
	};
	if ($@) {
	    # nada - interface went away before we could look it up
	};
    }
    return @interfaces;
}

=item my $nnames = $vmm->num_of_defined_interfaces()

Return the number of inactive interfaces known to the VMM. This can be
used as the C<maxnames> parameter to C<list_defined_interface_names>.

=item my @names = $vmm->list_defined_interface_names($maxnames)

Return a list of inactive interface names currently known to the VMM. The names can
be used with the C<get_interface_by_name> method.

=item my @ifaces = $vmm->list_all_interfaces($flags)

Return a list of all interfaces currently known to the VMM, whether
running or shutoff. The elements in the returned list are instances
of the L<Sys::Virt::Interface> class. The C<$flags> parameter can be
used to filter the list of returned interfaces.

=item my @ifaces = $vmm->list_secrets()

Return a list of all secrets currently known to the VMM. The elements
in the returned list are instances of the L<Sys::Virt::Secret> class.
This method requires O(n) RPC calls, so the C<list_all_secrets> method
is recommended as a more efficient alternative.

=cut

sub list_secrets {
    my $self = shift;

    my $nuuids = $self->num_of_secrets();
    my @uuids = $self->list_secret_uuids($nuuids);

    my @secrets;
    foreach my $uuid (@uuids) {
	eval {
	    push @secrets, Sys::Virt::Secret->_new(connection => $self, uuid => $uuid);
	};
	if ($@) {
	    # nada - secret went away before we could look it up
	};
    }
    return @secrets;
}

=item my $nuuids = $vmm->num_of_secrets()

Return the number of secrets known to the VMM. This can be
used as the C<maxuuids> parameter to C<list_secrets>.

=item my @uuids = $vmm->list_secret_uuids($maxuuids)

Return a list of all secret uuids currently known to the VMM. The uuids can
be used with the C<get_secret_by_uuid> method.

=item my @secrets = $vmm->list_all_secrets($flags)

Return a list of all secrets currently known to the VMM. The elements
in the returned list are instances of the L<Sys::Virt::Network> class.
The C<$flags> parameter can be used to filter the list of returned
secrets.

=item my @nets = $vmm->list_nwfilters()

Return a list of all nwfilters currently known to the VMM. The elements
in the returned list are instances of the L<Sys::Virt::NWFilter> class.
This method requires O(n) RPC calls, so the C<list_all_nwfilters> method
is recommended as a more efficient alternative.

=cut

sub list_nwfilters {
    my $self = shift;

    my $nnames = $self->num_of_nwfilters();
    my @names = $self->list_nwfilter_names($nnames);

    my @nwfilters;
    foreach my $name (@names) {
	eval {
	    push @nwfilters, Sys::Virt::NWFilter->_new(connection => $self, name => $name);
	};
	if ($@) {
	    # nada - nwfilter went away before we could look it up
	};
    }
    return @nwfilters;
}

=item my $nnames = $vmm->num_of_nwfilters()

Return the number of running nwfilters known to the VMM. This can be
used as the C<maxids> parameter to C<list_nwfilter_names>.

=item my @filterNames = $vmm->list_nwfilter_names($maxnames)

Return a list of all nwfilter names currently known to the VMM. The names can
be used with the C<get_nwfilter_by_name> method.

=item my @nwfilters = $vmm->list_all_nwfilters($flags)

Return a list of all nwfilters currently known to the VMM. The elements
in the returned list are instances of the L<Sys::Virt::NWFilter> class.
The C<$flags> parameter is currently unused and defaults to zero.

=item $vmm->define_save_image_xml($file, $dxml, $flags=0)

Update the XML associated with a virtual machine's save image. The C<$file>
parameter is the fully qualified path to the save image XML, while C<$dxml>
is the new XML document to write. The C<$flags> parameter is currently
unused and defaults to zero.

=item $xml = $vmm->get_save_image_xml_description($file, $flags=1)

Retrieve the current XML configuration associated with the virtual
machine's save image identified by C<$file>. The C<$flags> parameter is currently
unused and defaults to zero.

=item my $dom = $vmm->get_domain_by_name($name)

Return the domain with a name of C<$name>. The returned object is
an instance of the L<Sys::Virt::Domain> class.

=cut

sub get_domain_by_name {
    my $self = shift;
    my $name = shift;

    return Sys::Virt::Domain->_new(connection => $self, name => $name);
}



=item my $dom = $vmm->get_domain_by_id($id)

Return the domain with a local id of C<$id>. The returned object is
an instance of the L<Sys::Virt::Domain> class.

=cut

sub get_domain_by_id {
    my $self = shift;
    my $id = shift;

    return Sys::Virt::Domain->_new(connection => $self, id => $id);
}



=item my $dom = $vmm->get_domain_by_uuid($uuid)

Return the domain with a globally unique id of C<$uuid>. The returned object is
an instance of the L<Sys::Virt::Domain> class.

=cut

sub get_domain_by_uuid {
    my $self = shift;
    my $uuid = shift;

    return Sys::Virt::Domain->_new(connection => $self, uuid => $uuid);
}

=item my $net = $vmm->get_network_by_name($name)

Return the network with a name of C<$name>. The returned object is
an instance of the L<Sys::Virt::Network> class.

=cut

sub get_network_by_name {
    my $self = shift;
    my $name = shift;

    return Sys::Virt::Network->_new(connection => $self, name => $name);
}


=item my $net = $vmm->get_network_by_uuid($uuid)

Return the network with a globally unique id of C<$uuid>. The returned object is
an instance of the L<Sys::Virt::Network> class.

=cut

sub get_network_by_uuid {
    my $self = shift;
    my $uuid = shift;

    return Sys::Virt::Network->_new(connection => $self, uuid => $uuid);
}

=item my $pool = $vmm->get_storage_pool_by_name($name)

Return the storage pool with a name of C<$name>. The returned object is
an instance of the L<Sys::Virt::StoragePool> class.

=cut

sub get_storage_pool_by_name {
    my $self = shift;
    my $name = shift;

    return Sys::Virt::StoragePool->_new(connection => $self, name => $name);
}


=item my $pool = $vmm->get_storage_pool_by_uuid($uuid)

Return the storage pool with a globally unique id of C<$uuid>. The returned object is
an instance of the L<Sys::Virt::StoragePool> class.

=cut

sub get_storage_pool_by_uuid {
    my $self = shift;
    my $uuid = shift;

    return Sys::Virt::StoragePool->_new(connection => $self, uuid => $uuid);
}


=item my $pool = $vmm->get_storage_pool_by_volume($vol)

Return the storage pool with a storage volume C<$vol>. The C<$vol> parameter
must be an instance of the L<Sys::Virt::StorageVol> class. The returned object is
an instance of the L<Sys::Virt::StoragePool> class.

=cut

sub get_storage_pool_by_volume {
    my $self = shift;
    my $volume = shift;

    return Sys::Virt::StoragePool->_new(connection => $self, volume => $volume);
}


=item my $vol = $vmm->get_storage_volume_by_path($path)

Return the storage volume with a location of C<$path>. The returned object is
an instance of the L<Sys::Virt::StorageVol> class.

=cut

sub get_storage_volume_by_path {
    my $self = shift;
    my $path = shift;

    return Sys::Virt::StorageVol->_new(connection => $self, path => $path);
}


=item my $vol = $vmm->get_storage_volume_by_key($key)

Return the storage volume with a globally unique id of C<$key>. The returned object is
an instance of the L<Sys::Virt::StorageVol> class.

=cut

sub get_storage_volume_by_key {
    my $self = shift;
    my $key = shift;

    return Sys::Virt::StorageVol->_new(connection => $self, key => $key);
}

=item my $dev = $vmm->get_node_device_by_name($name)

Return the node device with a name of C<$name>. The returned object is
an instance of the L<Sys::Virt::NodeDevice> class.

=cut

sub get_node_device_by_name {
    my $self = shift;
    my $name = shift;

    return Sys::Virt::NodeDevice->_new(connection => $self, name => $name);
}


=item my $dev = $vmm->get_node_device_scsihost_by_wwn($wwnn, $wwpn, $flags=0)

Return the node device which is a SCSI host identified by C<$wwnn> and C<$wwpn>.
The C<$flags> parameter is unused and defaults to zero.  The returned object is
an instance of the L<Sys::Virt::NodeDevice> class.

=cut

sub get_node_device_scsihost_by_wwn {
    my $self = shift;
    my $wwnn = shift;
    my $wwpn = shift;

    return Sys::Virt::NodeDevice->_new(connection => $self,
				       wwnn => $wwnn,
				       wwpn => $wwpn);
}


=item my $iface = $vmm->get_interface_by_name($name)

Return the interface with a name of C<$name>. The returned object is
an instance of the L<Sys::Virt::Interface> class.

=cut

sub get_interface_by_name {
    my $self = shift;
    my $name = shift;

    return Sys::Virt::Interface->_new(connection => $self, name => $name);
}


=item my $iface = $vmm->get_interface_by_mac($mac)

Return the interface with a MAC address of C<$mac>. The returned object is
an instance of the L<Sys::Virt::Interface> class.

=cut

sub get_interface_by_mac {
    my $self = shift;
    my $mac = shift;

    return Sys::Virt::Interface->_new(connection => $self, mac => $mac);
}


=item my $sec = $vmm->get_secret_by_uuid($uuid)

Return the secret with a globally unique id of C<$uuid>. The returned object is
an instance of the L<Sys::Virt::Secret> class.

=cut

sub get_secret_by_uuid {
    my $self = shift;
    my $uuid = shift;

    return Sys::Virt::Secret->_new(connection => $self, uuid => $uuid);
}

=item my $sec = $vmm->get_secret_by_usage($usageType, $usageID)

Return the secret with a usage type of C<$usageType>, identified
by C<$usageID>. The returned object is an instance of the
L<Sys::Virt::Secret> class.

=cut

sub get_secret_by_usage {
    my $self = shift;
    my $type = shift;
    my $id = shift;

    return Sys::Virt::Secret->_new(connection => $self,
				   usageType => $type,
				   usageID => $id);
}

=item my $dom = $vmm->get_nwfilter_by_name($name)

Return the domain with a name of C<$name>. The returned object is
an instance of the L<Sys::Virt::NWFilter> class.

=cut

sub get_nwfilter_by_name {
    my $self = shift;
    my $name = shift;

    return Sys::Virt::NWFilter->_new(connection => $self, name => $name);
}


=item my $dom = $vmm->get_nwfilter_by_uuid($uuid)

Return the nwfilter with a globally unique id of C<$uuid>. The returned object is
an instance of the L<Sys::Virt::NWFilter> class.

=cut

sub get_nwfilter_by_uuid {
    my $self = shift;
    my $uuid = shift;

    return Sys::Virt::NWFilter->_new(connection => $self, uuid => $uuid);
}

=item my $xml = $vmm->find_storage_pool_sources($type, $srcspec[, $flags])

Probe for available storage pool sources for the pool of type C<$type>.
The C<$srcspec> parameter can be C<undef>, or a parameter to refine the
discovery process, for example a server hostname for NFS discovery. The
C<$flags> parameter is optional, and if omitted defaults to zero. The
returned scalar is an XML document describing the discovered storage
pool sources.

=item my @stats = $vmm->get_all_domain_stats($stats, \@doms=undef, $flags=0);

Get an list of all statistics for domains known to the hypervisor.
The C<$stats> parameter controls which data fields to return and
should be a combination of the DOMAIN STATS FIELD CONSTANTS.

The optional C<@doms> parameter is a list of Sys::Virt::Domain objects
to return stats for. If this is undefined, then all domains will be
returned. The C<$flags> method can be used to filter the list of
returned domains.

The return data for the method is a list, one element for each domain.
The element will be a hash with two keys, C<dom> pointing to an instance
of C<Sys::Virt::Domain> and C<data> pointing to another hash reference
containing the actual statistics.

=item $vmm->interface_change_begin($flags)

Begin a transaction for changing the configuration of one or more
network interfaces

=item $vmm->interface_change_commit($flags)

Complete a transaction for changing the configuration of one or more
network interfaces

=item $vmm->interface_change_rollback($flags)

Abort a transaction for changing the configuration of one or more
network interfaces

=item $vmm->restore_domain($savefile)

Recreate a domain from the saved state file given in the C<$savefile> parameter.

=item $vmm->get_max_vcpus($domtype)

Return the maximum number of vcpus that can be configured for a domain
of type C<$domtype>

=item my $hostname = $vmm->get_hostname()

Return the name of the host with which this connection is associated.

=item my $uri = $vmm->get_uri()

Return the URI associated with the open connection. This may be different
from the URI used when initially connecting to libvirt, when 'auto-probing'
or drivers occurrs.

=item my $xml = $vmm->get_sysinfo()

Return an XML documenting representing the host system information,
typically obtained from SMBIOS tables.

=item my $type = $vmm->get_type()

Return the type of virtualization backend accessed by this VMM object. Currently
the only supported type is C<Xen>.

=item my $xml = $vmm->domain_xml_from_native($format, $config);

Convert the native hypervisor configuration C<$config> which is in format
<$format> into libvirrt domain XML. Valid values of C<$format> vary between
hypervisor drivers.

=item my $config = $vmm->domain_xml_to_native($format, $xml)

Convert the libvirt domain XML configuration C<$xml> to a native hypervisor
configuration in format C<$format>

=item my $ver = $vmm->get_version()

Return the complete version number as a string encoded in the
formula C<(major * 1000000) + (minor * 1000) + micro>.

=item my $ver = $vmm->get_major_version

Return the major version number of the libvirt library.

=cut

sub get_major_version {
    my $self = shift;
    my $ver = $self->get_version;
    return ($ver - ($ver % 1000000))/1000000;
}


=item my $ver = $vmm->get_minor_version

Return the minor version number of the libvirt library.

=cut

sub get_minor_version {
    my $self = shift;
    my $ver = $self->get_version;
    my $mver = $ver % 1000000;
    return ($mver - ($mver % 1000)) / 1000;
}

=item my $ver = $vmm->get_micro_version

Return the micro version number of the libvirt library.

=cut

sub get_micro_version {
    my $self = shift;
    return $self->get_version % 1000;
}

sub get_version {
    my $self = shift;
    if (defined $self) {
	return $self->_get_conn_version;
    } else {
	return &Sys::Virt::_get_library_version();
    }
}

=item my $ver = $vmm->get_library_version

Return the version number of the API associated with
the active connection. This differs from C<get_version>
in that if the connection is to a remote libvirtd
daemon, it will return the API version of the remote
libvirt, rather than the local client.

=cut

sub get_library_version {
    my $self = shift;
    return $self->_get_conn_library_version;
}

1;

=pod

=item $conn->is_secure()

Returns a true value if the current connection is secure against
network interception. This implies either use of UNIX sockets,
or encryption with a TCP stream.

=item $conn->is_encrypted()

Returns a true value if the current connection data stream is
encrypted.

=item $conn->is_alive()

Returns a true value if the connection is alive, as determined
by keep-alive packets or other recent RPC traffic.

=item $conn->set_keep_alive($interval, $count)

Change the operation of the keep alive protocol to send C<$count>
packets spaced C<$interval> seconds apart before considering the
connection dead.

=item my $info = $con->get_node_info()

Returns a hash reference summarising the capabilities of the host
node. The elements of the hash are as follows:

=over 4

=item memory

The amount of physical memory in the host

=item model

The model of the CPU, eg x86_64

=item cpus

The total number of logical CPUs.

=item mhz

The peak MHZ of the CPU

=item nodes

The number of NUMA cells

=item sockets

The number of CPU sockets

=item cores

The number of cores per socket

=item threads

The number of threads per core

=back

NB, more accurate information about the total number of CPUs
and those online can be obtained using the C<get_node_cpu_map>
method.

=item my ($totcpus, $onlinemap, $totonline) = $con->get_node_cpu_map();

Returns an array containing information about the CPUs available
on the host. The first element, C<totcpus>, specifies the total
number of CPUs available to the host regardles of their online
stat. The second element, C<onlinemap>, provides a bitmap detailing
which CPUs are currently online. The third element, C<totonline>,
specifies the total number of online CPUs. The values in the bitmap
can be extracted using the C<unpack> method as follows:

  my @onlinemap = split(//, unpack("b*", $onlinemap));

=item my $info = $con->get_node_cpu_stats($cpuNum=-1, $flags=0)

Returns a hash reference providing information about the host
CPU statistics. If <$cpuNum> is omitted, it defaults to C<Sys::Virt::NODE_CPU_STATS_ALL_CPUS>
which causes it to return cummulative information for all
CPUs in the host. If C<$cpuNum> is zero or larger, it returns
information just for the specified number. The C<$flags>
parameter is currently unused and defaults to zero. The
fields in the returned hash reference are

=over 4

=item kernel

The time spent in kernelspace

=item user

The time spent in userspace

=item idle

The idle time

=item iowait

The I/O wait time

=item utilization

The overall percentage utilization.

=back

=item my $info = $con->get_node_memory_stats($cellNum=-1, $flags=0)

Returns a hash reference providing information about the host
memory statistics. If <$cellNum> is omitted, it defaults to C<Sys::Virt::NODE_MEMORY_STATS_ALL_CELLS>
which causes it to return cummulative information for all
NUMA cells in the host. If C<$cellNum> is zero or larger, it
returns information just for the specified number. The C<$flags>
parameter is currently unused and defaults to zero. The
fields in the returned hash reference are

=over 4

=item total

The total memory

=item free

The free memory

=item buffers

The memory consumed by buffers

=item cached

The memory consumed for cache

=back

=item my $params = $conn->get_node_memory_parameters($flags=0)

Return a hash reference containing the set of memory tunable
parameters for the node. The keys in the hash are one of the
constants MEMORY PARAMETERS described later. The C<$flags>
parameter is currently unused, and defaults to 0 if omitted.

=item $conn->set_node_memory_parameters($params, $flags=0)

Update the memory tunable parameters for the node. The
C<$params> should be a hash reference whose keys are one
of the MEMORY PARAMETERS constants. The C<$flags>
parameter is currently unused, and defaults to 0 if omitted.


=item $conn->node_suspend_for_duration($target, $duration, $flags=0)

Suspend the the host, using mode C<$target> which is one of the NODE
SUSPEND constants listed later. The C<$duration> parameter controls
how long the node is suspended for before waking up.

=item $conn->domain_event_register($callback)

Register a callback to received notificaitons of domain state change
events. Only a single callback can be registered with each connection
instance. The callback will be invoked with four parameters, an
instance of C<Sys::Virt> for the connection, an instance of C<Sys::Virt::Domain>
for the domain changing state, and a C<event> and C<detail> arguments,
corresponding to the event constants defined in the C<Sys::Virt::Domain>
module. Before discarding the connection object, the callback must be
deregistered, otherwise the connection object memory will never be
released in garbage collection.

=item $conn->domain_event_deregister()

Unregister a callback, allowing the connection object to be garbage
collected.

=item $callback = $conn->domain_event_register_any($dom, $eventID, $callback)

Register a callback to received notifications of domain events.
The C<$dom> parameter can be C<undef> to request events on all
known domains, or a specific C<Sys::Virt::Domain> object to
filter events. The C<$eventID> parameter is one of the EVENT ID
constants described later in this document. The C<$callback> is
a subroutine reference that will receive the events.

All callbacks receive a C<Sys::Virt> connection as the first parameter
and a C<Sys::Virt::Domain> object indicating the domain on which the
event occurred as the second parameter. Subsequent parameters vary
according to the event type

=over

=item EVENT_ID_LIFECYCLE

Extra C<event> and C<detail> parameters defining the lifecycle
transition that occurred.

=item EVENT_ID_REBOOT

No extra parameters

=item EVENT_ID_RTC_CHANGE

The C<utcoffset> gives the offset from UTC in seconds

=item EVENT_ID_WATCHDOG

The C<action> defines the action that is taken as a result
of the watchdog triggering. One of the WATCHDOG constants
described later

=item EVENT_ID_IO_ERROR

The C<srcPath> is the file on the host which had the error.
The C<devAlias> is the unique device alias from the guest
configuration associated with C<srcPath>. The C<action> is
the action taken as a result of the error, one of the
IO ERROR constants described later

=item EVENT_ID_GRAPHICS

The C<phase> is the stage of the connection, one of the GRAPHICS
PHASE constants described later. The C<local> and C<remote>
parameters follow with the details of the local and remote
network addresses. The C<authScheme> describes how the user
was authenticated (if at all). Finally C<identities> is an
array ref containing authenticated identities for the user,
if any.

=back

The return value is a unique callback ID that must be used when
unregistering the event.


=item $conn->domain_event_deregister_any($callbackID)

Unregister a callback, associated with the C<$callbackID> previously
obtained from C<domain_event_register_any>.

=item $callback = $conn->network_event_register_any($net, $eventID, $callback)

Register a callback to received notifications of network events.
The C<$net> parameter can be C<undef> to request events on all
known networks, or a specific C<Sys::Virt::Network> object to
filter events. The C<$eventID> parameter is one of the EVENT ID
constants described later in this document. The C<$callback> is
a subroutine reference that will receive the events.

All callbacks receive a C<Sys::Virt> connection as the first parameter
and a C<Sys::Virt::Network> object indicating the network on which the
event occurred as the second parameter. Subsequent parameters vary
according to the event type

=over

=item EVENT_ID_LIFECYCLE

Extra C<event> and C<detail> parameters defining the lifecycle
transition that occurred.

=back

The return value is a unique callback ID that must be used when
unregistering the event.


=item $conn->network_event_deregister_any($callbackID)

Unregister a callback, associated with the C<$callbackID> previously
obtained from C<network_event_register_any>.

=item $callback = $conn->storage_pool_event_register_any($pool, $eventID, $callback)

Register a callback to received notifications of storage pool events.
The C<$pool> parameter can be C<undef> to request events on all
known storage pools, or a specific C<Sys::Virt::StoragePool> object
to filter events. The C<$eventID> parameter is one of the EVENT ID
constants described later in this document. The C<$callback> is
a subroutine reference that will receive the events.

All callbacks receive a C<Sys::Virt> connection as the first parameter
and a C<Sys::Virt::StoragePool> object indicating the storage pool on
which the event occurred as the second parameter. Subsequent parameters
vary according to the event type

=over

=item EVENT_ID_LIFECYCLE

Extra C<event> and C<detail> parameters defining the lifecycle
transition that occurred.

=item EVENT_ID_REFRESH

No extra parameters.

=back

The return value is a unique callback ID that must be used when
unregistering the event.


=item $conn->storage_pool_event_deregister_any($callbackID)

Unregister a callback, associated with the C<$callbackID> previously
obtained from C<storage_pool_event_register_any>.

=item $callback = $conn->node_device_event_register_any($dev, $eventID, $callback)

Register a callback to received notifications of node device events.
The C<$dev> parameter can be C<undef> to request events on all
known node devices, or a specific C<Sys::Virt::NodeDevice> object
to filter events. The C<$eventID> parameter is one of the EVENT ID
constants described later in this document. The C<$callback> is
a subroutine reference that will receive the events.

All callbacks receive a C<Sys::Virt> connection as the first parameter
and a C<Sys::Virt::NodeDevice> object indicating the node device on
which the event occurred as the second parameter. Subsequent parameters
vary according to the event type

=over

=item EVENT_ID_LIFECYCLE

Extra C<event> and C<detail> parameters defining the lifecycle
transition that occurred.

=back

The return value is a unique callback ID that must be used when
unregistering the event.


=item $conn->node_device_event_deregister_any($callbackID)

Unregister a callback, associated with the C<$callbackID> previously
obtained from C<node_device_event_register_any>.

=item $callback = $conn->secret_event_register_any($secret, $eventID, $callback)

Register a callback to received notifications of secret events.
The C<$secret> parameter can be C<undef> to request events on all
known secrets, or a specific C<Sys::Virt::Secret> object to
filter events. The C<$eventID> parameter is one of the EVENT ID
constants described later in this document. The C<$callback> is
a subroutine reference that will receive the events.

All callbacks receive a C<Sys::Virt> connection as the first parameter
and a C<Sys::Virt::Secret> object indicating the secret on which the
event occurred as the second parameter. Subsequent parameters vary
according to the event type

=over

=item EVENT_ID_LIFECYCLE

Extra C<event> and C<detail> parameters defining the lifecycle
transition that occurred.

=item EVENT_ID_VALUE_CHANGED

No extra parameters.

=back

The return value is a unique callback ID that must be used when
unregistering the event.


=item $conn->secret_event_deregister_any($callbackID)

Unregister a callback, associated with the C<$callbackID> previously
obtained from C<secret_event_register_any>.

=item $conn->register_close_callback($coderef);

Register a callback to be invoked when the connection is closed.
The callback will be invoked with two parameters, the C<$conn>
it was registered against, and the reason for the close event.
The reason value will be one of the C<CLOSE REASON CONSTANTS>
listed later in this document.

=item $conn->unregister_close_callback();

Remove the previously registered close callback.

=item my $xml = $con->baseline_cpu(\@xml, $flags=0)

Given an array ref whose elements are XML documents describing host CPUs,
compute the baseline CPU model that is operable across all hosts. The
XML for the baseline CPU model is returned. The optional C<$flags>
parameter can take one of

=over 4

=item Sys::Virt::BASELINE_CPU_EXPAND_FEATURES

Expand the CPU definition to list all feature flags, even those
implied by the model name.

=item Sys::Virt::BASELINE_CPU_MIGRATABLE

Only include features which can be live migrated.

=back

=item @names = $con->get_cpu_model_names($arch, $flags=0)

Get a list of valid CPU models names for the architecture
given by C<$arch>. The C<$arch> value should be one of the
architectures listed in the capabilities XML document.
The C<$flags> parameter is currently unused and defaults
to 0.

=item my $info = $con->get_node_security_model()

Returns a hash reference summarising the security model of the
host node. There are two keys in the hash, C<model> specifying
the name of the security model (eg 'selinux') and C<doi>
specifying the 'domain of interpretation' for security labels.

=item my $xml = $con->get_capabilities();

Returns an XML document describing the hypervisor capabilities

=item my $xml = $con->get_domain_capabilities($emulator, $arch, $machine, $virttype, flags=0);

Returns an XML document describing the capabilities of the
requested guest configuration. Either C<$emulator> or C<$arch>
must be a valid string referring to an emulator binary or an
architecture name respectively. The C<$machine> parameter is
an optional name of a guest machine, and C<$virttype> is an
optional name of the virtualization type. C<$flags> is unused
and defaults to zero.

=item my $result = $con->compare_cpu($xml, $flags=0);

Checks whether the CPU definition in C<$xml> is compatible with the
current hypervisor connection. This can be used to determine whether
it is safe to migrate a guest to this host. The returned result is
one of the constants listed later The optional C<$flags> parameter
can take one of the following constants

=over 4

=item Sys::Virt::COMPARE_CPU_FAIL_INCOMPATIBLE

Raise a fatal error if the CPUs are not compatible, instead of
just returning a special error code.

=back

=item $mem = $con->get_node_free_memory();

Returns the current free memory on the host

=item @mem = $con->get_node_cells_free_memory($start, $end);

Returns the free memory on each NUMA cell between C<$start> and C<$end>.

=item @pages = $con->get_node_free_pages(\@pagesizes, $start, $end);

Returns information about the number of pages free on each NUMA cell
between C<$start> and C<$end> inclusive. The C<@pagesizes> parameter
should be an arrayref specifying which pages sizes information should
be returned for. Information about supported page sizes is available
in the capabilities XML. The returned array has an element for each
NUMA cell requested. The elements are hash references with two keys,
'cell' specifies the NUMA cell number and 'pages' specifies the
free page information for that cell. The 'pages' value is another
hash reference where the keys are the page sizes and the values
are the free count for that size.

=item $con->node_alloc_pages(\@pages, $start, $end, $flags=0)

Allocate further huge pages for the reserved dev. The <\@pages>
parameter is an array reference with one entry per page size to
allocate for. Each entry is a further array reference where the
first element is the page size and the second element is the
page count. The same number of pages will be allocated on each
NUMA node in the range C<$start> to C<$end> inclusive. The
C<$flags> parameter accepts two contants

=over 4

=item Sys::Virt::NODE_ALLOC_PAGES_ADD

The requested number of pages will be added to the existing huge
page reservation.

=item Sys::Virt::NODE_ALLOC_PAGES_SET

The huge page reservation will be set to exactly the requested
number

=back

=back

=head1 CONSTANTS

The following sets of constants are useful when dealing with APIs
in this package

=head2 CONNECTION

When opening a connection the following constants can be used:

=over 4

=item Sys::Virt::CONNECT_RO

Request a read-only connection

=item Sys::Virt::CONNECT_NO_ALIASES

Prevent the resolution of URI aliases

=back

=head2 CREDENTIAL TYPES

When providing authentication callbacks, the following constants
indicate the type of credential being requested

=over 4

=item Sys::Virt::CRED_AUTHNAME

Identity to act as

=item Sys::Virt::CRED_USERNAME

Identity to authorize as

=item Sys::Virt::CRED_CNONCE

Client supplies a nonce

=item Sys::Virt::CRED_REALM

Authentication realm

=item Sys::Virt::CRED_ECHOPROMPT

Challenge response non-secret

=item Sys::Virt::CRED_NOECHOPROMPT

Challenge response secret

=item Sys::Virt::CRED_PASSPHRASE

Passphrase secret

=item Sys::Virt::CRED_LANGUAGE

RFC 1766 language code

=item Sys::Virt::CRED_EXTERNAL

Externally provided credential

=back

=head2 CPU COMPARISON CONSTANTS

=over 4

=item Sys::Virt::CPU_COMPARE_INCOMPATIBLE

This host is missing one or more CPU features in the CPU
description

=item Sys::Virt::CPU_COMPARE_IDENTICAL

The host has an identical CPU description

=item Sys::Virt::CPU_COMPARE_SUPERSET

The host offers a superset of the CPU descriptoon

=back

=head2 NODE SUSPEND CONSTANTS

=over 4

=item Sys::Virt::NODE_SUSPEND_TARGET_MEM

Suspends to memory (equivalent of S3 on x86 architectures)

=item Sys::Virt::NODE_SUSPEND_TARGET_DISK

Suspends to disk (equivalent of S5 on x86 architectures)

=item Sys::Virt::NODE_SUSPEND_TARGET_HYBRID

Suspends to memory and disk (equivalent of S3+S5 on x86 architectures)

=back

=head2 NODE VCPU CONSTANTS

=over 4

=item Sys::Virt::NODE_CPU_STATS_ALL_CPUS

Request statistics for all CPUs

=back

=head2 NODE MEMORY CONSTANTS

=over 4

=item Sys::Virt::NODE_MEMORY_STATS_ALL_CELLS

Request statistics for all memory cells

=back

=head2 MEMORY PARAMETERS

The following constants are used to name memory
parameters of the node

=over 4

=item Sys::Virt::NODE_MEMORY_SHARED_FULL_SCANS

How many times all mergeable areas have been scanned.

=item Sys::Virt::NODE_MEMORY_SHARED_PAGES_SHARED

How many the shared memory pages are being used.

=item Sys::Virt::NODE_MEMORY_SHARED_PAGES_SHARING

How many sites are sharing the pages

=item Sys::Virt::NODE_MEMORY_SHARED_PAGES_TO_SCAN

How many present pages to scan before the shared memory service goes to sleep

=item Sys::Virt::NODE_MEMORY_SHARED_PAGES_UNSHARED

How many pages unique but repeatedly checked for merging.

=item Sys::Virt::NODE_MEMORY_SHARED_PAGES_VOLATILE

How many pages changing too fast to be placed in a tree.

=item Sys::Virt::NODE_MEMORY_SHARED_SLEEP_MILLISECS

How many milliseconds the shared memory service should sleep before next scan.

=item Sys::Virt::NODE_MEMORY_SHARED_MERGE_ACROSS_NODES

Whether pages can be merged across NUMA nodes

=back

=head2 CLOSE REASON CONSTANTS

The following constants related to the connection close callback,
describe the reason for the closing of the connection.

=over 4

=item Sys::Virt::CLOSE_REASON_CLIENT

The client application requested the connection be closed

=item Sys::Virt::CLOSE_REASON_EOF

End-of-file was encountered reading data from the connection

=item Sys::Virt::CLOSE_REASON_ERROR

An I/O error was encountered reading/writing data from/to the
connection

=item Sys::Virt::CLOSE_REASON_KEEPALIVE

The connection keepalive timer triggered due to lack of response
from the server

=back

=head2 CPU STATS CONSTANTS

The following constants provide the names of known CPU stats fields

=over 4

=item Sys::Virt::NODE_CPU_STATS_IDLE

Time spent idle

=item Sys::Virt::NODE_CPU_STATS_IOWAIT

Time spent waiting for I/O to complete

=item Sys::Virt::NODE_CPU_STATS_KERNEL

Time spent executing kernel code

=item Sys::Virt::NODE_CPU_STATS_USER

Time spent executing user code

=item Sys::Virt::NODE_CPU_STATS_INTR

Time spent processing interrupts

=item Sys::Virt::NODE_CPU_STATS_UTILIZATION

Percentage utilization of the CPU.

=back

=head2 MEMORY STAS CONSTANTS

The following constants provide the names of known memory stats fields

=over 4

=item Sys::Virt::NODE_MEMORY_STATS_BUFFERS

The amount of memory consumed by I/O buffers

=item Sys::Virt::NODE_MEMORY_STATS_CACHED

The amount of memory consumed by disk cache

=item Sys::Virt::NODE_MEMORY_STATS_FREE

The amount of free memory

=item Sys::Virt::NODE_MEMORY_STATS_TOTAL

The total amount of memory

=back

=head2 IP address constants

The following constants are used to interpret IP address types

=over 4

=item Sys::Virt::IP_ADDR_TYPE_IPV4

An IPv4 address type

=item Sys::Virt::IP_ADDR_TYPE_IPV6

An IPv6 address type

=back

=head1 BUGS

Hopefully none, but the XS code needs to be audited to ensure it
is not leaking memory.

=head1 AUTHORS

Daniel P. Berrange <berrange@redhat.com>

=head1 COPYRIGHT

Copyright (C) 2006-2009 Red Hat
Copyright (C) 2006-2009 Daniel P. Berrange

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of either the GNU General Public License as published
by the Free Software Foundation (either version 2 of the License, or at
your option any later version), or, the Artistic License, as specified
in the Perl README file.

=head1 SEE ALSO

L<Sys::Virt::Domain>, L<Sys::Virt::Network>, L<Sys::Virt::StoragePool>,
L<Sys::Virt::StorageVol>, L<Sys::Virt::Error>, C<http://libvirt.org>

=cut
