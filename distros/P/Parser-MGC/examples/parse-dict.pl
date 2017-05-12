#!/usr/bin/perl

use strict;
use warnings;

package DictParser;
use base qw( Parser::MGC );

sub parse
{
   my $self = shift;

   $self->any_of(
      sub { $self->token_int },

      sub { $self->token_string },

      sub { $self->committed_scope_of( "{", 'parse_dict', "}" ) },
   );
}

sub parse_dict
{
   my $self = shift;

   my %ret;
   $self->list_of( ",", sub {
      my $key = $self->token_ident;

      $self->expect( ":" );

      $ret{$key} = $self->parse;
   } );

   return \%ret
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
