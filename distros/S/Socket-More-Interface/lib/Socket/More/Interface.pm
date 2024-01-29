package Socket::More::Interface;
use v5.36;
our $VERSION = 'v0.1.0';

require XSLoader;
XSLoader::load('Socket::More::Interface', $VERSION);

use Export::These qw< getifaddrs if_nametoindex if_indextoname if_nameindex >;
1;
