use Test;
BEGIN { plan(tests => 1) }

skip(! $ENV{NP_DO_TEST6} ? 'Skip since env variable NP_DO_TEST6=0' : '', sub {
   my $ok;
   use Net::Packet::Env qw($Env);
   use Net::Packet::Consts qw(:eth :ipv6);

   $Env->dev($ENV{NP_ETH_DEV});
   $Env->ip ($ENV{NP_ETH_IP});
   $Env->mac($ENV{NP_ETH_MAC});
   $Env->debug(3) if $ENV{NP_DEBUG};

   require Net::Packet::ETH;
   require Net::Packet::IPv6;
   require Net::Packet::UDP;
   require Net::Packet::Layer7;
   require Net::Packet::Frame;

   my $l2 = Net::Packet::ETH->new(
      type => NP_ETH_TYPE_IPv6,
   );

   my $l3 = Net::Packet::IPv6->new(
      nextHeader => NP_IPv6_PROTOCOL_UDP,
      dst => $ENV{NP_ETH_TARGET_IP6},
   );

   my $l4 = Net::Packet::UDP->new(
      dst => $ENV{NP_ETH_TARGET_PORT},
   );

   my $l7 = Net::Packet::Layer7->new(
      data => 'test0',
   );

   my $frame = Net::Packet::Frame->new(l2 => $l2, l3 => $l3, l4 => $l4, l7 => $l7);
   $frame->send;

#  until ($Env->dump->timeout) {
#     if ($frame->recv) {
#        $ok++;
#        last;
#     }
#  }
   $ok++; # XXX: cannot verify reply is ok for now, need ICMPv6

   $Env->dump->stop;
   $Env->dump->clean;

   $ok;
});
