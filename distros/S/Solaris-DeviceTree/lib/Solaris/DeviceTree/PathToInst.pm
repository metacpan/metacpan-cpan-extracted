#
# $Header: /cvsroot/devicetool/Solaris-DeviceTree/lib/Solaris/DeviceTree/PathToInst.pm,v 1.6 2003/12/09 13:04:36 honkbude Exp $
#

package Solaris::DeviceTree::PathToInst;

use 5.006;
use strict;
use warnings;
use Carp;
use English;

use Data::Dumper;

require Exporter;
our %EXPORT_TAGS = ( 'all' => [ qw() ], );
our @EXPORT = ( @{ $EXPORT_TAGS{'all'} } );

use base qw( Exporter );
our $VERSION = do { my @r = (q$Revision: 1.6 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

our @ISA = qw( Solaris::DeviceTree::Node );
our $_ROOT_NODE;

use Solaris::DeviceTree::Node;

=pod

=head1 NAME

Solaris::DeviceTree::PathToInst - Perl interface to /etc/path_to_inst

=head1 SYNOPSIS

  use Solaris::DeviceTree::PathToInst;
  $tree = new Solaris::DeviceTree::PathToInst;
  $tree = new Solaris::DeviceTree::PathToInst( filename => '/a/etc/path_to_inst' );
  $root = $node->root_node;
  $path = $node->devfs_path;
  $nodename = $node->node_name;
  $busaddr = $node->bus_addr;
  $instance = $node->instance;
  $drivername = $node->driver_name;

=head1 DESCRIPTION

This module implements the L<Solaris::DeviceTree::Node> interface and
allows access to the Solaris driver configuration file C</etc/path_to_inst> via a hierarchical
tree structure. The API of this class overwrites methods from the
base class applicable to this context.

A line in the C<path_to_inst> looks like this:

  "<devfs_path>" <instance> "<driver_name>"

The C<devfs_path> is build out of the components

  <node_name>@<bus_addr>/<node_name>@<bus_addr>/...

and it is split at the C</> to build the node hierarchy.

=head1 METHODS

The following methods are available:

=head2 new

The constructor takes an optional named option C<filename> to
a location of a C<path_to_inst> file and returns a reference to the root node object.
If no filename is given the file from the running system at C</etc/path_to_inst> is used.

=cut

sub new {
  my ($pkg, %params) = @_;

  $params{filename} ||= '/etc/path_to_inst';

  if( !defined $_ROOT_NODE ) {
    # -> TODO: Localizing filehandles
    open PTI, $params{filename} || croak "Could not open " . $params{filename}. "\n";

    $_ROOT_NODE = $pkg->_new_node;
    $_ROOT_NODE->{_file} = $params{filename},
    $_ROOT_NODE->{_physical_name} = undef;
    $_ROOT_NODE->{_instance_number} = undef;

    while( <PTI> ) {
      chomp;
      s/#.*//;		# strip comments
      next if /^$/;	# skip empty lines

      # According to path_to_inst(4) a line looks like this:
      #   "physical name" instance number "driver name"
      my ($physical_name, $instance_number, $driver_name) =
        /^"([^"]+)"\s+(\d+)\s+"([^"]+)"$/;

      my @path_components = split( m!/!, $physical_name );

      # All physical names are absolute. Get rid of the first empty entry
      shift @path_components;

      $_ROOT_NODE->_insert( physical_path => $physical_name,
        path_components => \@path_components,
        instance => $instance_number, driver => $driver_name );
    }
    close PTI;

  }
  return $_ROOT_NODE;
}

# Special constructor for internal nodes
sub _new_child {
  my ($parent, %params) = @_;

  if( defined $parent && !defined ref( $parent ) ) {
    croak "The specified parent must be an object.";
  }
  my $this = $parent->_new_node( parent => $parent );
  $this->{_physical_name} = $params{physical_name};
  $this->{_node_name} = $params{node_name};
  $this->{_instance_number} = $params{instance_number};
  $this->{_bus_addr} = $params{bus_addr};

#print "_new_child: ", $params{physical_name} || "", " ", $params{node_name} || "", " ", $params{bus_addr} || "", "\n";
  return $this;
}

# This internal method inserts the node specified by the components in
# 'physical_path' with the attributes 'instance' and 'driver' as child
# for the given object.
sub _insert {
  my ($this, %params) = @_;

  my @path_components = @{$params{path_components}};
  my $physical_path = $params{physical_path};
  my $instance = $params{instance};
  my $driver = $params{driver};

  # $component is the node from the argument processed now
  my $component = shift @path_components;
  my ($node_name, $bus_addr) = ($component =~ /^([^@]*)(?:@(.*))?$/);

  # Find the node in the devicetree being processed
  my $node;
  foreach my $child (@{$this->{_child_nodes}}) {
    if( $child->{_node_name} eq $node_name &&
        $child->{_bus_addr} eq $bus_addr ) {
      $node = $child;
      last;
    }
  }
  if( !defined $node ) {
    # The node was not found. Generate it.
    $node = $this->_new_child( node_name => $node_name, bus_addr => $bus_addr );
  }

  if( @path_components > 0 ) {
    # There are still components in the path. Traverse further.
    $node->_insert( physical_path => $physical_path,
      path_components => \@path_components,
      instance => $instance, driver => $driver );
  } else {
    # We have found the final node. Set the attributes accordingly.
    $node->{_physical_name} = $physical_path;
    $node->{_instance} = $instance;
    $node->{_driver_name} = $driver;
#print "Inserting: ", $physical_path || "", " ", $node_name || "", " ", $bus_addr || "", "\n";
  }
  $node;
}

=pod

=head2 root_node

Returns the root node of the tree.

=cut

# Overwrite method of base class
sub root_node {
  my $this = shift;

  # Since we have a singleton the same reference to the object is
  # always returned.
  return $_ROOT_NODE;
}

=pod

=head2 devfs_path

Returns the physical path assocatiated with this node.

=cut

sub devfs_path {
  my $this = shift;

  # Handle special case: root node has undefined physical name meaning '/'
  return $this->{_physical_name} || '/';
}

=pod

=head2 node_name

Returns the name of the node. The value is derived from the L</devfs_path>
path. It is undefined for the root node and guaranteed to be defined for all other nodes.

=pod

=cut

sub node_name {
  my $this = shift;
  return $this->{_node_name};
}

=pod

=head2 driver_name

Returns the driver name for the node.

=cut

sub driver_name {
  my $this = shift;
  return $this->{_driver_name};
}

=pod

=head2 bus_addr

Returns the address on the bus for this node. C<undef> is returned
if a bus address has not been assigned to the device. A zero-length
string may be returned and is considered a valid bus address.

=cut

sub bus_addr {
  my $this = shift;
  return $this->{_bus_addr};
}

=pod

=head2 instance

Returns the instance number for this node of the bound driver.
C<undef> is returned if no instance number has been assigned.

=cut

sub instance {
  my $this = shift;
  return $this->{_instance};
}


=pod

=head1 AUTHOR

Copyright 1999-2003 Dagobert Michelsen.


=head1 SEE ALSO

L<Solaris::DeviceTree>, L<Solaris::DeviceTree::Node>, L<path_to_inst(4)>.

=cut

1;
