package Salvation::TC::Exception::WrongType;

use strict;
use base qw( Salvation::TC::Exception );

sub getType {
  return( ref( $_[0] ) ? $_[0]->{ 'type' } : '' );
}

sub getValue {
  return( ref( $_[0] ) ? $_[0]->{ 'value' } : '' );
}

1;
__END__
