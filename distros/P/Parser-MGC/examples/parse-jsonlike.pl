#!/usr/bin/perl

use strict;
use warnings;

# DO NOT RELY ON THIS AS A REAL JSON PARSER

# It is not intended to be used actually as a JSON parser, simply to stand as
# an example of how you might use Parser::MGC to parse a JSON-like syntax

# It doesn't handle things like floats, booleans or quoting of dict keys

package JsonlikeParser;
use base qw( Parser::MGC );

use Feature::Compat::Try;

sub parse
{
   my $self = shift;

   $self->any_of(
      'token_int',
      'token_string',

      sub { $self->committed_scope_of( "[", 'parse_list', "]" ) },

      sub { $self->committed_scope_of( "{", 'parse_dict', "}" ) },

      sub { $self->commit; $self->fail( "Expected integer, string, list, or dictionary" ) },
   );
}

sub parse_list
{
   my $self = shift;

   return $self->list_of( ",", 'parse' );
}

sub parse_dict
{
   my $self = shift;

   my %ret;
   $self->list_of( ",", sub {
      my $key = $self->token_ident;

      $self->expect( ":" );
      $self->commit;

      $ret{$key} = $self->parse;
   } );

   return \%ret
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
