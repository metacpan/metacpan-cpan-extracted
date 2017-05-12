#
# $Header: /cvsroot/devicetool/Solaris-DeviceTree/lib/Solaris/DeviceTree/Libdevinfo/Property.pm,v 1.7 2003/12/09 13:04:47 honkbude Exp $
#

package Solaris::DeviceTree::Libdevinfo::Property;

use 5.006;
use strict;
use warnings;
use Solaris::DeviceTree::Libdevinfo::Impl;

our $VERSION = do { my @r = (q$Revision: 1.7 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

=pod

=head1 NAME

Solaris::DeviceTree::Libdevinfo::Property - Property of a node of the Solaris devicetree

=head1 SYNOPSIS

  use Solaris::DeviceTree::Libdevinfo;
  $tree = new Solaris::DeviceTree::Libdevinfo;
  @disks = $tree->find_nodes( type => 'disk' );
  @props = @disks->properties;


=head1 DESCRIPTION


=head1 METHODS

The following methods are available:

=head3 $minor = new Solaris::DeviceTree::Libdevinfo::Property($minor_data, $devinfo_node);

The constructor takes a SWIG-pointer to the C data structure
of a minor node C<di_minor_t> and a backreference to the
C<Solaris::DeviceTree::Libdevinfo> object which generates this
instance.

=cut

sub new {
  my $pkg = shift @_;
  my $prop = shift @_;

  my $this = bless {
    prop => $prop
  }, $pkg;

  return $this;
}

=pod

=head3 my $name = $prop->name

This method returns the name of the property.

=cut

sub name {
  my $this = shift @_;
  return di_prop_name( $this->{prop} );
}

=pod

=head3 my ($major, $minor) = $prop->devt

This method returns the devt-record of the property containing the major- and
minor-number returned as list. If no devt-record is associated C<undef> is returned.

=cut

sub devt {
  my $this = shift @_;
  my $devt = di_prop_devt( $this->{prop} );

  my @result = undef;
  if( !isDDI_DEV_T_NONE( $devt ) ) {
    my ($major, $minor) = devt_majorminor( $devt );
    @result = ($major, $minor);
  }
  return @result;
}

=pod

=head3 $type = $prop->type

This method returns the type of the property. Depending on the type the data
of the property must be handled accordingly. Valid return types are:

  boolean int string byte unknown undefined

=cut

sub type {
  my $this = shift @_;

  my $prop = $this->{prop};
  my $type = di_prop_type( $prop );
  my @types = qw( boolean int string byte unknown undefined );
  return $types[ $type ];
}

=pod

=head3 my @data = $prop->data

This method returns the data associated with the property as list.

=cut

# -> TODO: let the user choose how to output the data: packed string,
# plaintext, hex characters.
# Accessor should be same as in PromProperty
sub data {
  my $this = shift @_;

  my $prop = $this->{prop};
  my $type;
  my @data;

  $type = di_prop_type( $prop );

  if( $type == $DI_PROP_TYPE_BOOLEAN ) {
    # boolean data. Existence means 'true'
    @data = ("true");
  } elsif( $type == $DI_PROP_TYPE_INT ) {
    # integer array data. Use helper function.
    my $handle = newIntHandle();
    my $count = di_prop_ints( $prop, $handle );
    my $index;
    for( $index = 0; $index < $count; $index++ ) {
      push @data, getIndexedInt( $handle, $index );
    }
    freeIntHandle( $handle );
  } elsif( $type == $DI_PROP_TYPE_STRING ) {
    # string array data. Use helper function.
    my $handle = newStringHandle();
    my $count = di_prop_strings( $prop, $handle );
    my $index;
    for( $index = 0; $index < $count; $index++ ) {
      push @data, getIndexedString( $handle, $index );
    }
    freeStringHandle( $handle );
  } elsif( $type == $DI_PROP_TYPE_BYTE ||
        $type == $DI_PROP_TYPE_UNKNOWN ) {
    # byte or unknown data. Which one doesn't matter because we always use
    # 'di_prop_bytes' to read the data.
    my $handle = newUCharTHandle();
    my $count = di_prop_bytes( $prop, $handle );
    my $index;
    for( $index = 0; $index < $count; $index++ ) {
      push @data, getIndexedByte( $handle, $index );
    }
    freeUCharTHandle( $handle );
  } elsif( $type == $DI_PROP_TYPE_UNDEF_IT ) {
    # the data was explicitly marked 'undefined'
    @data = undef;
  }

  return wantarray ? @data : join( " ", @data );
}

=pod

=head1 EXAMPLES


=head1 AUTHOR

Copyright 1999-2003 Dagobert Michelsen.


=head1 SEE ALSO

L<Solaris::DeviceTree::Libdevinfo>, C<libdevinfo>, C<di_prop_bytes>.

=cut

1;
