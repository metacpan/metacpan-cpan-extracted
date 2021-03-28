#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

my $fallback;

package TestParser;
use base qw( Parser::MGC );

sub parse
{
   my $self = shift;

   $self->any_of(
      sub {
         $self->committed_scope_of(
            "(",
            sub { return $self->token_int },
            ")",
         );
      },
      sub { $fallback++ },
   );
}



package main;

my $parser = TestParser->new;

is( $parser->from_string( "(123)" ), 123, '"(123)"' );

ok( !eval { $parser->from_string( "(abc)" ) }, '"(abc)"' );
ok( !$fallback, '"(abc) does not invoke fallback case' );

done_testing;
