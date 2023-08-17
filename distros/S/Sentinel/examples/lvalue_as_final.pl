#!/usr/bin/perl

use v5.14;
use warnings;

package lvalue_as_final;

use B qw( svref_2object );
use Sentinel;

sub MODIFY_CODE_ATTRIBUTES
{
   my ( $pkg, $code, @attrs ) = @_;
   return grep {
      if( $_ eq "lvalue_as_final" ) {
         my $glob = svref_2object( $code )->GV->object_2svref;

         *$glob = sub :lvalue {
            my ( $self, @args ) = @_;
            sentinel get => sub { $code->( $self, \@args ) },
                     set => sub { $code->( $self, \@args, $_[0] ) };
         };

         0
      }
      else {
         1
      }
   } @attrs;
}

### example

sub foo :lvalue_as_final
{
   my $self = shift;
   my ( $args, $new ) = @_;
   my ( $one, $two, $three ) = @$args;

   print "$self ->foo( $one, $two, $three ) set to $new\n";
}

lvalue_as_final->foo(1,2,3) = "new value";
