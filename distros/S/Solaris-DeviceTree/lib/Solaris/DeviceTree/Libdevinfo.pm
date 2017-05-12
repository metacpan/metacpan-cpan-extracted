#
# $Header: /cvsroot/devicetool/Solaris-DeviceTree/lib/Solaris/DeviceTree/Libdevinfo.pm,v 1.9 2003/12/12 11:11:55 honkbude Exp $
#

package Solaris::DeviceTree::Libdevinfo;

use 5.006;
use strict;
use warnings;
use Carp;
use English;

our @ISA = qw( Solaris::DeviceTree::Node );
our $VERSION = do { my @r = (q$Revision: 1.9 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

use Solaris::DeviceTree::Libdevinfo::Impl;
use Solaris::DeviceTree::Libdevinfo::MinorNode;
use Solaris::DeviceTree::Libdevinfo::Property;
use Solaris::DeviceTree::Libdevinfo::PromProperty;

# Package global containing a reference to the Libdevinfo tree (singleton)
our $_ROOT_NODE;

# Package global containing a reference to the system PROM handle (singleton)
our $_PROM_HANDLE;

=pod

=head1 NAME

Solaris::DeviceTree::Libdevinfo - Perl interface to the Solaris devinfo library

=head1 SYNOPSIS

Construction and destruction:

  use Solaris::DeviceTree::Libdevinfo;
  $tree = Solaris::DeviceTree::Libdevinfo->new;

Data access methods:

  $path = $node->devfs_path;
  $nodename = $node->node_name;
  $bindingname = $node->binding_name;
  $busaddr = $node->bus_addr;
  @cnames = $devtree->compatible_names;
  $drivername = $devtree->driver_name;
  %ops = $devtree->driver_ops;
  $inst = $node->instance;
  %state = $node->state;
  $id = $node->nodeid;
  if( $node->is_pseudo_node ) { ... }
  if( $node->is_sid_node ) { ... }
  if( $node->is_prom_node ) { ... }
  $props = $node->props;
  $promprops = $node->prom_props;
  @minor = $node->minor_nodes;

=head1 DESCRIPTION

This module implements the L<Solaris::DeviceTree::Node> interface
and allows access to the Solaris devinfo library L<libdevinfo(3lib)>.
The devicetree is represented as a hierarchical collection of nodes
in the kernel.

The implementation closely resembles the API of the C library. However,
due to the object interface and the beauty of Perl there a few differences to keep in mind
when using this library after reading the manual pages of the original
L<libdevinfo(3lib)>:

=over 4

=item *

The 'di_'-prefix of the function names from the C API has been stripped.

=item *

The functions C<di_init> and C<di_fini> for generation and destruction of
devicetrees are now called implicitly during contruction and destruction repectively.

=item *

Accessing the nodes by driver via C<di_drv_first_node> and C<di_drv_next_node>
is not implemented in favor of the much more expressive C<find_nodes>
added in Perl.

=item *

The function C<di_walk_node> is not implemented because treewalking
in Perl using C<child_nodes> is much easier than in C and is therefore
not needed.

=item *

Getting child nodes via subsequent calls to C<di_child_node> has been
simplified to a single call to C<child_nodes> returning an array of
all child nodes.

=item *

Access to C<di_devid> is currently not implemented as the returned
value is meaningless without access to L<libdevid(3lib)>, which I have not done (yet).
Requests welcome.

=back

     di_binding_name               di_bus_addr
     di_child_node                 di_compatible_names
     di_devfs_path                 di_devfs_path_free
     di_devid                      di_driver_name
     di_driver_ops                 di_drv_first_node
     di_drv_next_node              di_fini
     di_init                       di_instance
     di_minor_class                di_minor_devt
     di_minor_name                 di_minor_next
     di_minor_nodetype             di_minor_spectype
     di_minor_type                 di_node_name
     di_nodeid                     di_parent_node
     di_prom_fini                  di_prom_init
     di_prom_prop_data             di_prom_prop_lookup_bytes
     di_prom_prop_lookup_ints      di_prom_prop_lookup_strings
     di_prom_prop_name             di_prom_prop_next
     di_prop_bytes                 di_prop_devt
     di_prop_ints                  di_prop_lookup_bytes
     di_prop_lookup_ints           di_prop_lookup_strings
     di_prop_name                  di_prop_next
     di_prop_strings               di_prop_type
     di_sibling_node               di_state
     di_walk_minor                 di_walk_node

=head1 METHODS

For tree traversal methods see the base class L<Solaris::DeviceTree::Node>.

The following methods are available:

=head2 new

The constructor returns a reference to the root node object, which is a
L<Solaris::DeviceTree::Libdevinfo> object.
The methods are all read-only.

=cut

sub new {
  my ($pkg, %params) = @_;

  # We always want to access all information from the complete tree.
  # If only a subset of information is needed we handle it on the
  # perl end. This might be a performance issue when lots of trees
  # are generated, but as the methods are all read-only a singleton
  # tree should be sufficient.

  if( !defined $_ROOT_NODE ) {
    $_ROOT_NODE = bless {
      _data => di_init( "/", $DINFOCPYALL ),
      _parent => undef,
    }, $pkg;
  }
  return $_ROOT_NODE;
}

# Special constructor for internal nodes
sub _new_internal {
  my ($pkg, %params) = @_;

  # The parameter 'data' has the SWIG-type di_node_t and points to
  # the C data structure needed to access the node from the C library.
  # The parameter 'parent' points to the parent Perl object of this
  # node in the device tree. This is done in favor of using di_parent_node
  # from the library for two reasons: first it's a lot easier, second
  # it is good to have at most one object per node from the devicetree.
  # Checking the identity of a node can than be done by comparing the
  # references.
  # Both parameters should only be used when nodes inside the tree
  # are created from within methods of this class.

  die "No data specified." if( !defined $params{data} );
  die "No parent specified." if( !defined $params{parent} );

  my $this = bless {
    _data => $params{data},
    _parent => $params{parent},
  }, $pkg;

  return $this;
}

# This helper function generates a persistent prom handle on demand
# and returns it.
sub _prom_handle {
  if( !defined $_PROM_HANDLE ) {
    $_PROM_HANDLE = di_prom_init();
    if( isDI_PROM_HANDLE_NIL( $_PROM_HANDLE ) ) {
       # Maybe an exception should be thrown here.
#      warn "Cannot access PROM device: $ERRNO";
      $_PROM_HANDLE = undef;
    }
  }
  return $_PROM_HANDLE;
}

#=pod
#
#=head3 $tree->DESTROY;
#
#This is the destructor method. It should not be necessary to
#call this method directly.
#
#This is the equivalent of calling C<di_fini> from the C API.
#
#=cut

sub DESTROY {
  my $this = shift;

  # We need weak references for singletons. Fix this some time...
  if( !defined $this->{_parent} ) {
    di_prom_fini( $this->{_prom_handle} ) if( defined $this->{_prom_handle} );
    $this->{_prom_handle} = undef;
    di_fini( $this->{_data} ) if( defined $this->{_data} );
    $this->{_data} = undef;
  }
}

# tree traversal documented in Solaris::DeviceTree::Node
sub child_nodes {
  my ($this, %options) = @_;

  # The children of each node are cached
  if( !exists $this->{_children} ) {
    # Cache is empty, fill it.
    my @result = ();
    my $child = di_child_node( $this->{_data} );

    # Iterate over all children and generate objects accordlingly
    while( !isDI_NODE_NIL( $child ) ) {
      push @result, Solaris::DeviceTree::Libdevinfo->_new_internal(
        data => $child, parent => $this );
      $child = di_sibling_node( $child );
    }

    # Store result in cache
    $this->{_children} = \@result;
  }

  # Always return contents of cache
  return @{$this->{_children}};
}

# tree traversal documented in Solaris::DeviceTree::Node
sub parent_node {
  my $this = shift;

  # We directly return the parent node. Especially we don't use
  # di_parent_node from the C library. See the description of
  # the constructor for the reason.
  return $this->{_parent};
}

# tree traversal documented in Solaris::DeviceTree::Node
sub root_node {
  my $this = shift;

  # Since we have a singleton the same reference to the object is
  # always returned.
  return $_ROOT_NODE;
}

# tree traversal documented in Solaris::DeviceTree::Node
sub sibling_nodes {
  my $this = shift;

  my $parent = $this->parent_node;

  # Read all siblings including $this
  my @siblings = defined $parent ? $parent->child_nodes : ();

  # Strip out current node
  my @sib = grep { $_ ne $this } @siblings;

  return @sib;
}

=pod

=head2 devfs_path

Returns the physical path assocatiated with this node.

=cut

sub devfs_path {
  my $this = shift;
  return di_devfs_path( $this->{_data} );
}

=pod

=head2 node_name

Returns the name of the node.

=cut

sub node_name {
  my $this = shift;
  return di_node_name( $this->{_data} );
}

=pod

=head2 binding_name

Returns the binding name for this node. The binding name
is the name used by the system to select a driver for the device.

=cut

sub binding_name {
  my $this = shift;
  return di_binding_name( $this->{_data} );
}

=pod

=head2 bus_addr

Returns the address on the bus for this node. C<undef> is returned
if a bus address has not been assigned to the device. A zero-length
string may be returned and is considered a valid bus address.

=cut

sub bus_addr {
  my $this = shift;
  my $busaddr = di_bus_addr( $this->{_data} );
  return $busaddr;
}

=pod

=head2 compatible_names

Returns the list of names from compatible device for the current node.
See the discussion of generic names in L<Writing  Device Drivers|> for
a description of how compatible names are used by Solaris to achieve
driver binding for the node.

=cut

sub compatible_names {
  my $this = shift;
  my $node = $this->{_data};

  my $namehandle = newStringHandle();
  my $lastIndex = di_compatible_names( $node, $namehandle ) - 1;
  my @compatibleNames =
    map { getIndexedString( $namehandle, $_ ) } 0..$lastIndex;
  freeStringHandle( $namehandle );

  @compatibleNames;
}

#sub devid {
#  my $this = shift;
#  my $devid = di_devid( $this->{_data} );
#  return (isDevidNull( $devid ) == 0 ? $devid : 0);
#}

=pod

=head2 driver_name

Returns the name of the driver for the node or C<undef> if the node
is not bound to any driver.

=cut

sub driver_name {
  my $this = shift;
  return di_driver_name( $this->{_data} );
}

=pod

=head2 driver_ops

Returns a hash whos keys indicate, which entry points of the
device driver entry points are supported by the driver bound
to this node. Possible keys are:

  BUS
  CB
  STREAM

=cut

sub driver_ops {
  my $this = shift;

  my $ops = di_driver_ops( $this->{_data} );
  my %ops;

  $ops{BUS}    = 1 if( $ops & $DI_BUS_OPS );
  $ops{CB}     = 1 if( $ops & $DI_CB_OPS );
  $ops{STREAM} = 1 if( $ops & $DI_STREAM_OPS );
  return %ops;
}

=pod

=head2 instance

Returns the instance number for this node of the bound driver.
C<undef> is returned if no instance number has been assigned.

=cut

sub instance {
  my $this = shift;
  my $instance = di_instance( $this->{_data} );
  # if instance number is -1 then no instance was bound
  $instance = undef if( $instance == -1 );
  return $instance;
}

=pod

=head2 state

Returns the driver state attached to this node as hash.
The presence of the keys in the hash represent the states
of the driver. The following keys in the hash can be present:

  DRIVER_DETACHED
  DEVICE_OFFLINE
  DEVICE_DOWN
  BUS_QUIESCED
  BUS_DOWN

=cut

sub state {
  my $this = shift;

  my $state = di_state( $this->{_data} );
  my %state;

  $state{DRIVER_DETACHED} = 1 if( $state & $DI_DRIVER_DETACHED );
  $state{DEVICE_OFFLINE}  = 1 if( $state & $DI_DEVICE_OFFLINE );
  $state{DEVICE_DOWN}     = 1 if( $state & $DI_DEVICE_DOWN );
  $state{BUS_QUISCED}     = 1 if( $state & $DI_BUS_QUIESCED );
  $state{BUS_DOWN}        = 1 if( $state & $DI_BUS_DOWN );

  return %state;
}

=pod

=head2 nodeid

Returns the type of the node. Three different strings identifying
the types can be returned or C<undef> if the type is unknown:

  PSEUDO
  SID
  PROM

Nodes of the type C<PROM> may have additional PROM properties that
are defined by the PROM. The properties can be accessed with L</prom_props>.

=cut

sub nodeid {
  my $this = shift;
  my %_nodeid = (
    $DI_PSEUDO_NODEID => 'PSEUDO',
    $DI_SID_NODEID => 'SID',
    $DI_PROM_NODEID => 'PROM',
  );

  my $nodeid = di_nodeid( $this->{_data} );
  my $result = ( exists $_nodeid{ $nodeid } ? $_nodeid{ $nodeid } : undef );
  return $result;
}

=pod

=head2 is_pseudo_node
=head2 is_sid_node
=head2 is_prom_node

Returns C<true> if the node is of type pseudo / SID / PROM or C<undef> if not.

=cut

sub is_pseudo_node {
  my $this = shift;
  return di_nodeid( $this->{_data} ) == $DI_PSEUDO_NODEID ? 'PSEUDO' : undef;
}

sub is_sid_node {
  my $this = shift;
  return di_nodeid( $this->{_data} ) == $DI_SID_NODEID ? 'SID' : undef;
}


sub is_prom_node {
  my $this = shift;

  return di_nodeid( $this->{_data} ) == $DI_PROM_NODEID ? 'PROM' : undef;
}

=pod

=head2 props

Returns a reference to a hash which maps property names to property values.
The property values are of class L<Solaris::DeviceTree::Libdevinfo::Property>.

=cut

sub props {
  my $this = shift;
  my $node = $this->{_data};

  if( !exists $this->{_props} ) {
    my %props;
    my $prop = di_prop_next( $node, makeDI_PROP_NIL() );
    while( !isDI_PROP_NIL( $prop ) ) {
      my $propObj = new Solaris::DeviceTree::Libdevinfo::Property( $prop );
      $props{ $propObj->name } = $propObj;
      $prop = di_prop_next( $node, $prop );
    }
    $this->{_props} = \%props;
  }
  return $this->{_props};
}

=pod

=head2 prom_props

Returns a reference to a hash which maps PROM property names to property values.
The property values are of class L<Solaris::DeviceTree::Libdevinfo::PromProperty>.
If the PROM device can not be opened (most likely because the process does
not have the permission to access C</dev/openprom>) then C<undef> is returned.

=cut

sub prom_props {
  my $this = shift;
  my $node = $this->{_data};

  if( !exists $this->{_prom_props} ) {
    my %props;
    my $ph = $this->_prom_handle;
    if( defined $ph ) {
      my $handle = newUCharTHandle();
      my $prop = di_prom_prop_next( $ph, $node, makeDI_PROM_PROP_NIL() );
      while( !isDI_PROM_PROP_NIL( $prop ) ) {
        my $name = di_prom_prop_name( $prop );
        my $count = di_prom_prop_data( $prop, $handle );
        my $data = pack "C" x $count, map { getIndexedByte( $handle, $_ ) } 0 .. $count-1;
        $props{ $name } = Solaris::DeviceTree::Libdevinfo::PromProperty->new( $data );
  
        $prop = di_prom_prop_next( $ph, $node, $prop );
      }
      freeUCharTHandle( $handle );
      $this->{_prom_props} = \%props;
    } else {
      $this->{_prom_props} = undef;
    }
  }

  return $this->{_prom_props};
}

=pod

=head2 minor_nodes

Returns a reference to a list of all minor nodes which are associated with this node.
The minor nodes are of class L<Solaris::DeviceTree::Libdevinfo::MinorNode>.

=cut

sub minor_nodes {
  my $this = shift;
  my $node = $this->{_data};

  if( !exists $this->{_minorNodes} ) {
    my @minorNodes;
    my $minor = di_minor_next( $node, makeDI_MINOR_NIL() );
    while( !isDI_MINOR_NIL( $minor ) ) {
      push @minorNodes, new Solaris::DeviceTree::Libdevinfo::MinorNode( $minor, $this );
      $minor = di_minor_next( $node, $minor );
    }
    $this->{_minorNodes} = \@minorNodes;
  }
  return $this->{_minorNodes};
}

=pod

=head1 AUTHOR

Copyright 1999-2003 Dagobert Michelsen.

=head1 SEE ALSO

L<libdevinfo(3devinfo)>, L<libdevinfo(3lib)>,
L<Solaris::DeviceTree::Libdevinfo::MinorNode>,
L<Solaris::DeviceTree::Libdevinfo::Property>,
L<Solaris::DeviceTree::Libdevinfo::PromProperty>.

=cut

1;
