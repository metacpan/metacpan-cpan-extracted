#
# $Header: /cvsroot/devicetool/Solaris-DeviceTree/lib/Solaris/DeviceTree/Filesystem/MinorNode.pm,v 1.7 2003/12/12 11:11:55 honkbude Exp $
#

package Solaris::DeviceTree::Filesystem::MinorNode;

use 5.006;
use strict;
use warnings;

# some constants
our $S_IFMT = 0xf000;
our $S_IFBLK = 0x6000;
our $S_IFCHR = 0x2000;

our $STAT_DEV = 0;
our $STAT_INO = 1;
our $STAT_MODE = 2;
our $STAT_NLINK = 3;
our $STAT_UID = 4;
our $STAT_GID = 5;
our $STAT_RDEV = 6;
our $STAT_SIZE = 7;
our $STAT_ATIME = 8;
our $STAT_MTIME = 9;
our $STAT_CTIME = 10;
our $STAT_BLKSIZE = 11;
our $STAT_BLOCKS = 12;

require Exporter;
our %EXPORT_TAGS = ( 'all' => [ qw( S_IFBLK S_IFCHR ) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = do { my @r = (q$Revision: 1.7 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

=pod

=head1 NAME

Solaris::DeviceTree::Filesystem::MinorNode - Minor node of the Solaris device filetree

=head1 SYNOPSIS

Construction:

  use Solaris::DeviceTree::Filesystem;
  $tree = Solaris::DeviceTree::Filesystem->new;
  @disks = $tree->find_nodes( type => 'disk' );
  @minor = $disk[0]->minor_nodes;

Data access methods:

  $name = $minor->name;
  $devfs_path = $minor->devfs_path;
  ($major_num,$minor_num) = $minor->devt;
  if( !defined $minor->nodetype ) { print "I knew that!"; }
  $spectype = $minor->spectype
  if( $minor->is_raw_device ) { ... }
  if( $minor->is_block_device ) { ... }
  $treenode = $minor->node;
  $slice = $minor->slice;


=head1 DESCRIPTION

This class implements a minor node for a device file in the Solaris
filesystem devicetree.

This is an internal class to L<Solaris::DeviceTree::Filesystem>. There should be
no need to generate instances of this class in an application explicitly.
Instances are generated only from L<Solaris::DeviceTree::Filesystem::minor_nodes>.


=head1 METHODS

The following methods are available:

=cut

# The constructor takes a string holding the absolute path to
# the device file and a backreference to the
# L<Solaris::DeviceTree::Filesystem> object which generates this
# instance. The constructor is considered private and should not be
# used.

sub new {
  my ($pkg, $filepath, $node) = @_;

  my ($name) = ($filepath =~ /:(.*)$/);
  my $this = bless {
    _filepath => $filepath,
    _node => $node,	# if we need infos about the upper node
    _stat => [ stat $filepath ],
    _name => $name,
  }, ref( $pkg ) || $pkg;

  # If we have a dangling link this field can be undefined, but
  # there should be no dangling links.
  warn "Cannot stat $filepath.\n" if( !defined $this->{_stat} );

  # This information is taken from <sys/mkdev.h>
  # (see also major.3c and minor.3c)
  my $rdev = $this->{_stat}->[$STAT_RDEV];
  $this->{_major} = $rdev >> 18;
  $this->{_minor} = $rdev & 0x3ffff;	# 18 Bits

  return $this;
}

=pod

=head2 name

This method returns the name of the minor node.
This is used e.g. as suffix of the device filename.
For disks this is something like 'a' or 'a,raw'.

=cut

sub name {
  my $this = shift;
  return $this->{_name};
}

=pod

=head2 devfs_path

Return the complete physical path including the minor node

=cut

sub devfs_path {
  my $this = shift;
  return $this->node->devfs_path . ":" . $this->name;
}

=pod

=head2 devt

Return the major and minor device number as a pair for the node.
The major numbers should be the same for all minor nodes returned
by a L<Solaris::DeviceTree::Libdevinfo> node.

=cut

sub devt {
  my $this = shift;
  return ($this->{_major}, $this->{_minor});
}

=pod

=head2 nodetype

Return the nodetype of the minor node. Because we can't
find that out by looking at the filesystem we always return
C<undef>.

=cut

sub nodetype {
  return undef;
}

=pod

=head2 spectype

Returns the type of the minor node. The return values
  $S_IFCHR   for a raw device
  $S_IFBLK   for a block device
are possible. Both scalars are exported by default.

=cut

sub spectype {
  my $this = shift;

  return 'raw' if( $this->is_raw_device );
  return 'block' if( $this->is_block_device );

  # This is a strange little fellow. We have a minor node
  # which is neither a block- nor a character-device.
  return undef;
}

=pod

=head2 is_raw_device

Returns true if the minor node is a raw device.

=cut

sub is_raw_device {
  my $this = shift;
  return ($this->{_stat}->[$STAT_MODE] & $S_IFMT) == $S_IFCHR;
}

=pod

=head2 is_block_device

Returns true if the minor node is a block device.

=cut

sub is_block_device {
  my $this = shift;
  return ($this->{_stat}->[$STAT_MODE] & $S_IFMT) == $S_IFBLK;
}

=pod

=head2 node

Returns the associated L<Solaris::DevinfoTree::Filesystem> node.
A treenode can (and usually does) have multiple minor nodes.

=cut

sub node {
  my $this = shift;
  return $this->{_node};
}

=pod

=head2 slice

Returns the slice number associated with this minor node.

=cut

sub slice {
  my ($this, %options) = @_;

  if( exists $options{_slice} ) {
    $this->{_slice} = $options{_slice};
  }
  return $this->{_slice};
}

=pod


=head1 EXPORTS

  $S_IFCHR
  $S_IFBLK


=head1 AUTHOR

Copyright 1999-2003 Dagobert Michelsen.


=head1 SEE ALSO

  L<Solaris::DeviceTree::Filesystem>

=cut

1;
