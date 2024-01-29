package Socket::More::Lookup;

use v5.36;

our $VERSION = 'v0.1.0';

require XSLoader;
XSLoader::load('Socket::More::Lookup', $VERSION);
use Export::These qw<getaddrinfo getnameinfo gai_strerror>;

use constant::more qw<LU_FLAGS=0 LU_FAMILY LU_TYPE LU_PROTOCOL LU_ADDR LU_CANONNAME>;
use Export::These qw<LU_FLAGS LU_FAMILY LU_TYPE LU_PROTOCOL LU_ADDR LU_CANONNAME>;
sub _reexport{};

sub resolve {
  
}

1;
