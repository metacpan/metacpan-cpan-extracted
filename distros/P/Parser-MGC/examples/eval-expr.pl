#!/usr/bin/perl

use strict;
use warnings;

package ExprParser;
use base qw( Parser::MGC );

use Feature::Compat::Try;

# An expression is a list of terms, joined by + or - operators
sub parse
{
   my $self = shift;

   my $val = $self->parse_term;

   1 while $self->any_of(
      sub { $self->expect( "+" ); $self->commit; $val += $self->parse_term; 1 },
      sub { $self->expect( "-" ); $self->commit; $val -= $self->parse_term; 1 },
      sub { 0 },
   );

   return $val;
}

# A term is a list of factors, joined by * or - operators
sub parse_term
{
   my $self = shift;

   my $val = $self->parse_factor;

   1 while $self->any_of(
      sub { $self->expect( "*" ); $self->commit; $val *= $self->parse_factor; 1 },
      sub { $self->expect( "/" ); $self->commit; $val /= $self->parse_factor; 1 },
      sub { 0 },
   );

   return $val;
}

# A factor is either a parenthesized expression, or an integer
sub parse_factor
{
   my $self = shift;

   $self->any_of(
      sub { $self->committed_scope_of( "(", 'parse', ")" ) },
      sub { $self->token_int },
   );
}

if( !caller ) {
   my $parser = __PACKAGE__->new;

   while( defined( my $line = <STDIN> ) ) {
      try {
         my $ret = $parser->from_string( $line );
         print "$ret\n";
      }
      catch ( $e ) {
         print $e;
      }
   }
}

1;
