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
      nlmsg_type  => RTM_GETROUTE,
      nlmsg_flags => NLM_F_DUMP,
) );

$rtnlsock->recv_nlmsgs( \@messages, 2**16 ) or
   die "Cannot recv - $!";

foreach my $message ( @messages ) {
   if( $message->nlmsg_type == NLMSG_ERROR ) {
      $! = -(unpack "i!", $message->nlmsg)[0];
      print "Got error $!\n";
   }
   elsif( $message->nlmsg_type == RTM_NEWROUTE ) {
      printf "Got reply type=%d flags=%04x seq=%d pid=%d\n",
         $message->nlmsg_type, $message->nlmsg_flags, $message->nlmsg_seq, $message->nlmsg_pid;

      printf "  family=%d tos=%x table=%d protocol=%d scope=%d type=%d flags=%04x\n",
         $message->rtm_family, $message->rtm_tos, $message->rtm_table, $message->rtm_protocol, $message->rtm_scope, $message->rtm_type, $message->rtm_flags;

      printf "  source=%s destination=%s\n", $message->src // "any", $message->dst // "any";

      print pp( $message->nlattrs ) . "\n";
   }
}
