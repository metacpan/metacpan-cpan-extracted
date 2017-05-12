#
# $Header: /cvsroot/devicetool/Solaris-DeviceTree/lib/Solaris/DeviceTree/Node.pm,v 1.10 2003/12/12 11:11:55 honkbude Exp $
#

package Solaris::DeviceTree::Node;

use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = do { my @r = (q$Revision: 1.10 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

=pod

=head1 NAME

Solaris::DeviceTree::Node - Abstract base class for all device nodes

=head1 DESCRIPTION

This class acts as an abstract base class for subclasses of L<Solaris::DeviceTree>
to provide methods of general use returning default values for attributes and properties
for nodes and supply tree traversal and searching methods.
It should not be necessary to instantiate objects of this class directly.

=head1 SYNOPSIS

Tree traversal:

  $parent = $node->parent_node
  @childs = $node->child_nodes
  $root = $node->root_node
  @siblings = $node->sibling_nodes

Value access:

  $path = $node->devfs_path
  $nodename = $node->node_name
  $bindingname = $node->binding_name
  $drivername = $node->driver_name
  $busaddr = $node->bus_addr
  $instance = $node->instance
  @compat = $node->compatible_names
  %ops = $node->driver_ops
  if( $node->is_pseudo_node ) ...
  if( $node->is_sid_node ) ...
  if( $node->is_prom_node ) ...
  $nodeid = $node->nodeid
  %state = $node->state
  $props = $node->props; $props->{'myprop'}->...
  $pprops = $node->prom_props; $pprops->{'mypprop'}->...
  $minors = $node->minor_nodes; $minors->[0]->...
  $ctrl = $node->controller
  $target = $node->target
  $lun = $node->lun
  $slice = $node->slice
  $rmt = $node->rmt

Derived value access:

  $prop = $node->find_prop( devfs_path => '/aliases', prop_name => 'disk' )
  $solaris_path = $node->solaris_path

Node type detection:

  if( $node->is_network_node ) ...
  if( $node->is_block_node ) ...
  if( $node->is_controller_node ) ...

Node selection:

  @network_nodes = $node->network_nodes
  @block_nodes = $node->block_nodes
  @controller_nodes = $node->controller_nodes

  $node = $node->find_nodes( devfs_path => '/pci@1f,0/pci@1f,2000' );
  @nodes = $node->find_nodes( func => sub { $_->is_network_node } );


=cut

# This constructor is called from classes implementing the node interface.
sub _new_node {
  my ($class, %params) = @_;

  my $parent = $params{parent};

  my $this = bless {
    _parent => $parent,
    _child_nodes => [],
  }, ref( $class ) || $class;

  if( defined $parent ) {
    push @{$parent->{_child_nodes}}, $this;
  }

  return $this;
}

=pod

=head1 METHODS

The following methods are available:

=head2 parent_node

Returns the parent node for this node. If this is the root
node C<undef> is returned.

=cut

sub parent_node {
  my $this = shift;
  return $this->{_parent};
}

=pod

=head2 child_nodes

This method returns a list with all children.

=cut

sub child_nodes {
  my ($this, %options) = @_;

  return @{$this->{_child_nodes}};
}

=pod

=head2 root_node

Returns the root node of the tree.

=cut

sub root_node {
  my $this = shift;

  my $root = $this;
  while( defined $root->parent_node ) {
    $root = $root->parent_node;
  }
  return $root;
}

=pod

=head2 sibling_nodes

Returns the list of siblings for this object. A sibling is a child
from our parent, but not ourselves.

=cut

sub sibling_nodes {
  my $this = shift;

  my $parent = $this->parent_node;

  # Read all siblings including $this
  my @siblings = defined $parent ? $parent->child_nodes : ();

  # Strip out current node
  @siblings = grep { $_ ne $this } @siblings;

  return @siblings;
}

=pod

=head2 devfs_path

Returns the physical path assocatiated with this node.
Default is C<undef>.

=cut

sub devfs_path { return undef; }

=pod

=head2 node_name

Returns the name of the node used in the pysical path.
Default is C<undef>.

=pod

=cut

sub node_name { return undef; }

=pod

=head2 binding_name

Returns the binding name of the driver for the node.
Default is C<undef>.

=cut

sub binding_name { return undef; }

=pod

=head2 driver_name

Returns the driver name for the node.
Default is C<undef>.

=cut

sub driver_name { return undef; }

=pod

=head2 bus_addr

Returns the address on the bus for this node.
Default is C<undef>.

=cut

sub bus_addr { return undef; }

=pod

=head2 instance

Returns the instance number of the bound driver for this node.
Default is C<undef>.

=cut

sub instance { return undef; }

=pod

=head2 compatible_names

Returns the list of device which are compatible to this node.
Default is the empty list.

=cut

sub compatible_names { return (); }

=pod

=head2 driver_ops

Returns a hash which keys indicate which driver entry points are
supported by the driver bound to this node.
This is done to allow writing of something like C<if( exists $ops{'STREAM'} ) ...>.
Default is the empty list.

=cut

sub driver_ops { return (); }

=pod

=head2 is_pseudo_node
=head2 is_sid_node
=head2 is_prom_node

Returns C<true> if this is a pseudo / SID / PROM node.
The default is C<false>.

=cut

sub is_pseudo_node { return undef; }
sub is_sid_node { return undef; }
sub is_prom_node { return undef; }

=head2 nodeid

Returns the type of the node differing between pseudo, SID, etc.
Default is C<undef>.

=cut

sub nodeid { return undef; }

=head2 state

Returns a hash which keys indicate the state in which the bound driver is.
Default is the empty list.

=cut

sub state { return (); }

=pod

=head2 props

Returns a reference to the properties associated with this node.
Default is C<undef>.

=cut

sub props { return undef; }

=pod

=head2 prom_props

Returns a reference to the PROM properties associated with this node.
Default is C<undef>.

=cut

sub prom_props { return undef; }

=pod

=head2 minor_nodes

Returns a reference to a list containing the minor nodes associated to this node.
Default is C<undef>.

=cut

sub minor_nodes { return undef; }


=head2 solaris_device

This method returns the name of the associated Solaris device. This is currently something like

  c0t0d0s0   for a disk device
  hme0       for a network device

or C<undef> if no corresponding Solaris device could be found.

=cut

sub solaris_device {
  my $this = shift;

  my $solaris_device = undef;

  if( $this->is_controller_node ) {
    $solaris_device = 'c' . $this->controller if( defined $this->controller );
  } elsif( $this->is_block_node ) {
    $solaris_device = '';
    my $ctrl_node = $this;
    while( !defined $ctrl_node->controller && defined $ctrl_node->parent_node ) {
      $ctrl_node = $ctrl_node->parent_node;
    }
    $solaris_device .= 'c' . $ctrl_node->controller if( defined $ctrl_node->controller );
    $solaris_device .= 't' . $this->target if( defined $this->target );
    $solaris_device .= 'd' . $this->lun if( defined $this->lun );
  } elsif( $this->is_network_node ) {
    $solaris_device = $this->driver_name . $this->instance;
#  } elsif( $this->is_tape_node ) {
#    # -> TODO: Better heuristics, map /dev/rmt and stuff
#    $solaris_device = $this->driver_name . $this->instance;
  }

  $solaris_device;
}


=pod

=head2 controller

Returns the controller number which is associated to this node.
Default is C<undef>.

=cut

sub controller {
  my ($this, %args) = @_;

  if( exists $args{_controller} ) {
    $this->{_controller} = $args{_controller};
  }
  return (exists $this->{_controller} ? $this->{_controller} : undef);
}

=pod

=head2 target

Returns the target number which is associated to this node.
Default is C<undef>.

=cut

sub target {
  my ($this, %args) = @_;

  if( exists $args{_target} ) {
    $this->{_target} = $args{_target};
  }
  return (exists $this->{_target} ? $this->{_target} : undef);
}

=pod

=head2 lun

Returns the logical unit number which is associated to this node.
Default is C<undef>.

=cut

sub lun {
  my ($this, %args) = @_;

  if( exists $args{_lun} ) {
    $this->{_lun} = $args{_lun};
  }
  return (exists $this->{_lun} ? $this->{_lun} : undef);
}

=pod

=head2 slice

Returns the slice number which is associated to this node.
Default is C<undef>.

=cut

sub slice {
  my ($this, %args) = @_;

  if( exists $args{_slice} ) {
    $this->{_slice} = $args{_slice};
  }
  return (exists $this->{_slice} ? $this->{_slice} : undef);
}

=pod

=head2 rmt

Returns the tape number which is associated to this node.
Default is C<undef>.

=cut

sub rmt {
  my ($this, %args) = @_;

  if( exists $args{_rmt} ) {
    $this->{_rmt} = $args{_rmt};
  }
  return (exists $this->{_rmt} ? $this->{_rmt} : undef);
}

=pod

=head2 is_network_node

This method returns true if the node represents a network card.

=cut

sub is_network_node {
  my ($this) = @_;

  my $is_network_node = undef;

  # Check properties if we have any
  my $prom_prop = $this->prom_props;
  if( defined $prom_prop ) {
    my $device_prop = $prom_prop->{device_type};
    if( defined $device_prop ) {
      $is_network_node = $device_prop->string eq 'network';
    }
  }

  if( !defined $is_network_node ) {
    # Use driver names to check if it is a network component. However, this list
    # might be updated, so return undef (=don't know) else.
    my @known_network_drivers = ( qw( tr le qe hme eri dmfe qfe ge bge ce ) );
    my %known; @known{@known_network_drivers} = (1 x scalar @known_network_drivers);
  
    my $driver_name = $this->driver_name;
    $is_network_node = (defined $driver_name && exists $known{$driver_name});
  }

  return $is_network_node;
}

=pod

=head2 is_block_node

This method returns true if the node represents a block device
(which is essentially a disk).

=cut

sub is_block_node {
  my ($this) = @_;

  my $is_block_node = undef;

  # Check properties if we have any
  my $prom_prop = $this->prom_props;
  if( defined $prom_prop ) {
    my $device_prop = $prom_prop->{device_type};
    if( defined $device_prop ) {
      # If we don't have a bus address or instance than it is a transfer node
      # from the prom.
      $is_block_node = ( ($device_prop->string eq 'block') &&
                         (defined $this->bus_addr || defined $this->instance) );
    }
  }

  # -> TODO: Check for PSEUDO nodes which are mapped through transfer nodes.
  # Skip the next test for testing purposes

  if( !defined $is_block_node ) {
    # Use driver names to check if it is a block driver. However, this list
    # might be updated, so return undef (=don't know) else.
    my @known_block_drivers = ( qw( sd ssd dad ) );
    my %known; @known{@known_block_drivers} = (1 x scalar @known_block_drivers);
  
    my $driver_name = $this->driver_name;
    $is_block_node = (defined $driver_name && exists $known{$driver_name});
  }
  
  return $is_block_node;
}

=pod

=head2 is_controller_node

This method returns true if the node represents a controller device.

=cut

sub is_controller_node {
  my ($this) = @_;

  # when we already have an assigned controller number we definitely have a controller
  if( defined $this->controller ) {
    return 1;
  }

  # -> TODO: Do PROM property analytics and driver class checking for further detection

  return undef;
}


sub is_tape_node {
}

=pod

=head2 network_nodes

This method returns all nodes for network cards in the tree.

=cut

sub network_nodes {
  my ($this) = @_;

  my @nodes = $this->find_nodes( func => sub { $_->is_network_node } );
  return @nodes;
}

=pod

=head2 block_nodes

This method returns all nodes for disks in the tree.

=cut

sub block_nodes {
  my ($this) = @_;

  my @nodes = $this->find_nodes( func => sub { $_->is_block_node } );
  return @nodes;
}

=pod

=head2 controller_nodes

This method returns all nodes for controller devices.

=cut

sub controller_nodes {
  my ($this) = @_;

  my @nodes = $this->find_nodes( func => sub { $_->is_controller_node } );
  return @nodes;
}

# -- Special search methods --

=pod

=head2 find_nodes

This method returns nodes matching certain criteria. Currently it is
possible to match against a physical path or to specify a subroutine
where the node is returned if the subroutine returns true. As in
Perl L<grep> C<$_> is locally bound to the node being checked.

In a scalar context the method returns only the first node found.
In an array context the method returns all matching nodes.

Examples:

  $node = $node->find_nodes( devfs_path => '/pci@1f,0/pci@1f,2000' );
  @nodes = $node->find_nodes( func => sub { $_->is_network_node } );

=cut

# -> TODO: Wildcard matching

sub find_nodes {
  my ($this, %options) = @_;

  my @result = ($this);

  foreach my $name (keys %options) {
    if( $name eq 'func' ) {
      local $_ = $this;
      if( !$options{$name}->() ) {
        @result = ();
        last;
      }
    } elsif( $name eq 'devfs_path' ) {
      # -> TODO: This can be done more efficient when recursing is skipped
      # on wrong nodes.
      if( $options{$name} ne $this->devfs_path ) {
        @result = ();
        last;
      }
    # -> TODO: Do all properties here
    } else {
      warn "Unknown property '$name' at find_nodes.\n";
    }
  }

  if( scalar @result > 0 && !wantarray ) {
    # Only one node is requested. Take shortcut and return the newly
    # found node.
    return $this;
  }

  if( wantarray ) {
    # We want all results. Recurse down into the tree.
    return (@result, map { $_->find_nodes( %options ) } $this->child_nodes );
  } else {
    # This node wasn't right. Check all nodes and stop if we found one.
    my $result;
    foreach my $node ($this->child_nodes) {
      $result = $node->find_nodes( %options );
      last if( defined $result );
    }
    return $result;
  }
}

=pod

=head2 find_prop

This method picks a node by criteria from the devicetree and
then selects either a property or a prom property depending on the
options given. At least one of

  prop_name
  prom_prop_name

must be specified. All options valid for find_nodes are also applicable
to this method.

Example:

  $prop = $node->find_prop( devfs_path => '/aliases', prop_name => 'disk' )

=cut

# -> TODO: The return value should be formatted properly.
# -> TODO: Should this be extended to attributes?

sub find_prop {
  my ($this, %options) = @_;

  my %find_options = %options;
  delete $find_options{prop_name};
  delete $find_options{prom_prop_name};
  my $node = $this->find_nodes( %find_options );

  if( exists $options{prop_name} ) {
    my $prop_name = $options{prop_name};
    my $props = $node->props;
    return exists $props->{$prop_name} ? $props->{$prop_name} : undef;
  } elsif( exists $options{prom_prop_name} ) {
    my $prom_prop_name = $options{prom_prop_name};
    my $prom_props = $node->prom_props;
    return exists $prom_props->{$prom_prop_name} ? $prom_props->{$prom_prop_name} : undef;
  } else {
    croak "Mandatory option 'prop_name' or 'prom_prop_name' not specified";
  }
}

=pod

=head2 find_minor_node( name => ':a' );

This method finds the minor node with the specified name.

=cut

sub find_minor_node {
  my ($this, %options) = @_;

  if( exists $options{name} ) {
    foreach my $minor (@{$this->minor_nodes}) {
      return $minor if( $minor->name eq $options{name} );
    }
  } else {
    croak "Mandatory option 'name' in find_minor_node is missing.";
  }
}

=pod

#=head2 prom_path
#
#This method converts between a Solaris device path and an OBP device path.
#
#The conversion is quite complex. As a first step the IOCTLS
#
#  OPROMDEV2PROMNAME (OIOC | 15)   /* Convert devfs path to prom path */
#  OPROMPROM2DEVNAME (OIOC | 16)   /* Convert prom path to devfs path */
#
#from the C<openeepr> driver accessed through C</dev/openprom> might be taken.
#However, some older machines are not aware of that. It would
#be optimal to use C<devfs_dev_to_prom_name> from L<libdevinfo(3devinfo)>, but that one is
#a static function and reprogramming that one is *not* fun.
#
#=cut

# This method takes an obp path in an OBP::Path object and returns a
# solaris path.
# In other words: a path containing only prom nodes is transformed to
# a path containing pseudo nodes.
#   $promPath is a reference to an OBP::Path::Component array
# This method returns an OBP::Path object. The returned object might or
# might not point to a node in the obp tree.
sub solaris_path {
  my ($this, $promPath) = @_;
  $promPath = new OBP::Path( string => $promPath ) if( !ref( $promPath ) );
  return $promPath if( @{$promPath->components} == 0 );

  my $pc;	# leftmost path component, the one to check against
  $pc = shift @{$promPath->components};

#print "Matching ", $pc->string, " ", $this->devfsPath, "\n";
  my @children = $this->children(
    nodename => $pc->node, busaddress => $pc->busaddress );
  if( @children == 0 ) {
    # no direct match found
    # Check if we have a transfer node.

    # The mapping might or might not lead to different pathes.
    # Examples:
    #   Ultra 10   IDE disk:    disk -> dad
    #              ATAPI cdrom: cdrom -> sd
    #              SCSI disk:   disk -> sd
    #   Ultra 1:   SCSI disk:   sd -> sd
    @children = $this->children(
      nodename => $pc->node, busaddr => undef, instance => undef );
    if( @children == 0 ) {
      # No transfer node found. Because we can't find the next node in the
      # device tree we guess that the path stays the same and return what we have. 
      return new OBP::Path( components => [ $pc, @{$promPath->components} ] );
    } elsif( @children == 1 ) {
      # we found the transfer node. Continue with the node specified in the
      # driverName attribute but leave the address and args (if any) the same.
      my $transferNode = $children[ 0 ];
      my @target = $this->children(
        nodename => $transferNode->driverName, busaddress => $pc->busaddress );
      if( @target == 0 ) {
        # We have a transfer node but no node to continue. Return the corrected
        # node and leave the rest as is.
        return new OBP::Path( components => [
          new OBP::Path::Component(
            node => $transferNode->driverName,
            adr => $pc->adr,
            subadr => $pc->subadr,
            arg => $pc->arg,
          ),
          @{$promPath->components}
        ] );
      } elsif( @target == 1 ) {
        # Everything fine. Prepend the found note after node transferal to
        # the result of the continued search.
        my $contnode = $target[ 0 ];
        return new OBP::Path( components => [
          new OBP::Path::Component( string => $contnode->nodeName . "@" . $contnode->busAddress . ( defined $pc->arg ? ':' . $pc->arg : '' ) ),
          @{$contnode->solarisPath( $promPath )->components}
        ] );
      } else {
        warn "Found more than one node after node transfer. This should not happen.";
      }
    } else {
      # This is a very ugly situation. We have a valid prefix and we don't
      # know yet how to continue correctly. Both might be valid Solaris pathes.
      # It is unfortunately possible (is it?) that one path can be continued
      # and the other can not. So all pathes should be tried and compared here.
      # -> TODO
      warn "  Found more than one transfer node:\n    " . 
        join( "\n    ", map { $_->devfsPath } @children ) . "\n";
      my $match = $children[ 0 ];
      return new OBP::Path( components => [ $pc, @{$match->solarisPath( $promPath )->components} ] );
    }
  } elsif( @children == 1 ) {
    # found exact match. Continue with the next node.
    my $match = $children[ 0 ];
    return new OBP::Path( components => [ $pc, @{$match->solarisPath( $promPath )->components} ] );
  } else {
    # -> TODO: Wildcard match
    warn "Wildcard match. Just taking the first match.";
    my $match = $children[ 0 ];
    return new OBP::Path( components => [ $pc, @{$match->solarisPath( $promPath )->components} ] );
  }
}

=pod

=head1 AUTHOR

Copyright 1999-2003 Dagobert Michelsen.


=head1 SEE ALSO

L<Solaris::DeviceTree::Libdevinfo>, L<Solaris::DeviceTree::PathToInst>,
L<Solaris::DeviceTree::Filesystem>,
L<eeprom(1m)>.

=cut

1;

