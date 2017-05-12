#!/usr/bin/perl

use strict;
use warnings;

package BencodeParser;
use base qw( Parser::MGC );

# See also
#   https://en.wikipedia.org/wiki/Bencode

sub parse
{
   my $self = shift;

   $self->any_of(
      sub { $self->parse_int },
      sub { $self->parse_bytestring },
      sub { $self->parse_list },
      sub { $self->parse_dict },
   );
}

sub parse_int
{
   my $self = shift;

   $self->expect( 'i' );
   my $value = $self->expect( qr/-?\d+/ );
   $self->expect( 'e' );

   return $value;
}

sub parse_bytestring
{
   my $self = shift;

   my $len = $self->expect( qr/\d+/ );
   $self->expect( ':' );

   return $self->take( $len );
}

sub parse_list
{
   my $self = shift;

   $self->committed_scope_of(
      'l',
      sub { $self->sequence_of( sub { $self->parse } ) },
      'e'
   );
}

sub parse_dict
{
   my $self = shift;

   my $kvlist = $self->committed_scope_of(
      'd',
      sub { $self->sequence_of( sub { $self->parse } ) },
      'e'
   );

   return { @$kvlist };
}

use Data::Dumper;

if( !caller ) {
   my $parser = __PACKAGE__->new;

   while( defined( my $line = <STDIN> ) ) {
      my $ret = eval { $parser->from_string( $line ) };
      print $@ and next if $@;

      print Dumper( $ret );
   }
}

1;
