#!/usr/bin/perl

use strict;
use warnings;

package BencodeParser;
use base qw( Parser::MGC );

use Feature::Compat::Try;

# See also
#   https://en.wikipedia.org/wiki/Bencode

sub parse
{
   my $self = shift;

   $self->any_of(
      'parse_int',
      'parse_bytestring',
      'parse_list',
      'parse_dict',

      sub { $self->commit; $self->fail( "Expected int, bytestring, list or dict" ) },
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
      sub { $self->sequence_of( 'parse' ) },
      'e'
   );
}

sub parse_dict
{
   my $self = shift;

   my $kvlist = $self->committed_scope_of(
      'd',
      sub { $self->sequence_of( 'parse' ) },
      'e'
   );

   return { @$kvlist };
}

use Data::Dumper;

if( !caller ) {
   my $parser = __PACKAGE__->new;

   while( defined( my $line = <STDIN> ) ) {
      try {
         my $ret = $parser->from_string( $line );
         print Dumper( $ret );
      }
      catch ( $e ) {
         print $e;
      }
   }
}

1;
