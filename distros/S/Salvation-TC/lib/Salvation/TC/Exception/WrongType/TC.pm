package Salvation::TC::Exception::WrongType::TC;

use strict;
use base 'Salvation::TC::Exception::WrongType';

sub getPrev {
  return( ref( $_[0] ) ? $_[0]->{ 'prev' } : undef );
}

sub getParamName {
  return( ref( $_[0] ) ? $_[0]->{ 'param_name' } : undef );
}

1;
__END__
