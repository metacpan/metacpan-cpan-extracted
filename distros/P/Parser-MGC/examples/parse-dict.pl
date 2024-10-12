#!/usr/bin/perl

use v5.14;
use warnings;

package DictParser;
use base qw( Parser::MGC );

use Feature::Compat::Try;

sub parse
{
   my $self = shift;

   $self->any_of(
      'token_int',
      'token_string',

      sub { $self->committed_scope_of( "{", 'parse_dict', "}" ) },

      sub { $self->commit; $self->fail( "Expected integer, string, or dictionary" ) },
   );
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
