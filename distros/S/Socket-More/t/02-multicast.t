use strict;
use warnings;
use Socket::More::Constants;
use Socket::More;

use Test::More;
{
  # Multicast 
	my @results=Socket::More::sockaddr_passive( {address=>"224.0.0.1", port=>12345, family=>AF_INET, socktype=>SOCK_DGRAM, interface=>"en0", group=>"MULTICAST"});

  use Data::Dumper;
  #say STDERR "OUTPUT";
  #say STDERR Dumper \@results;
}
ok 1;
done_testing;
