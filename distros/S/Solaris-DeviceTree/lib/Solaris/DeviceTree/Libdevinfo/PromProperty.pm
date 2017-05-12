#
# $Header: /cvsroot/devicetool/Solaris-DeviceTree/lib/Solaris/DeviceTree/Libdevinfo/PromProperty.pm,v 1.6 2003/12/09 13:04:47 honkbude Exp $
#

package Solaris::DeviceTree::Libdevinfo::PromProperty;

use 5.006;
use strict;
use warnings;
use Solaris::DeviceTree::Libdevinfo::Impl;

our $VERSION = do { my @r = (q$Revision: 1.6 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r }; # must be all one line, for MakeMaker

=pod

=head1 NAME

Solaris::DeviceTree::Libdevinfo::PromProperty -
PROM property of a node of the Solaris devicetree

=head1 SYNOPSIS

  use Solaris::DeviceTree::Libdevinfo;
  $tree = new Solaris::DeviceTree::Libdevinfo;
  %pprops = %{$tree->prom_props};


=head1 DESCRIPTION

This class allows access to PROM properties of a node in various
output formats. The value of the property is returned as a
reference to a scalar containing the binary values of the property.

=head1 METHODS

The constructor is considered internal and should not be used.

The following methods are available:

=cut

# The constructor takes a packed binary scalar
# with the value. Instances of this class are usually created from
# L<Solaris::DeviceTree::Libdevinfo::prom_props>.
sub new {
  my ($pkg, $data) = @_;

  my $this = bless \$data, $pkg;

  return $this;
}

=pod

=head3 $promprop->string

Returns the value of the property as human readable string where the value
is returned as ASCII string or hex depending of the contents.

=cut

sub iaToString {
  my @intArray = @_;
  return "" if( @intArray == 0 );

  # according to di_prom_prop_lookup_bytes(3DEVINFO) a property of type 'string'
  # can be a concatenation of several strings separated by '0'.
  # NOTE: We assume here that each of the strings must not be empty.

  # does the string contain unprintable characters?
  pop @intArray if( $intArray[ -1 ] == 0 );     # strip possible trailing zero

  my $isString = 1;
  # check for single string
  foreach my $v (@intArray) {
    if( $v < 32 || ($v > 126 && $v < 161) || $v > 254)  {
      $isString = 0;
    }
  }

  # if it is not a simple string it might be a string array
  my $isStringArray = 1;
  if( $isString == 0 ) {
    my $newStringEmpty = 0;
    foreach my $v (@intArray) {
      if( $v == 0 ) {
        $isStringArray = 0 if( $newStringEmpty == 1 );	# Empty element in array
      }
      $newStringEmpty = ( $v == 0 ? 1 : 0 );
      if( ($v > 0 && $v < 32) || ($v > 126 && $v < 161) || $v > 254)  {
        $isStringArray = 0;
      }
    }
  }

  # if it is an integer array, the length is dividable by 4
  my $isIntArray = 0;
  my @propInts;
  if( @intArray % 4 == 0 ) {
    $isIntArray = 1;
    my @a = @intArray;
    while( @a > 0 ) {
      my $val = 0;
      for (0..3) {
        $val = $val * 256 + (shift @a);
      }
      push @propInts, $val;
    }
  }

  # convert the array to a printable string
  my $string;
  if( $isString ) {
    $string = join "", map { chr( $_ ) } @intArray;	# convert to characters
  } elsif( $isStringArray ) {
    $string = join "", map { $_ == 0 ? "\n" : chr( $_ ) } @intArray;	# convert to characters
  } elsif( $isIntArray ) {
    $string = join " ", @propInts;
  } else {
    $string = join " ", @intArray;   # Use unmodified array here and print ascii values
  }
  return $string;

}

sub string {
  my ($this, %options) = @_;

  return iaToString( unpack( "C*", $$this ) );
}

=pod

=head1 AUTHOR

Copyright 1999-2003 Dagobert Michelsen.


=head1 SEE ALSO

L<Solaris::DeviceTree::Libdevinfo>, C<libdevinfo>, C<di_prom_prop_name>,
C<di_prom_prop_data>, C<di_prom_prop_next>.

=cut

1;
