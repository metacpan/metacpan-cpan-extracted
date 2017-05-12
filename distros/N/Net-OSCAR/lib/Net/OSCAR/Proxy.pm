package Net::OSCAR::Proxy;
BEGIN {
  $Net::OSCAR::Proxy::VERSION = '1.928';
}

$REVISION = '$Revision$';

use strict;
use vars qw($REVISION);

sub use_socks {
	require Net::SOCKS or return -1;
	
}

1;

