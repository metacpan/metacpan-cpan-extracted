#!/usr/bin/perl
#

use strict;
use warnings;
use Test::More tests => 5;

use Net::DNS::Multicast;


my $resolver = Net::DNS::Resolver->new( retrans => 0, retry => 0 );

ok( !$resolver->send('example.local'),	 'multicast $resolver->send("example.local")' );
ok( !$resolver->bgsend('example.local'), 'multicast $resolver->bgsend("example.local")' );

ok( !$resolver->send('example.com'),   'unicast $resolver->send("example.com")' );
ok( !$resolver->bgsend('example.com'), 'unicast $resolver->bgsend("example.com")' );

ok( $resolver->string, '$resolver->string' );

exit;


package Net::DNS::Resolver;	## off-line dry test
sub _create_tcp_socket {return}	## stub
sub _create_udp_socket {return}	## stub

__END__

