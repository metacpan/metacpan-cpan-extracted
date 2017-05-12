#!/usr/bin/perl

use strict;
use warnings;

package PodParser;
use base qw( Parser::MGC );

sub parse
{
   my $self = shift;

   $self->sequence_of(
      sub { $self->any_of(

         sub { my ( undef, $tag, $delim ) = $self->expect( qr/([A-Z])(<+)/ );
               $self->commit;
               +{ $tag => $self->scope_of( undef, \&parse, ">" x length $delim ) }; },

         sub { $self->substring_before( qr/[A-Z]</ ) },
      ) },
   );
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
