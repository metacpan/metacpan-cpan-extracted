#
# $Header: /cvsroot/devicetool/Solaris-DeviceTree/lib/Solaris/DeviceTree/Overlay.pm,v 1.4 2003/12/12 11:11:55 honkbude Exp $
#

package Solaris::DeviceTree::Overlay;

use 5.006;
use strict;
use warnings;

our @ISA = qw( Solaris::DeviceTree::Node );
our $VERSION = do { my @r = (q$Revision: 1.4 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

use Carp;
use English;
use Solaris::DeviceTree::Node;
use Solaris::DeviceTree::Overlay::MinorNode;

use Data::Dumper;

=pod

=head1 NAME

Solaris::DeviceTree::Overlay - Unification of multiple devicetrees

=head1 SYNOPSIS

  use Solaris::DeviceTree::Overlay

Construction and destruction:

  $devtree = Solaris::DeviceTree::Overlay->new( sources => { 'src1' => $tree1, ... } )

Tree traversal:

  @children = $devtree->child_nodes
  @siblings = $devtree->sibling_nodes
  $node = $node->parent_node
  $root = $node->root_node

Methods concerning tree merging:

  @sources = $node->sources

Data access methods:

  $path = $node->devfs_path
  $instance = $devtree->instance
  $id = $node->nodeid
  @compat_names = $devtree->compatible_names
  ...

=head1 DESCRIPTION

The L<Solaris::DeviceTree::Overlay> module implements the L<Solaris::DeviceTree::Node>
interface to access the Solaris device tree in a unified view from multiple data sources.
Each data source must implement the L<Solaris::DeviceTree::Node> interface.
As a general goal the unification checks that the values of all data source comply
with each other.
The method used to unify the information depends on the type of the returned value:

=over 4

=item Scalars

A defined scalar precedes an undefined scalar silently.
Two defined scalars with the same value are merged together silently.
Two defined scalars with different values issue a warning and the value
of the first data source is used.

=item Arrays

Currently only the array from the first defined source is used.

=item Hashes

Currently only the hash from the first defined source is used.

=item Properties and PROM Properties

Properties and PROM properties from all source are merged together by name.
If two sources define the same property or PROM property
and have differing values a warning is issued and the first value
is used.

=item Minor Nodes

Minor nodes from all sources are merged together by name.
If two sources define the same minor node and the values for
the attributes of the minor nodes differ a warning is issued
and the first value is used. 

=item 

=back 4

=head1 METHODS

The following methods are available:

=head2 new

The constructor returns a reference to a L<Solaris::DeviceTree::Overlay> object which
itself implements the L<Solaris::DeviceTree::Node> interface. The instance returned
represents the root-node of the devicetree. 

  $devtree = Solaris::DeviceTree::Overlay->new(
    sources => { 'libdevinfo' => $libdevinfotree, 'pti' => $pathtoinsttree } ]
  );

=cut

sub new {
  my ($pkg, %params) = @_;

  my %sources;
  if( !exists $params{sources} ) {
    croak "Mandatory option 'sources' not defined.\n";
  }
  if( ref( $params{sources} ) ne "HASH" ) {
    croak "Mandatory option 'sources' must be a reference to a hash array instead of a " .
      ref( $params{sources} ) . ".\n";
  }

  my $this = $pkg->_new_node();
  $this->{_sources} = $params{sources};
  $this->{_child_initialized} = 0;

  return $this;
}

=pod

=head2 DESTROY

This methos removes all internal data structures which are associated
with this object.

=cut

sub DESTROY {
  # This does currently not do much (read: nothing)
  my $this = shift;
}

=pod

=head2 child_nodes

This method returns a list with the objects of the children for
all data sources. The nodes are merged using the nodename and the busaddress
as key.

Example:

  @children = $devtree->child_nodes

=cut

sub child_nodes {
  my ($this, %options) = @_;

  if( !$this->{_child_initialized} ) {
    my %child_nodes;
    foreach my $source (keys %{$this->{_sources}}) {
      my @source_child_nodes = $this->{_sources}->{$source}->child_nodes;
      foreach my $child (@source_child_nodes) {
        my $nodeid = $child->node_name;
        $nodeid .= "@" . $child->bus_addr if( defined $child->bus_addr && $child->bus_addr ne "" );
        $child_nodes{$nodeid}->{$source} = $child;
      }
    }
  
    foreach my $nodeid (keys %child_nodes) {
      my $child_node = $this->_new_node( parent => $this );
      $child_node->{_sources} = $child_nodes{$nodeid};
    }
    $this->{_child_initialized} = 1;
  }
  return $this->SUPER::child_nodes( %options );
}

=pod

=head2 sources

This method returns a list containing the names of all data sources
which were used to build this node.

Example:

  @sources = $node->sources

=cut

sub sources {
  my ($this, %options) = @_;

  return keys %{$this->{_sources}};
}

=pod

=head2 parent_node

Returns the parent node for the object. If the object is toplevel,
then C<undef> is returned.

Example:

  $node = $devtree->parent_node

=cut

# This is inherited from ::Node

=pod

=head2 root_node

Returns the root node of the tree.

Example:

  $node = $devtree->root_node

=cut

# This is inherited from ::Node

=pod

=head2 sibling_nodes

Returns the list of siblings for the object. A sibling is a child
from our parent, but not ourselves.

Example:

  @siblings = $devtree->sibling_nodes

=cut

# This is inherited from ::Node

=pod

=head2 devfs_path

Returns the physical path assocatiated with this node.

Example:

  $path = $devtree->devfs_path

=cut

# -> TODO: Include features to select specific sources,
#          avoid sanity checks, list available sources etc.

BEGIN {

for my $scalar_method (qw( devfs_path node_name binding_name instance bus_addr driver_name nodeid controller target lun slice )) {
  eval qq{
    sub $scalar_method {
      my (\$this, \%params) = \@_;
    
      my \$$scalar_method;
    
      # Unify information from all sources
      my \$selected_source;
      foreach my \$source (keys \%{\$this->{_sources}}) {
#print "Source: \$source\\n";
        my \$source_${scalar_method} = \$this->{_sources}->{\$source}->$scalar_method;
#print "P: \$source_${scalar_method}\\n";
        if( !defined \$$scalar_method ) {
          \$$scalar_method = \$source_${scalar_method};
          \$selected_source = \$source;
        } else {
          if( defined \$$scalar_method && defined \$source_${scalar_method} &&
              \$$scalar_method ne \$source_${scalar_method} ) {
            warn "Differing values for $scalar_method:\\n" .
              "  \$source: " . \$source_${scalar_method} . "\\n" .
              "  \$selected_source: " . \$$scalar_method . "\\n";
          }
        }
          
      }
      \$$scalar_method;
    }
  };
}
}

sub compatible_names {
  my ($this) = @_;

  if( !exists $this->{_compatible_names} ) {
    my @compatible_names;
    my $selected_source = undef;
    foreach my $source (keys %{$this->{_sources}}) {
      my @cnames = $this->{_sources}->{$source}->compatible_names;
      next if( !@cnames );
      if( defined $selected_source ) {
        warn "Differing values for compatible_names:\n" .
          "  $source: " . join( " ", @compatible_names ) . "\n" .
          "  $selected_source: " . join( " ", @cnames ) . "\n";
      } else {
        @compatible_names = @cnames;
        $selected_source = $source;
      }
    }
    $this->{_compatible_names} = \@compatible_names;
  }

  return @{$this->{_compatible_names}};
}

sub driver_ops {
  my ($this) = @_;
  foreach my $source (keys %{$this->{_sources}}) {
    my %driver_ops = $this->{_sources}->{$source}->driver_ops;
    return %driver_ops if( %driver_ops );
  }
  return ();
}

sub state {
  my ($this) = @_;
  foreach my $source (keys %{$this->{_sources}}) {
    my %state = $this->{_sources}->{$source}->state;
    return %state if( %state );
  }
  return ();
}

=pod

=head2 nodeid

Returns the type of the node. Three different strings identifying
the types can be returned or C<undef> if the type is unknown:

  PSEUDO
  SID
  PROM

Nodes of the type C<PROM> may have additional prom properties that
are defined by the PROM. The properties can be accessed with
L<prom_props>.

Example:

  $id = $node->nodeid

=cut

sub props {
  my ($this, %options) = @_;

  if( !exists $this->{_props} ) {
    my $old_source;
    foreach my $source (keys %{$this->{_sources}}) {
      my $props = $this->{_sources}->{$source}->props;
      if( defined $props ) {
        if( defined $this->{_props} ) {
          warn "Differing values for properties from sources $source and $old_source.\n";
        } else {
          $this->{_props} = $props;
          $old_source = $source;
        }
      }
    }
  }

  return $this->{_props};
}

sub prom_props {
  my ($this, %options) = @_;

  if( !exists $this->{_prom_props} ) {
    my $old_source;
    foreach my $source (keys %{$this->{_sources}}) {
      my $prom_props = $this->{_sources}->{$source}->prom_props;
      if( defined $prom_props ) {
        if( defined $this->{_prom_props} ) {
          warn "Differing values for prom_properties from sources $source and $old_source.\n";
        } else {
          $this->{_prom_props} = $prom_props;
          $old_source = $source;
        }
      }
    }
  }

  return $this->{_prom_props};
}

=pod

=head2 node_name

Returns the name of the node.

Example:

  $nodename = $devtree->node_name

=head2 binding_name

Returns the binding name for this node. The binding name
is the name used by the system to select a driver for the device.

Example:

  $bindingname = $devtree->binding_name

=head2 bus_addr

Returns the address on the bus for this node. C<undef> is returned
if a bus address has not been assigned to the device. A zero-length
string may be returned and is considered a valid bus address.

Example:

  $busadr = $devtree->bus_addr

=head2 instance

Returns the instance number of the driver bound to the node. If no driver
is bound to the node C<undef> is returned.

Example:

  $instance = $devtree->instance

=head2 compatible_names

Returns the list of names from compatible device for the current node.
See the discussion of generic names in L<Writing  Device Drivers> for
a description of how compatible names are used by Solaris to achieve
driver binding for the node.

Example:

  @compat_names = $devtree->compatible_names

=head2 driver_name

Returns the name of the driver for the node or C<undef> if the node
is not bound to any driver.

Example:

  $drivername = $devtree->driver_name

=head2 minor_nodes

Returns a reference to a list of all minor nodes which are associated with this node.
The minor nodes are of class L<Solaris::DeviceTree::Overlay::MinorNode>.

Example:

  @minor = @{$node->minor_nodes}

=cut

sub minor_nodes {
  my ($this, %options) = @_;

  if( !exists $this->{_minor_nodes} ) {
    # Unify information from all sources
    my %minor_nodes;
    my %minor_node_sources;
    foreach my $source (keys %{$this->{_sources}}) {
      my $mlist = $this->{_sources}->{$source}->minor_nodes;
      $mlist ||= [];
      foreach my $minor_node (@$mlist) {
        $minor_nodes{$minor_node->name} ||= 
          Solaris::DeviceTree::Overlay::MinorNode->new(
            node => $this,
            name => $minor_node->name,
          );
        my $m = $minor_nodes{$minor_node->name};

        my ($d, $e) = $minor_node->devt;
        if( defined $d || defined $e ) {
          my ($a, $b) = $m->devt;
          if( defined $a || defined $b ) {
            my ($major, $minor) = $m->devt;
            my ($major2, $minor2) = $minor_node->devt;
            if( $major != $major2 || $minor != $minor2 ) {
              carp "Differing values for major and minor:\n" .
                "  " . $minor_node_sources{$minor_node->name}{devt} . ": (" . $major . "," . $minor . ")\n" .
                "  " . $source . ": (" . $major2 . "," . $minor2 . ")\n";
            }
          } else {
            $m->{_major} = $d;
            $m->{_minor} = $e;
            $minor_node_sources{$minor_node->name}{devt} = $source,
          }
        }
        if( defined $minor_node->nodetype ) {
          if( defined $m->nodetype ) {
            if( $minor_node->nodetype ne $m->nodetype ) {
              carp "Differing values for nodetype:\n" .
                "  " . $minor_node_sources{$minor_node->name}{nodetype} . ": " . $m->nodetype . "\n" .
                "  " . $source . ": " . $minor_node->nodetype . "\n";
            }
          } else {
            $m->{_nodetype} = $minor_node->nodetype;
            $minor_node_sources{$minor_node->name}{nodetype} = $source,
          }
        }
#print "spec0\n";
        if( defined $minor_node->spectype ) {
#print "spec1\n";
          if( defined $m->spectype ) {
            if( $minor_node->spectype ne $m->spectype ) {
              carp "Differing values for spectype:\n" .
                "  " . $minor_node_sources{$minor_node->name}{nodetype} . ": " . $m->nodetype . "\n" .
                "  " . $source . ": " . $minor_node->nodetype . "\n";
            }
          } else {
            $m->{_nodetype} = $minor_node->nodetype;
            $minor_node_sources{$minor_node->name}{nodetype} = $source,
          }
        }
#print "spec0\n";
        if( defined $minor_node->spectype ) {
#print "spec1\n";
          if( defined $m->spectype ) {
            if( $minor_node->spectype ne $m->spectype ) {
              carp "Differing values for spectype:\n" .
                "  " . $minor_node_sources{$minor_node->name}{spectype} . ": " . $m->spectype . "\n" .
                "  $source: " . $minor_node->spectype . "\n";
            }
          } else {
#print "Setting spectype for $source to ", $minor_node->spectype, "\n";
            $m->{_spectype} = $minor_node->spectype;
            $minor_node_sources{$minor_node->name}{spectype} = $source,
          }
        }
      }
    }
    $this->{_minor_nodes} = [ values %minor_nodes ];
# print Dumper( $this->{_minor_nodes} );
  }

  return $this->{_minor_nodes};
}

=pod 

=head1 EXAMPLES

=head2 Print the device pathes contained in the C</etc/path_to_inst>

  use Solaris::DeviceTree;

  my $t = Solaris::DeviceTree->new( use => [ qw( path_to_inst ) ] );
  my @nodes = ( $t );
  while( @nodes > 0 ) {
    my $node = shift @nodes;
    print $node->devfs_path, "\n";
    unshift @nodes, $node->child_nodes;
  }

=head1 AUTHOR

Copyright 1999-2003 Dagobert Michelsen.


=head1 SEE ALSO

L<Solaris::DeviceTree::PathToInst>, L<Solaris::DeviceTree::Filesystem>,
L<Solaris::DeviceTree::Libdevinfo>.

=cut

1;
