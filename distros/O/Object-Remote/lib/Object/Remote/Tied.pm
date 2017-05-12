package Object::Remote::Tied;

use strictures 1;

#a proxied tied object just ties to the
#proxy object that exists on the remote
#side of the actual tied variable - when
#creating the remote tied variable the proxy
#is passed to the constructor

sub TIEHASH {
  return $_[1];
}

sub TIEARRAY {
  return $_[1];
}

1;

