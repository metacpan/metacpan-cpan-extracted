#
# $Header: /cvsroot/devicetool/Solaris-DeviceTree/lib/Solaris/DeviceTree/Overlay/MinorNode.pm,v 1.3 2003/12/12 11:11:55 honkbude Exp $
#

package Solaris::DeviceTree::Overlay::MinorNode;

use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = do { my @r = (q$Revision: 1.3 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

=pod

=head1 NAME

Solaris::DeviceTree::MinorNode - Generic minor node of the devicetree

=head1 SYNOPSIS

  use Solaris::DeviceTree;
  $tree = new Solaris::DeviceTree( uses => qw( libdevinfo filesystem ) );
  @disks = $tree->find_nodes( type => 'disk' );
  @minor = @disks->minor_nodes;


=head1 DESCRIPTION

This class implements generic minor nodes which are generated from
C<Solaris::DeviceTree>. The data from all configured data sources
containing minor nodes are unified through this class.
This is an internal class to C<Solaris::DeviceTree>. There should be
no need to generate instances of this class in an application explicitly.
Instances are generated only from C<Solaris::DeviceTree::minor_nodes()>.


=head1 METHODS

The following methods are available:

=cut

sub new {
  my ($pkg, %options) = @_;

  croak "No source node specified." if( !exists $options{node} );
  croak "No node name specified." if( !exists $options{name} );

  my $this = bless {
    _node => $options{node},
    _name => $options{name},
  }, ref( $pkg ) || $pkg;

  return $this;
}

=pod

=head3 $name = $minor->name;

Return the name of the minor node. This is used e.g. as suffix
of the device filename. For disks this is something like 'a' or
'a,raw'.

=cut

sub name {
  my $this = shift;
  return $this->{_name};
}

=pod

=head3 $path = $minor->devfs_path;

Return the complete physical path including the minor node

=cut

sub devfs_path {
  my $this = shift;
  return $this->node->devfs_path . ":" . $this->name;
}

=pod

=head3 ($majnum,$minnum) = $minor->devt;

Returns the major and minor device number as a pair for the node.
The major numbers should be the same for all minor nodes return
by a L<Solaris::DeviceTree::Libdevinfo> node.

=cut

sub devt {
  my $this = shift;
  return defined $this->{_major} || defined $this->{_minor} ?
    ($this->{_major}, $this->{_minor}) : undef;
}

=pod

=head3 $type = $minor->nodetype

Returns the nodetype of the minor node. Because we can't
find that out by looking at the filesystem we always return
'undef'.

=cut

sub nodetype {
  my $this = shift;
  return $this->{_nodetype};
}

=pod

=head3 $spectype = $minor->spectype

Returns the type of the minor node. Returns
  $S_IFCHR     for a raw device
  $S_IFBLK     for a block device
Both scalars are exported by default.

=cut

sub spectype {
  my $this = shift;
#print "SPECTYPE ", $this->name, ": ", $this->{_spectype} || "", "\n";
  return $this->{_spectype};
}

=pod

=head3 if( $minor->is_raw_device ) { ... }

Returns true if the minor node is a raw device

=cut

# Does this really matter here?
our $S_IFCHR=0;
our $S_IFBLK=0;

sub is_raw_device {
  my $this = shift;
  return $this->spectype eq $S_IFCHR;
}

=pod

=head3 if( $minor->is_block_device ) { ... }

Returns true if the minor node is a block device

=cut

sub is_block_device {
  my $this = shift;
  return $this->spectype eq $S_IFBLK;
}

=pod

=head3 $node = $minor->node;

Returns the associated C<Solaris::DeviceTree> node.
One C<DeviceTree> node can (and usually does) have multiple minor nodes.

=cut

sub node {
  my $this = shift;
  return $this->{_node};
}

=head3 $slice = $minor->slice;

Returns the slice number associated with this minor node if
it represents a block device.

=cut

sub slice {
  my ($this, %args) = @_;

  if( exists $args{_slice} ) {
    $this->{_slice} = $args{_slice};
  }

  return $this->{_slice};
}

=pod

=head1 EXAMPLES


=head1 AUTHOR

Copyright 1999-2003 Dagobert Michelsen.


=head1 SEE ALSO

  L<Solaris::DeviceTree::Filesystem>

=cut

1;
