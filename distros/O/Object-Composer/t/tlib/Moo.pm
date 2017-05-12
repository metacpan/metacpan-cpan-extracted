package Moo;


use strict;
use base 'Foo';


sub new {
  shift;
  my $args = [ @_ ];
  return bless $args, __PACKAGE__;
}


sub arg_at {
  my ( $self, $index ) = @_;
  if( $index <= scalar @$self ) {
    return $self->[$index];
  }

  undef;
}




1;
