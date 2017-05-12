#
# $Header: /cvsroot/devicetool/Solaris-DeviceTree/lib/Solaris/DeviceTree/Filesystem.pm,v 1.10 2003/12/12 11:11:55 honkbude Exp $
#

package Solaris::DeviceTree::Filesystem;

use 5.006;
use strict;
use warnings;
use Carp;

our %EXPORT_TAGS = ( 'all' => [ qw() ], );
our @EXPORT = ( @{ $EXPORT_TAGS{'all'} } );

use base qw( Exporter );
our $VERSION = do { my @r = (q$Revision: 1.10 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

our @ISA = qw( Solaris::DeviceTree::Node );
our $_ROOT_NODE;

use Solaris::DeviceTree::Node;
use Solaris::DeviceTree::Filesystem::MinorNode;

=pod

=head1 NAME

Solaris::DeviceTree::Filesystem - Perl interface to C</dev> and C</devices>


=head1 SYNOPSIS

  use Solaris::DeviceTree::Filesystem;
  $tree = Solaris::DeviceTree::Filesystem->new;
  @children = $node->child_nodes;
  $devfs_path = $node->devfs_path;
  $node_name = $node->node_name;
  $bus_addr = $node->bus_addr;
  @minor_nodes = @{$node->minor_nodes}
  $instance = $node->instance;


=head1 DESCRIPTION

The L<Solaris::DeviceTree::Filesystem> module implements access to the
Solaris device configuration files below C</devices> via a hierarchical
tree structure. The API of this class contains all methods from
L<Solaris::DeviceTree::Node> applicable to this context.

Additionally, the information from C</dev/cfg>, C</dev/dsk>, C</dev/rdsk>
and C</dev/rmt> is used to identify controller numbers and recognize
disk- and tape-devices for instance calculation.

Each directory represents a node in the devicetree, each block or
character special file an associated minor node. Other types of files
are not allowed below C</devices>.
A name of a special file in the devicetree always has the form

  <node_name>@<bus_addr>:<device_arguments>

The bus address and the device arguments are optional.


=head1 METHODS

For a detailed description of the available methods and their meaning
see the documentation of the base class L<Solaris::DeviceTree::Node>.

The following methods returns values other than the defaults from
the base class:

=head2 new

This method contructs a new filesystem tree.

=cut

# -> TODO: It would be nice to allow other filesystem roots
#          (e. g. /a) for remote mounted filesystems

sub new {
  my ($pkg, %options) = @_;

  if( !defined $_ROOT_NODE ) {

    $_ROOT_NODE = $pkg->_new_node;
    $_ROOT_NODE->{_dir} = "/devices";
    $_ROOT_NODE->{_physical_name} = '';
    $_ROOT_NODE->{_minor_nodes} = [];
  }

  my %disks;

  {
    local *DIR;
    opendir DIR, '/dev/dsk';
    my @dsk = grep !/^\.\.?$/, readdir( DIR );
    @disks{ map { '/dev/dsk/' . $_ } @dsk } = @dsk;
    closedir DIR;

    opendir DIR, '/dev/rdsk';
    my @rdsk = grep !/^\.\.?$/, readdir( DIR );
    @disks{ map { '/dev/rdsk/' . $_ } @rdsk } = @rdsk;
    closedir DIR;
  }

  foreach my $disk (keys %disks) {
    my $devfs_path = readlink $disk;
    my ($c, $t, $d, $s) = ($disks{$disk} =~ /c(\d+)t(\d+)d(\d+)s(\d+)/);
    $devfs_path =~ s!^\.\./\.\./devices!!;
    my ($path, $minor) = ($devfs_path =~ /^([^:]+):(.*)$/);
    my $node = $_ROOT_NODE->find_nodes( devfs_path => $path );
    if( defined $node ) {
      my $parent = $node->parent_node;
      if( defined $parent ) {
        $parent->controller( _controller => $c );
      } else {
        warn "Parent node for the device path '${path}' for the disk " . 
          "'${disk}' could not be found.";
      }

      $node->target( _target => $t );
      $node->lun( _lun => $d );

      my $minor_node = $node->find_minor_node( name => $minor );
      if( defined $minor_node ) {
        $minor_node->slice( _slice => $s );
      } else {
        warn "The minor node '${minor}' for the device path " .
          "'${path}' for the disk " . 
          "'${disk}' could not be found.";
      }
    } else {
      warn "The device path '${path}' for the disk " . 
        "'${disk}' could not be found.";
    }
  }

  my @cfg;
  {
    # -> TODO: A real filehandle would be nicer
    local *DIR;
    opendir DIR, "/dev/cfg";
    @cfg = grep !/^\.\.?$/, readdir( DIR );
    closedir DIR;
  }

  foreach my $cfg (@cfg) {
    next if( $cfg =~ /^usb\d+$/ );	# USB busses are not handled right now -> TODO
    my $devfs_path = readlink "/dev/cfg/" . $cfg;
    if( !defined $devfs_path ) {
      warn "The file '/dev/cfg/${cfg}' is not a link. Skipping it.";
      next;
    }
    my ($c) = ($cfg =~ /c(\d+)/);
    if( !defined $c ) {
      warn "File with peculiar name '${cfg}' found below /dev/cfg.\n" .
        "The names should begin with 'c' and be followed by a number." .
        "Skipping it.";
      next;
    }

    my $ctrl_found = 0;

    $devfs_path =~ s!^\.\./\.\./devices!!;
    if( defined $devfs_path ) {
      my ($path, $minor) = ($devfs_path =~ /^([^:]+):(.*)$/);
      if( defined $path && defined $minor ) {
        my $node = $_ROOT_NODE->find_nodes( devfs_path => $path );
        if( defined $node ) {
          $node->controller( _controller => $c );
          $ctrl_found = 1;
        }
      }
    }
    if( !$ctrl_found ) {
      warn "The node for the device path '${devfs_path}' for the controller " . 
        "'c${c}' could not be found";
    }
  }

  return $_ROOT_NODE;
}

=pod

=head2 child_nodes

This methods returns the child nodes below this node.

=cut

sub child_nodes {
  my ($this, %options) = @_;

  if( !$this->{_child_initialized} ) {
    # Child nodes are created on demand for each node
    if( exists $this->{_dir} ) {
      my %child_nodes;
      local *DIR;
      opendir DIR, $this->{_dir};
      while( defined( my $file = readdir DIR ) ) {
        next if( $file =~ /^\.\.?$/ );
    
        my $filepath = $this->{_dir} . '/' . $file;
        if( !-d $filepath && !-b _ && !-c _ ) {
          warn "File $filepath is neiter a directory nor a block- or\n" .
            "character device and should not belong here!\n";
          next;
        }
  
        # We have now a valid node
        my ($physical_name, $node_name, $bus_addr, $device_arguments) =
          ($file =~ /^
            (						# physical name
              ([^\@:]*)					# node name
              (?:\@([^:]*))?				# bus addr
            )
            (?::(.*))?					# device arguments
            $/x);
  
        my $nodeid = $physical_name;
        if( !exists $child_nodes{$nodeid} ) {
          my $child = $this->_new_node( parent => $this );
          $child->{_physical_name} = $this->{_physical_name} . '/' . $physical_name;
          $child->{_node_name} = $node_name;
          $child->{_bus_addr} = $bus_addr;
          $child->{_minor_nodes} = [];
  
          $child_nodes{$nodeid} = $child;
        }
  
        my $child = $child_nodes{$nodeid};
        if( -d _ ) {
          $child->{_dir} = $filepath;
        }
  
        if( -b _ || -c _ ) {
          # Minor nodes
          my $minor_node = Solaris::DeviceTree::Filesystem::MinorNode->new(
            $filepath, $child );
          push @{$child->{_minor_nodes}}, $minor_node;
        }
      }
      closedir DIR;
    }
  
    $this->{_child_initialized} = 1;
  }

  return $this->SUPER::child_nodes( %options );
}

=pod

=head2 devfs_path

This method returns the physical path for this node.

=cut

sub devfs_path {
  my ($this, %options) = @_;

  # Handle special case for root node name
  return !defined $this->parent_node ? '/' : $this->{_physical_name};
}

=pod

=head2 node_name

This method returns the name of the node.
It is undefined for the root node and guaranteed to be defined for all other nodes.

=cut

sub node_name {
  my ($this, %options) = @_;

  return $this->{_node_name};
}

=pod

=head2 bus_addr

This method return the bus address of the node. The bus address may be undefined.

=cut

sub bus_addr {
  my ($this, %options) = @_;

  return $this->{_bus_addr};
}

=pod

=head2 minor_nodes

This method returns a reference to a list of the minor nodes associated
with this node. For a detailed description of the methods available
to access the returned minor nodes see L<Solaris::DeviceTree::Filesystem::MinorNode>.

=cut

sub minor_nodes {
  my ($this, %options) = @_;

  return $this->{_minor_nodes};
}

# - a disk is a device located below /dev/dsk, /dev/rdsk or one of following:
#     sd ssd
sub is_block_device {
  return 0;
}
# -> TODO

# - a tape is a device located below /dev/rmt or one of the following:
#     st
sub is_byte_device {
  return 0;
}

# Device types taken from 1275.pdf p. 26
#   display
#   block	hard disk	bootable
#   byte	tape		bootable
#   network	ethernet	bootable
#   serial

=pod

=head2 instance

This method returns the instance number of the driver for this node.
The instance number is calculated from the minor numbers of the
minor nodes for the used driver. The type of the calculation depends
on the implementation of the driver. If the mapping of minor numbers
to instances is not known in this method C<undef> is returned.
Currently C<undef> is returned for all minor numbers for all drivers.

=cut

# Instances can be guessed from the minor nodes. Lookup through
# /etc/name_to_major and hardwiring the driver usage seems
# necessary.

# -> TODO: Should is_disk_device also be implemented in this class?

sub instance {
  my ($this, %options) = @_;

  if( !exists $this->{_instance} ) {
    my $instance = undef;
    if( $this->is_block_device ) {
      foreach my $minor_node ($this->minor_nodes) {
        my ($major, $minor) = $minor_node->devt;
        $instance = int $minor / 8 if( !defined $instance );
      }
    } elsif( $this->is_byte_device ) {
      my $minor = 0;
      # From mtio.7i:
      #     15      7      6          5          4         3          2       1      0
      #     __________________________________________________________________________
      #      Unit #       BSD      Reserved   Density   Density   No rewind    Unit #
      #     Bits 7-15   behavior              Select    Select    on Close    Bits 0-1
      #
      #     /*
      #      * Layout of minor device byte:
      #      */
      #     #define MTUNIT(dev)     (((minor(dev) & 0xff80) >> 5) +(minor(dev) & 0x3))
      #     #define MT_NOREWIND     (1 <<2)
      #     #define MT_DENSITY_MASK (3 <<3)
      #     #define MT_DENSITY1     (0 <<3)         /* Lowest density/format */
      #     #define MT_DENSITY2     (1 <<3)
      #     #define MT_DENSITY3     (2 <<3)
      #     #define MT_DENSITY4     (3 <<3)         /* Highest density/format */
      #     #define MTMINOR(unit)   (((unit & 0x7fc) << 5) + (unit & 0x3))
      #     #define MT_BSD          (1 <<6)         /* BSD behavior on close */

      $instance = ($minor & 0xff80) >> 5 + ($minor & 3);
    }

    $this->{_instance} = $instance;
  }

  return $this->{_instance};
}

=pod

=head1 AUTHOR

Copyright 1999-2003 Dagobert Michelsen.


=head1 SEE ALSO

  L<Solaris::DeviceTree>, L<Solaris::DeviceTree::Filesystem::MinorNode>

=cut


1;
