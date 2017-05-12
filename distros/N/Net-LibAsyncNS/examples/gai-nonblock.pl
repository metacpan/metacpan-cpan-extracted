#!/usr/bin/perl

use strict;
use warnings;

use Getopt::Long;
use Socket;
use constant CAN_IPv6 => eval { require Socket6 };
use Net::LibAsyncNS;
use IO::Poll;

my %hints = (
   socktype => SOCK_RAW, # Just to ensure one result per host
);

GetOptions(
   '4' => sub { $hints{family} = AF_INET },
   '6' => sub { CAN_IPv6 ? $hints{family} = Socket::AF_INET6()
                         : die "Cannot do AF_INET6\n"; },
) or exit 1;

my @hosts = @ARGV;

my $asyncns = Net::LibAsyncNS->new( scalar @hosts );

foreach my $host ( @hosts ) {
   my $q = $asyncns->getaddrinfo( $host, undef, \%hints );
   $q->setuserdata( sub {
      my ( $err, @res ) = $asyncns->getaddrinfo_done( $q );

      if( $err ) {
         print STDERR "$host - $err\n";
      }
      else {
         foreach my $res ( @res ) {
            if( $res->{family} == AF_INET ) {
               print "$host: " . inet_ntoa( (unpack_sockaddr_in $res->{addr})[1] ) . "\n";
            }
            elsif( CAN_IPv6 and $res->{family} == Socket6::AF_INET6() ) {
               print "$host: " . Socket6::inet_ntop( $res->{family}, (Socket6::unpack_sockaddr_in6 $res->{addr} )[1] ) . "\n";
            }
            else {
               printf "%s: {family=%d,addr=%v02x}\n", $host, $res->{family}, $res->{addr};
            }
         }
      }
   } );
}

my $fh = $asyncns->new_handle_for_fd;

my $poll = IO::Poll->new;
$poll->mask( $fh => POLLIN );

while(1) {
   $asyncns->getnqueries or last;

   my $ret = $poll->poll();
   defined $ret or die "poll() - $!";

   if( $poll->events( $fh ) ) {
      $asyncns->wait( 0 ) or die "asyncns_wait() - $!";
      while( my $query = $asyncns->getnext ) {
         $query->getuserdata->();
      }
   }
}
