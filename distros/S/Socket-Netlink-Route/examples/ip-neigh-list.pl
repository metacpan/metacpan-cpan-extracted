#!/usr/bin/perl

use strict;
use warnings;

use IO::Socket::Netlink::Route;
use Socket;
use Socket::Netlink qw( :DEFAULT );
use Socket::Netlink::Route qw( :DEFAULT );

use Data::Dump qw( pp );

my $rtnlsock = IO::Socket::Netlink::Route->new
   or die "Cannot make netlink socket - $!";

my @messages;

$rtnlsock->send_nlmsg( $rtnlsock->new_request(
      nlmsg_type  => RTM_GETNEIGH, 
      nlmsg_flags => NLM_F_DUMP,
) );

$rtnlsock->recv_nlmsgs( \@messages, 2**16 ) or
   die "Cannot recv - $!";

foreach my $message ( @messages ) {
   if( $message->nlmsg_type == NLMSG_ERROR ) {
      $! = -(unpack "i!", $message->nlmsg)[0];
      print "Got error $!\n";
   }
   elsif( $message->nlmsg_type == RTM_NEWNEIGH ) {
      printf "Got reply type=%d flags=%04x seq=%d pid=%d\n",
         $message->nlmsg_type, $message->nlmsg_flags, $message->nlmsg_seq, $message->nlmsg_pid;

      printf "  family=%d ifindex=%d state=%d flags=%04x type=%d\n",
         $message->ndm_family, $message->ndm_ifindex, $message->ndm_state, $message->ndm_flags, $message->ndm_type;

      print pp( $message->nlattrs ) . "\n";
   }
}
